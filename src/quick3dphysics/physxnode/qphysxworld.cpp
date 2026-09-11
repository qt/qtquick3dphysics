// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qphysxworld_p.h"

#include "characterkinematic/PxControllerManager.h"
#include "extensions/PxDefaultCpuDispatcher.h"
#include "foundation/PxFoundation.h"
#include "PxPhysics.h"
#include "foundation/PxPhysicsVersion.h"
#include "PxRigidActor.h"
#include "PxScene.h"
#include "PxShape.h"
#include "PxSimulationEventCallback.h"

#include "qabstractcollisionshape_p.h"
#include "qabstractphysicsnode_p.h"
#include "qphysicsutils_p.h"
#include "qphysicsworld_p.h"
#include "qstaticphysxobjects_p.h"
#include "qtriggerbody_p.h"

QT_BEGIN_NAMESPACE

// The shape a PhysX shape was built for, or null if it was not built for one.
// Only ever compared, since the shape can be gone by the time it is looked at.
static QAbstractCollisionShape *frontendShape(const physx::PxShape *shape)
{
    return shape ? static_cast<QAbstractCollisionShape *>(shape->userData) : nullptr;
}

class SimulationEventCallback : public physx::PxSimulationEventCallback
{
public:
    SimulationEventCallback(QPhysicsWorld *worldIn) : world(worldIn) {};
    virtual ~SimulationEventCallback() = default;

    void onTrigger(physx::PxTriggerPair *pairs, physx::PxU32 count) override
    {
        // A body one of whose shapes leaves a trigger as another of them enters
        // it has a lost and a found pair in the same batch, and taking the lost
        // one first would report the body as having left and entered again. So
        // the found pair is taken first, and only for the trigger and body that
        // has both: every other pair is handled in the order PhysX gave it, so
        // a body leaving one trigger as it enters another is still reported that
        // way.
        const auto replacesLostOverlap = [pairs, count](physx::PxU32 i) {
            if (pairs[i].status != physx::PxPairFlag::eNOTIFY_TOUCH_FOUND)
                return false;
            for (physx::PxU32 j = 0; j < count; j++) {
                if (pairs[j].status == physx::PxPairFlag::eNOTIFY_TOUCH_LOST
                    && pairs[j].triggerActor == pairs[i].triggerActor
                    && pairs[j].otherActor == pairs[i].otherActor) {
                    return true;
                }
            }
            return false;
        };

        // Those first, then every pair in turn. Registering one of them again
        // on the second pass does nothing: the body is inside already and the
        // pair is one of its own already.
        enum Pass { ReplacedOverlaps, EveryPair };
        for (const Pass pass : { ReplacedOverlaps, EveryPair }) {
            for (physx::PxU32 i = 0; i < count; i++) {
                if (pass == ReplacedOverlaps && !replacesLostOverlap(i))
                    continue;

                // ignore pairs when shapes have been deleted
                if (pairs[i].flags
                    & (physx::PxTriggerPairFlag::eREMOVED_SHAPE_TRIGGER
                       | physx::PxTriggerPairFlag::eREMOVED_SHAPE_OTHER))
                    continue;

                QTriggerBody *triggerNode =
                        static_cast<QTriggerBody *>(pairs[i].triggerActor->userData);

                QAbstractPhysicsNode *otherNode =
                        static_cast<QAbstractPhysicsNode *>(pairs[i].otherActor->userData);

                if (!triggerNode || !otherNode) {
                    qWarning() << "QtQuick3DPhysics internal error: null pointer in trigger "
                                  "collision.";
                    continue;
                }

                // Asked per pair, since one batch can report the same node in
                // several pairs and a handler run for one of them can delete a
                // node a later one points at. Nothing else can: PhysX sends
                // these from the thread that deletes nodes.
                if (world->isNodeRemoved(triggerNode) || world->isNodeRemoved(otherNode))
                    continue;

                // Passed on so the trigger can tell one pair of a body from
                // another: PhysX reports a pair of shapes and a body is several
                // of those, so one of them stopping overlapping is not the body
                // leaving.
                const QTriggerBody::ShapePair shapes { frontendShape(pairs[i].triggerShape),
                                                       frontendShape(pairs[i].otherShape) };

                // Whether a body is worth following, and what it is owed, is
                // the trigger's to decide, once per body rather than once per
                // pair: a body that changes its mind while inside would
                // otherwise be half followed.
                if (pairs[i].status == physx::PxPairFlag::eNOTIFY_TOUCH_FOUND)
                    triggerNode->registerCollision(otherNode, shapes);
                else if (pairs[i].status == physx::PxPairFlag::eNOTIFY_TOUCH_LOST)
                    triggerNode->deregisterCollision(otherNode, shapes);
            }
        }
    }

    void onConstraintBreak(physx::PxConstraintInfo * /*constraints*/,
                           physx::PxU32 /*count*/) override {};
    void onWake(physx::PxActor ** /*actors*/, physx::PxU32 /*count*/) override {};
    void onSleep(physx::PxActor ** /*actors*/, physx::PxU32 /*count*/) override {};
    void onContact(const physx::PxContactPairHeader &pairHeader, const physx::PxContactPair *pairs,
                   physx::PxU32 nbPairs) override
    {
        constexpr physx::PxU32 bufferSize = 64;
        physx::PxContactPairPoint contacts[bufferSize];

        for (physx::PxU32 i = 0; i < nbPairs; i++) {
            const physx::PxContactPair &contactPair = pairs[i];

            if (contactPair.events & physx::PxPairFlag::eNOTIFY_TOUCH_FOUND) {
                QAbstractPhysicsNode *trigger =
                        static_cast<QAbstractPhysicsNode *>(pairHeader.actors[0]->userData);
                QAbstractPhysicsNode *other =
                        static_cast<QAbstractPhysicsNode *>(pairHeader.actors[1]->userData);

                if (!trigger || !other || world->isNodeRemoved(trigger)
                    || world->isNodeRemoved(other) || !trigger->m_backendObject
                    || !other->m_backendObject)
                    continue;

                const bool triggerReceive =
                        trigger->receiveContactReports() && other->sendContactReports();
                const bool otherReceive =
                        other->receiveContactReports() && trigger->sendContactReports();

                if (!triggerReceive && !otherReceive)
                    continue;

                physx::PxU32 nbContacts = pairs[i].extractContacts(contacts, bufferSize);

                QList<QVector3D> positions;
                QList<QVector3D> impulses;
                QList<QVector3D> normals;

                positions.reserve(nbContacts);
                impulses.reserve(nbContacts);
                normals.reserve(nbContacts);

                for (physx::PxU32 j = 0; j < nbContacts; j++) {
                    physx::PxVec3 position = contacts[j].position;
                    physx::PxVec3 impulse = contacts[j].impulse;
                    physx::PxVec3 normal = contacts[j].normal;

                    positions.push_back(QPhysicsUtils::toQtType(position));
                    impulses.push_back(QPhysicsUtils::toQtType(impulse));
                    normals.push_back(QPhysicsUtils::toQtType(normal));
                }

                QList<QVector3D> normalsInverted;
                normalsInverted.reserve(normals.size());
                for (const QVector3D &v : std::as_const(normals)) {
                    normalsInverted.push_back(QVector3D(-v.x(), -v.y(), -v.z()));
                }

                if (triggerReceive)
                    world->registerContact(other, trigger, positions, impulses, normals);
                if (otherReceive)
                    world->registerContact(trigger, other, positions, impulses, normalsInverted);
            }
        }
    };
    void onAdvance(const physx::PxRigidBody *const * /*bodyBuffer*/,
                   const physx::PxTransform * /*poseBuffer*/,
                   const physx::PxU32 /*count*/) override {};

private:
    QPhysicsWorld *world = nullptr;
};

static constexpr bool isBitSet(quint32 value, quint32 position)
{
    Q_ASSERT(position <= 32);
    return value & (1 << (position));
}

// If any 'id' bit is set in the other mask it means collisions should be ignored, i.e.
static bool isFilteredOut(physx::PxFilterData filterData0, physx::PxFilterData filterData1)
{
    // First word is id, second is collision mask
    const quint32 id0 = filterData0.word0;
    const quint32 id1 = filterData1.word0;
    const quint32 mask0 = filterData0.word1;
    const quint32 mask1 = filterData1.word1;

    return id0 < 32 && id1 < 32 && (isBitSet(mask0, id1) || isBitSet(mask1, id0));
}

static physx::PxFilterFlags
contactReportFilterShader(physx::PxFilterObjectAttributes attributes0,
                          physx::PxFilterData filterData0,
                          physx::PxFilterObjectAttributes attributes1,
                          physx::PxFilterData filterData1, physx::PxPairFlags &pairFlags,
                          const void * /*constantBlock*/, physx::PxU32 /*constantBlockSize*/)
{
    if (isFilteredOut(filterData0, filterData1)) {
        // We return a 'suppress' since that will still re-evaluate when filter data is changed.
        return physx::PxFilterFlag::eSUPPRESS;
    }

    // A trigger shape does not collide, it only reports what overlaps it, so
    // there is nothing to solve and nothing for a continuous sweep to do. The
    // scene has CCD enabled unconditionally (see below), and PhysX warns for
    // every trigger pair that asks for a CCD contact, so ask only for what a
    // trigger actually needs.
    if (physx::PxFilterObjectIsTrigger(attributes0)
        || physx::PxFilterObjectIsTrigger(attributes1)) {
        pairFlags = physx::PxPairFlag::eTRIGGER_DEFAULT;
        return physx::PxFilterFlag::eDEFAULT;
    }

    // Makes objects collide
    const auto defaultCollisonFlags =
            physx::PxPairFlag::eSOLVE_CONTACT |
            physx::PxPairFlag::eDETECT_DISCRETE_CONTACT |
            physx::PxPairFlag::eDETECT_CCD_CONTACT; // will be ignored by physX engine if the ccd is disabled

    // For trigger body detection
    const auto notifyTouchFlags =
            physx::PxPairFlag::eNOTIFY_TOUCH_FOUND | physx::PxPairFlag::eNOTIFY_TOUCH_LOST;

    // For contact detection
    const auto notifyContactFlags = physx::PxPairFlag::eNOTIFY_CONTACT_POINTS;

    pairFlags = defaultCollisonFlags | notifyTouchFlags | notifyContactFlags;
    return physx::PxFilterFlag::eDEFAULT;
}

#define PHYSX_RELEASE(x)                                                                           \
    if (x != nullptr) {                                                                            \
        x->release();                                                                              \
        x = nullptr;                                                                               \
    }

void QPhysXWorld::createWorld()
{
    auto &s_physx = StaticPhysXObjects::getReference();
    s_physx.foundationRefCount++;

    if (s_physx.foundationCreated)
        return;

    s_physx.foundation = PxCreateFoundation(
            PX_PHYSICS_VERSION, s_physx.defaultAllocatorCallback, s_physx.defaultErrorCallback);
    if (!s_physx.foundation)
        qFatal("PxCreateFoundation failed!");

    s_physx.foundationCreated = true;
}

void QPhysXWorld::deleteWorld()
{
    auto &s_physx = StaticPhysXObjects::getReference();
    s_physx.foundationRefCount--;
    if (s_physx.foundationRefCount == 0) {
        PHYSX_RELEASE(controllerManager);
        PHYSX_RELEASE(scene);
        PHYSX_RELEASE(s_physx.dispatcher);
        // Every node releases its material when it is cleaned up, which happens before the
        // last world is deleted, so nothing should be left to release here
        Q_ASSERT(s_physx.materials.isEmpty());
        s_physx.materials.clear();
        PHYSX_RELEASE(s_physx.physics);
        PHYSX_RELEASE(s_physx.foundation);

        delete callback;
        callback = nullptr;
        s_physx.foundationCreated = false;
        s_physx.physicsCreated = false;
    } else {
        delete callback;
        callback = nullptr;
        PHYSX_RELEASE(controllerManager);
        PHYSX_RELEASE(scene);
    }
}

void QPhysXWorld::createScene(float typicalLength, float typicalSpeed, const QVector3D &gravity,
                              QPhysicsWorld *physicsWorld, unsigned int numThreads)
{
    if (scene) {
        qWarning() << "Scene already created";
        return;
    }

    physx::PxTolerancesScale scale;
    scale.length = typicalLength;
    scale.speed = typicalSpeed;

    auto &s_physx = StaticPhysXObjects::getReference();

    if (!s_physx.physicsCreated) {
        constexpr bool recordMemoryAllocations = true;
        s_physx.physics = PxCreatePhysics(PX_PHYSICS_VERSION, *s_physx.foundation, scale,
                                          recordMemoryAllocations);
        if (!s_physx.physics)
            qFatal("PxCreatePhysics failed!");

        s_physx.dispatcher = physx::PxDefaultCpuDispatcherCreate(numThreads);
        s_physx.physicsCreated = true;
    }

    callback = new SimulationEventCallback(physicsWorld);

    physx::PxSceneDesc sceneDesc(scale);
    sceneDesc.gravity = QPhysicsUtils::toPhysXType(gravity);
    sceneDesc.cpuDispatcher = s_physx.dispatcher;

    sceneDesc.filterShader = contactReportFilterShader;
    // CCD is always enabled at the scene level. Since PhysX's CCD pass is cheap enough
    // (see PxsCCDContext::updateCCD) when there are no CCD-enabled bodies in the scene,
    // it makes the code simpler.
    sceneDesc.flags |= physx::PxSceneFlag::eENABLE_CCD;
    sceneDesc.solverType = physx::PxSolverType::eTGS;
    sceneDesc.simulationEventCallback = callback;

    if (physicsWorld->reportKinematicKinematicCollisions())
        sceneDesc.kineKineFilteringMode = physx::PxPairFilteringMode::eKEEP;
    if (physicsWorld->reportStaticKinematicCollisions())
        sceneDesc.staticKineFilteringMode = physx::PxPairFilteringMode::eKEEP;

    switch (physicsWorld->staticQueryStructure()) {
    case QPhysicsWorld::QueryStructure::NoStructure: {
        Q_ASSERT(false && "Unreachable: setStaticQueryStructure() rejects NoStructure");
        break;
    }

    case QPhysicsWorld::QueryStructure::StaticTree: {
        sceneDesc.staticStructure = physx::PxPruningStructureType::eSTATIC_AABB_TREE;
        break;
    }

    case QPhysicsWorld::QueryStructure::DynamicTree: {
        sceneDesc.staticStructure = physx::PxPruningStructureType::eDYNAMIC_AABB_TREE;
        break;
    }

    }

    switch (physicsWorld->dynamicQueryStructure()) {
    case QPhysicsWorld::QueryStructure::NoStructure: {
        sceneDesc.dynamicStructure = physx::PxPruningStructureType::eNONE;
        break;
    }

    case QPhysicsWorld::QueryStructure::StaticTree: {
        sceneDesc.dynamicStructure = physx::PxPruningStructureType::eSTATIC_AABB_TREE;
        break;
    }

    case QPhysicsWorld::QueryStructure::DynamicTree: {
        sceneDesc.dynamicStructure = physx::PxPruningStructureType::eDYNAMIC_AABB_TREE;
        break;
    }

    }

    scene = s_physx.physics->createScene(sceneDesc);
}

QT_END_NAMESPACE
