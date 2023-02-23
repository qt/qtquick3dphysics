// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qcapsuleshape_p.h"
#include "qdebugdrawhelper_p.h"
#include "qphysicsworld_p.h"

#include "qabstractphysicsnode_p.h"
#include "qphysicsutils_p.h"
#include "qtriggerbody_p.h"
#include "qrigidbody_p.h"
#include "qplaneshape_p.h"
#include "qphysicscommands_p.h"

#include "PxPhysicsAPI.h"
#include "qcharactercontroller_p.h"
#include "qheightfieldshape_p.h"

#include "cooking/PxCooking.h"

#include "extensions/PxDefaultCpuDispatcher.h"

#include <QtQuick3D/private/qquick3dobject_p.h>
#include <QtQuick3D/private/qquick3dnode_p.h>
#include <QtQuick3D/private/qquick3dmodel_p.h>
#include <QtQuick3D/private/qquick3ddefaultmaterial_p.h>
#include <QtQuick3DUtils/private/qssgutils_p.h>

#define PHYSX_ENABLE_PVD 0

QT_BEGIN_NAMESPACE

/*!
    \qmltype PhysicsWorld
    \inqmlmodule QtQuick3D.Physics
    \since 6.4
    \brief Controls the physics simulation.

    The PhysicsWorld type controls the physics simulation. This node is used to create an instance of the physics world as well
    as define its properties. There can only be one physics world. All collision nodes in the qml
    will get added automatically to the physics world.
*/

/*!
    \qmlproperty vector3d PhysicsWorld::gravity
    This property defines the gravity vector of the physics world.
    The default value is \c (0, -981, 0). Set the value to \c{Qt.vector3d(0, -9.81, 0)} if your
    unit of measurement is meters and you are simulating Earth gravity.
*/

/*!
    \qmlproperty bool PhysicsWorld::running
    This property starts or stops the physical simulation. The default value is \c true.
*/

/*!
    \qmlproperty bool PhysicsWorld::forceDebugDraw
    This property enables debug drawing of all active shapes in the physics world. The default value
    is \c false.
*/

/*!
    \qmlproperty bool PhysicsWorld::enableCCD
    This property enables continuous collision detection. This will reduce the risk of bodies going
    through other bodies at high velocities (also known as tunnelling). The default value is \c
    false.
*/

/*!
    \qmlproperty float PhysicsWorld::typicalLength
    This property defines the approximate size of objects in the simulation. This is used to
    estimate certain length-related tolerances. Objects much smaller or much larger than this
    size may not behave properly. The default value is \c 100.

    Range: \c{[0, inf]}
*/

/*!
    \qmlproperty float PhysicsWorld::typicalSpeed
    This property defines the typical magnitude of velocities of objects in simulation. This is used
    to estimate whether a contact should be treated as bouncing or resting based on its impact
    velocity, and a kinetic energy threshold below which the simulation may put objects to sleep.

    For normal physical environments, a good choice is the approximate speed of an object falling
    under gravity for one second. The default value is \c 1000.

    Range: \c{[0, inf]}
*/

/*!
    \qmlproperty float PhysicsWorld::defaultDensity
    This property defines the default density of dynamic objects, measured in kilograms per cubic
    unit. This is equal to the weight of a cube with side \c 1.

    The default value is \c 0.001, corresponding to 1 g/cm³: the density of water. If your unit of
    measurement is meters, a good value would be \c 1000. Note that only positive values are
    allowed.

    Range: \c{(0, inf]}
*/

/*!
    \qmlproperty Node PhysicsWorld::viewport
    This property defines the viewport where debug components will be drawn if \l{forceDebugDraw}
    is enabled. If unset the \l{scene} node will be used.

    \sa forceDebugDraw, scene
*/

/*!
    \qmlproperty float PhysicsWorld::minimumTimestep
    This property defines the minimum simulation timestep in milliseconds. The default value is
    \c 16.667 which corresponds to \c 60 frames per second.

    Range: \c{[0, maximumTimestep]}
*/

/*!
    \qmlproperty float PhysicsWorld::maximumTimestep
    This property defines the maximum simulation timestep in milliseconds. The default value is
    \c 33.333 which corresponds to \c 30 frames per second.

    Range: \c{[0, inf]}
*/

/*!
    \qmlproperty Node PhysicsWorld::scene

    This property defines the top-most Node that contains all the nodes of the physical
    simulation. All physics objects that are an ancestor of this node will be seen as part of this
    PhysicsWorld.

    \note Using the same scene node for several PhysicsWorld is unsupported.
*/

/*!
    \qmlsignal PhysicsWorld::frameDone(float timestep)
    \since 6.5

    This signal is emitted when the physical simulation is done simulating a frame. The \a timestep
    parameter is how long in milliseconds the timestep was in the simulation.
*/

Q_LOGGING_CATEGORY(lcQuick3dPhysics, "qt.quick3d.physics");

static const QQuaternion kMinus90YawRotation = QQuaternion::fromEulerAngles(0, -90, 0);

static inline bool fuzzyEquals(const physx::PxTransform &a, const physx::PxTransform &b)
{
    return qFuzzyCompare(a.p.x, b.p.x) && qFuzzyCompare(a.p.y, b.p.y) && qFuzzyCompare(a.p.z, b.p.z)
            && qFuzzyCompare(a.q.x, b.q.x) && qFuzzyCompare(a.q.y, b.q.y)
            && qFuzzyCompare(a.q.z, b.q.z) && qFuzzyCompare(a.q.w, b.q.w);
}

static physx::PxTransform getPhysXWorldTransform(const QQuick3DNode *node)
{
    const QQuaternion &rotation = node->sceneRotation();
    const QVector3D worldPosition = node->scenePosition();
    return physx::PxTransform(QPhysicsUtils::toPhysXType(worldPosition),
                              QPhysicsUtils::toPhysXType(rotation));
}

static physx::PxTransform getPhysXWorldTransform(const QMatrix4x4 transform)
{
    auto rotationMatrix = transform;
    mat44::normalize(rotationMatrix);
    auto rotation =
            QQuaternion::fromRotationMatrix(mat44::getUpper3x3(rotationMatrix)).normalized();
    const QVector3D worldPosition = mat44::getPosition(transform);
    return physx::PxTransform(QPhysicsUtils::toPhysXType(worldPosition),
                              QPhysicsUtils::toPhysXType(rotation));
}

static physx::PxTransform getPhysXLocalTransform(const QQuick3DNode *node)
{
    // Modify transforms to make the PhysX shapes match the QtQuick3D conventions
    if (qobject_cast<const QPlaneShape *>(node) != nullptr) {
        // Rotate the plane to make it match the built-in rectangle
        const QQuaternion rotation = kMinus90YawRotation * node->rotation();
        return physx::PxTransform(QPhysicsUtils::toPhysXType(node->position()),
                                  QPhysicsUtils::toPhysXType(rotation));
    } else if (auto *hf = qobject_cast<const QHeightFieldShape *>(node)) {
        // Shift the height field so it's centered at the origin
        return physx::PxTransform(QPhysicsUtils::toPhysXType(node->position() + hf->hfOffset()),
                                  QPhysicsUtils::toPhysXType(node->rotation()));
    }

    const QQuaternion &rotation = node->rotation();
    const QVector3D &worldPosition = node->position();
    return physx::PxTransform(QPhysicsUtils::toPhysXType(worldPosition),
                              QPhysicsUtils::toPhysXType(rotation));
}

static physx::PxFilterFlags
contactReportFilterShader(physx::PxFilterObjectAttributes /*attributes0*/,
                          physx::PxFilterData /*filterData0*/,
                          physx::PxFilterObjectAttributes /*attributes1*/,
                          physx::PxFilterData /*filterData1*/, physx::PxPairFlags &pairFlags,
                          const void * /*constantBlock*/, physx::PxU32 /*constantBlockSize*/)
{
    // Makes objects collide
    const auto defaultCollisonFlags =
            physx::PxPairFlag::eSOLVE_CONTACT | physx::PxPairFlag::eDETECT_DISCRETE_CONTACT;

    // For trigger body detection
    const auto notifyTouchFlags =
            physx::PxPairFlag::eNOTIFY_TOUCH_FOUND | physx::PxPairFlag::eNOTIFY_TOUCH_LOST;

    // For contact detection
    const auto notifyContactFlags = physx::PxPairFlag::eNOTIFY_CONTACT_POINTS;

    pairFlags = defaultCollisonFlags | notifyTouchFlags | notifyContactFlags;
    return physx::PxFilterFlag::eDEFAULT;
}

static physx::PxFilterFlags
contactReportFilterShaderCCD(physx::PxFilterObjectAttributes /*attributes0*/,
                             physx::PxFilterData /*filterData0*/,
                             physx::PxFilterObjectAttributes /*attributes1*/,
                             physx::PxFilterData /*filterData1*/, physx::PxPairFlags &pairFlags,
                             const void * /*constantBlock*/, physx::PxU32 /*constantBlockSize*/)
{
    // Makes objects collide
    const auto defaultCollisonFlags = physx::PxPairFlag::eSOLVE_CONTACT
            | physx::PxPairFlag::eDETECT_DISCRETE_CONTACT | physx::PxPairFlag::eDETECT_CCD_CONTACT;

    // For trigger body detection
    const auto notifyTouchFlags =
            physx::PxPairFlag::eNOTIFY_TOUCH_FOUND | physx::PxPairFlag::eNOTIFY_TOUCH_LOST;

    // For contact detection
    const auto notifyContactFlags = physx::PxPairFlag::eNOTIFY_CONTACT_POINTS;

    pairFlags = defaultCollisonFlags | notifyTouchFlags | notifyContactFlags;
    return physx::PxFilterFlag::eDEFAULT;
}

class CallBackObject : public physx::PxSimulationEventCallback
{
public:
    CallBackObject(QPhysicsWorld *worldIn) : world(worldIn) {};
    virtual ~CallBackObject() = default;

    void onTrigger(physx::PxTriggerPair *pairs, physx::PxU32 count) override
    {
        for (physx::PxU32 i = 0; i < count; i++) {
            // ignore pairs when shapes have been deleted
            if (pairs[i].flags
                & (physx::PxTriggerPairFlag::eREMOVED_SHAPE_TRIGGER
                   | physx::PxTriggerPairFlag::eREMOVED_SHAPE_OTHER))
                continue;

            QAbstractPhysicsNode *triggerNode =
                    static_cast<QAbstractPhysicsNode *>(pairs[i].triggerActor->userData);

            QAbstractPhysicsNode *otherNode =
                    static_cast<QAbstractPhysicsNode *>(pairs[i].otherActor->userData);

            if (!triggerNode || !otherNode) {
                qWarning() << "QtQuick3DPhysics internal error: null pointer in trigger collision.";
                continue;
            }

            if (pairs->status == physx::PxPairFlag::eNOTIFY_TOUCH_FOUND) {
                if (otherNode->sendTriggerReports()) {
                    world->registerOverlap(pairs[i].triggerActor, pairs[i].otherActor);
                }
                if (otherNode->receiveTriggerReports()) {
                    emit otherNode->enteredTriggerBody(triggerNode);
                }
            } else if (pairs->status == physx::PxPairFlag::eNOTIFY_TOUCH_LOST) {
                if (otherNode->sendTriggerReports()) {
                    world->deregisterOverlap(pairs[i].triggerActor, pairs[i].otherActor);
                }
                if (otherNode->receiveTriggerReports()) {
                    emit otherNode->exitedTriggerBody(triggerNode);
                }
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

                if (!trigger || !other) //### TODO: handle character controllers
                    continue;

                const bool triggerReceive = world->hasReceiveContactReports(trigger)
                        && world->hasSendContactReports(other);
                const bool otherReceive = world->hasReceiveContactReports(other)
                        && world->hasSendContactReports(trigger);

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
                for (const QVector3D &v : normals) {
                    normalsInverted.push_back(QVector3D(-v.x(), -v.y(), -v.z()));
                }

                if (triggerReceive)
                    trigger->registerContact(other, positions, impulses, normals);
                if (otherReceive)
                    other->registerContact(trigger, positions, impulses, normalsInverted);
            }
        }
    };
    void onAdvance(const physx::PxRigidBody *const * /*bodyBuffer*/,
                   const physx::PxTransform * /*poseBuffer*/,
                   const physx::PxU32 /*count*/) override {};

private:
    QPhysicsWorld *world = nullptr;
};

#define PHYSX_RELEASE(x)                                                                           \
    if (x != nullptr) {                                                                            \
        x->release();                                                                              \
        x = nullptr;                                                                               \
    }

struct StaticPhysXObjects
{
    physx::PxDefaultErrorCallback defaultErrorCallback;
    physx::PxDefaultAllocator defaultAllocatorCallback;
    physx::PxFoundation *foundation = nullptr;
    physx::PxPvd *pvd = nullptr;
    physx::PxPvdTransport *transport = nullptr;
    physx::PxPhysics *physics = nullptr;
    physx::PxDefaultCpuDispatcher *dispatcher = nullptr;
    physx::PxCooking *cooking = nullptr;

    unsigned int foundationRefCount = 0;
    bool foundationCreated = false;
    bool physicsCreated = false;
};

StaticPhysXObjects s_physx = StaticPhysXObjects();

struct PhysXWorld
{
    void createWorld()
    {
        s_physx.foundationRefCount++;

        if (s_physx.foundationCreated)
            return;

        s_physx.foundation = PxCreateFoundation(
                PX_PHYSICS_VERSION, s_physx.defaultAllocatorCallback, s_physx.defaultErrorCallback);
        if (!s_physx.foundation)
            qFatal("PxCreateFoundation failed!");

        s_physx.foundationCreated = true;

#if PHYSX_ENABLE_PVD
        s_physx.pvd = PxCreatePvd(*m_physx->foundation);
        s_physx.transport = physx::PxDefaultPvdSocketTransportCreate("qt", 5425, 10);
        s_physx.pvd->connect(*m_physx->transport, physx::PxPvdInstrumentationFlag::eALL);
#endif

        // FIXME: does the tolerance matter?
        s_physx.cooking = PxCreateCooking(PX_PHYSICS_VERSION, *s_physx.foundation,
                                          physx::PxCookingParams(physx::PxTolerancesScale()));
    }

    void deleteWorld()
    {
        s_physx.foundationRefCount--;
        if (s_physx.foundationRefCount == 0) {
            PHYSX_RELEASE(controllerManager);
            PHYSX_RELEASE(scene);
            PHYSX_RELEASE(s_physx.dispatcher);
            PHYSX_RELEASE(s_physx.cooking);
            PHYSX_RELEASE(s_physx.transport);
            PHYSX_RELEASE(s_physx.pvd);
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

    void createScene(float typicalLength, float typicalSpeed, const QVector3D &gravity,
                     bool enableCCD, QPhysicsWorld *physicsWorld)
    {
        if (scene) {
            qWarning() << "Scene already created";
            return;
        }

        physx::PxTolerancesScale scale;
        scale.length = typicalLength;
        scale.speed = typicalSpeed;

        if (!s_physx.physicsCreated) {
            constexpr bool recordMemoryAllocations = true;
            s_physx.physics = PxCreatePhysics(PX_PHYSICS_VERSION, *s_physx.foundation, scale,
                                              recordMemoryAllocations, s_physx.pvd);
            if (!s_physx.physics)
                qFatal("PxCreatePhysics failed!");
            s_physx.dispatcher = physx::PxDefaultCpuDispatcherCreate(2);
            s_physx.physicsCreated = true;
        }

        callback = new CallBackObject(physicsWorld);

        physx::PxSceneDesc sceneDesc(scale);
        sceneDesc.gravity = QPhysicsUtils::toPhysXType(gravity);
        sceneDesc.cpuDispatcher = s_physx.dispatcher;

        if (enableCCD) {
            sceneDesc.filterShader = contactReportFilterShaderCCD;
            sceneDesc.flags |= physx::PxSceneFlag::eENABLE_CCD;
        } else {
            sceneDesc.filterShader = contactReportFilterShader;
        }
        sceneDesc.solverType = physx::PxSolverType::eTGS;
        sceneDesc.simulationEventCallback = callback;

        scene = s_physx.physics->createScene(sceneDesc);
    }

    // variables unique to each world/scene
    physx::PxControllerManager *controllerManager = nullptr;
    CallBackObject *callback = nullptr;
    physx::PxScene *scene = nullptr;
    bool isRunning = false;
};

// Used for debug drawing
enum class DebugDrawBodyType {
    Static = 0,
    DynamicAwake = 1,
    DynamicSleeping = 2,
    Trigger = 3,
    Unknown = 4
};

class QAbstractPhysXNode
{
public:
    QAbstractPhysXNode(QAbstractPhysicsNode *node) : frontendNode(node)
    {
        node->m_backendObject = this;
    }
    virtual ~QAbstractPhysXNode() { }

    bool cleanupIfRemoved(PhysXWorld *physX); // TODO rename??

    virtual void init(QPhysicsWorld *world, PhysXWorld *physX) = 0;
    virtual void updateDefaultDensity(float /*density*/) { }
    virtual void createMaterial(PhysXWorld *physX);
    void createMaterialFromQtMaterial(PhysXWorld *physX, QPhysicsMaterial *qtMaterial);
    virtual void markDirtyShapes() { }
    virtual void rebuildDirtyShapes(QPhysicsWorld *, PhysXWorld *) { }

    virtual void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) = 0;
    virtual void cleanup(PhysXWorld *)
    {
        for (auto *shape : shapes)
            PHYSX_RELEASE(shape);
        if (material != defaultMaterial)
            PHYSX_RELEASE(material);
    }
    virtual bool debugGeometryCapability() { return false; }
    virtual physx::PxTransform getGlobalPose() { return {}; }

    virtual bool useTriggerFlag() { return false; }
    virtual DebugDrawBodyType getDebugDrawBodyType() { return DebugDrawBodyType::Unknown; }

    bool shapesDirty() const { return frontendNode && frontendNode->m_shapesDirty; }
    void setShapesDirty(bool dirty) { frontendNode->m_shapesDirty = dirty; }

    QVector<physx::PxShape *> shapes;
    physx::PxMaterial *material = nullptr;
    QAbstractPhysicsNode *frontendNode = nullptr;
    bool isRemoved = false;
    static physx::PxMaterial *defaultMaterial;
};

physx::PxMaterial *QAbstractPhysXNode::defaultMaterial = nullptr;

bool QAbstractPhysXNode::cleanupIfRemoved(PhysXWorld *physX)
{
    if (isRemoved) {
        cleanup(physX);
        delete this;
        return true;
    }
    return false;
}

class QPhysXCharacterController : public QAbstractPhysXNode
{
public:
    QPhysXCharacterController(QCharacterController *frontEnd) : QAbstractPhysXNode(frontEnd) { }
    void cleanup(PhysXWorld *physX) override;
    void init(QPhysicsWorld *world, PhysXWorld *physX) override;

    void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) override;
    void createMaterial(PhysXWorld *physX) override;

private:
    physx::PxController *controller = nullptr;
};

class QPhysXActorBody : public QAbstractPhysXNode
{
public:
    QPhysXActorBody(QAbstractPhysicsNode *frontEnd) : QAbstractPhysXNode(frontEnd) { }
    void cleanup(PhysXWorld *physX) override
    {
        if (actor) {
            physX->scene->removeActor(*actor);
            PHYSX_RELEASE(actor);
        }
        QAbstractPhysXNode::cleanup(physX);
    }
    void init(QPhysicsWorld *world, PhysXWorld *physX) override;
    void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) override;
    void markDirtyShapes() override;
    void rebuildDirtyShapes(QPhysicsWorld *world, PhysXWorld *physX) override;
    virtual void createActor(PhysXWorld *physX);

    bool debugGeometryCapability() override { return true; }
    physx::PxTransform getGlobalPose() override { return actor->getGlobalPose(); }
    void buildShapes(PhysXWorld *physX);

    physx::PxRigidActor *actor = nullptr;
};

class QPhysXRigidBody : public QPhysXActorBody
{
public:
    QPhysXRigidBody(QAbstractPhysicsBody *frontEnd) : QPhysXActorBody(frontEnd) { }
    void createMaterial(PhysXWorld *physX) override;
};

class QPhysXStaticBody : public QPhysXRigidBody
{
public:
    QPhysXStaticBody(QStaticRigidBody *frontEnd) : QPhysXRigidBody(frontEnd) { }

    DebugDrawBodyType getDebugDrawBodyType() override;
    void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) override;
    void createActor(PhysXWorld *physX) override;
};

class QPhysXDynamicBody : public QPhysXRigidBody
{
public:
    QPhysXDynamicBody(QDynamicRigidBody *frontEnd) : QPhysXRigidBody(frontEnd) { }

    DebugDrawBodyType getDebugDrawBodyType() override;
    void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) override;
    void rebuildDirtyShapes(QPhysicsWorld *world, PhysXWorld *physX) override;
    void updateDefaultDensity(float density) override;
};

class QPhysXTriggerBody : public QPhysXActorBody
{
public:
    QPhysXTriggerBody(QTriggerBody *frontEnd) : QPhysXActorBody(frontEnd) { }

    DebugDrawBodyType getDebugDrawBodyType() override;
    void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) override;
    bool useTriggerFlag() override { return true; }
};

class QPhysXFactory
{
public:
    static QAbstractPhysXNode *createBackend(QAbstractPhysicsNode *node)
    { // TODO: virtual function in QAbstractPhysicsNode??

        if (auto *rigidBody = qobject_cast<QDynamicRigidBody *>(node))
            return new QPhysXDynamicBody(rigidBody);
        if (auto *staticBody = qobject_cast<QStaticRigidBody *>(node))
            return new QPhysXStaticBody(staticBody);
        if (auto *triggerBody = qobject_cast<QTriggerBody *>(node))
            return new QPhysXTriggerBody(triggerBody);
        if (auto *controller = qobject_cast<QCharacterController *>(node))
            return new QPhysXCharacterController(controller);
        Q_UNREACHABLE();
    }
};

/*
   NOTE
   The inheritance hierarchy is not ideal, since both controller and rigid body have materials,
   but trigger doesn't. AND both trigger and rigid body have actors, but controller doesn't.

   TODO: defaultMaterial isn't used for rigid bodies, since they always create their own
   QPhysicsMaterial with default values. We should only have a qt material when set explicitly.
   */

void QAbstractPhysXNode::createMaterialFromQtMaterial(PhysXWorld * /*physX*/,
                                                      QPhysicsMaterial *qtMaterial)
{
    if (qtMaterial) {
        material = s_physx.physics->createMaterial(qtMaterial->staticFriction(),
                                                   qtMaterial->dynamicFriction(),
                                                   qtMaterial->restitution());
    } else {
        if (!defaultMaterial) {
            defaultMaterial = s_physx.physics->createMaterial(
                    QPhysicsMaterial::defaultStaticFriction,
                    QPhysicsMaterial::defaultDynamicFriction, QPhysicsMaterial::defaultRestitution);
        }
        material = defaultMaterial;
    }
}

void QAbstractPhysXNode::createMaterial(PhysXWorld *physX)
{
    createMaterialFromQtMaterial(physX, nullptr);
}

void QPhysXCharacterController::createMaterial(PhysXWorld *physX)
{
    createMaterialFromQtMaterial(physX, static_cast<QCharacterController *>(frontendNode)->physicsMaterial());
}

void QPhysXRigidBody::createMaterial(PhysXWorld *physX)
{
    createMaterialFromQtMaterial(physX, static_cast<QAbstractPhysicsBody *>(frontendNode)->physicsMaterial());
}

void QPhysXActorBody::createActor(PhysXWorld * /*physX*/)
{
    physx::PxTransform trf = getPhysXWorldTransform(frontendNode);
    actor = s_physx.physics->createRigidDynamic(trf);
}

void QPhysXStaticBody::createActor(PhysXWorld * /*physX*/)
{
    physx::PxTransform trf = getPhysXWorldTransform(frontendNode);
    actor = s_physx.physics->createRigidStatic(trf);
}

void QPhysXActorBody::init(QPhysicsWorld *, PhysXWorld *physX)
{
    Q_ASSERT(!actor);

    createMaterial(physX);
    createActor(physX);

    actor->userData = reinterpret_cast<void *>(frontendNode);
    physX->scene->addActor(*actor);
    setShapesDirty(true);
}

void QPhysXCharacterController::cleanup(PhysXWorld *physX)
{
    PHYSX_RELEASE(controller);
    QAbstractPhysXNode::cleanup(physX);
}

void QPhysXCharacterController::init(QPhysicsWorld *world, PhysXWorld *physX)
{
    Q_ASSERT(!controller);

    auto *characterController = static_cast<QCharacterController *>(frontendNode);

    auto shapes = characterController->getCollisionShapesList();
    if (shapes.empty())
        return;
    auto *capsule = qobject_cast<QCapsuleShape *>(shapes.first());
    if (!capsule)
        return;

    auto *mgr = world->controllerManager();
    if (!mgr)
        return;

    createMaterial(physX);

    const QVector3D s = characterController->sceneScale();
    const qreal hs = s.y();
    const qreal rs = s.x();
    physx::PxCapsuleControllerDesc desc;
    desc.radius = rs * capsule->diameter() / 2;
    desc.height = hs * capsule->height();
    desc.stepOffset = desc.height / 4; // TODO: API

    desc.material = material;
    const QVector3D pos = characterController->scenePosition();
    desc.position = { pos.x(), pos.y(), pos.z() };
    controller = mgr->createController(desc);

    auto *actor = controller->getActor();
    if (actor)
        actor->userData = characterController;
    else
        qWarning() << "QtQuick3DPhysics internal error: CharacterController created without actor.";
}

void QPhysXDynamicBody::updateDefaultDensity(float density)
{
    QDynamicRigidBody *rigidBody = static_cast<QDynamicRigidBody *>(frontendNode);
    rigidBody->updateDefaultDensity(density);
}

DebugDrawBodyType QPhysXDynamicBody::getDebugDrawBodyType()
{
    auto dynamicActor = static_cast<physx::PxRigidDynamic *>(actor);
    return dynamicActor->isSleeping() ? DebugDrawBodyType::DynamicSleeping
                                      : DebugDrawBodyType::DynamicAwake;
}

void QPhysXActorBody::markDirtyShapes()
{
    if (!frontendNode || !actor)
        return;

    // Go through the shapes and look for a change in pose (rotation, position)
    // TODO: it is likely cheaper to connect a signal for changes on the position and rotation
    // property and mark the node dirty then.
    if (!shapesDirty()) {
        const auto &collisionShapes = frontendNode->getCollisionShapesList();
        const auto &physXShapes = shapes;

        const int len = collisionShapes.size();
        if (physXShapes.size() != len) {
            // This should not really happen but check it anyway
            setShapesDirty(true);
        } else {

            for (int i = 0; i < len; i++) {
                auto poseNew = getPhysXLocalTransform(collisionShapes[i]);
                auto poseOld = physXShapes[i]->getLocalPose();

                if (!fuzzyEquals(poseNew, poseOld)) {
                    setShapesDirty(true);
                    break;
                }
            }
        }
    }
}

void QPhysXActorBody::buildShapes(PhysXWorld * /*physX*/)
{
    auto body = actor;
    for (auto *shape : shapes) {
        body->detachShape(*shape);
        PHYSX_RELEASE(shape);
    }

    // TODO: Only remove changed shapes?
    shapes.clear();

    for (const auto &collisionShape : frontendNode->getCollisionShapesList()) {
        // TODO: shapes can be shared between multiple actors.
        // Do we need to create new ones for every body?
        auto *geom = collisionShape->getPhysXGeometry();
        if (!geom || !material)
            continue;
        auto physXShape = s_physx.physics->createShape(*geom, *material);

        if (useTriggerFlag()) {
            physXShape->setFlag(physx::PxShapeFlag::eSIMULATION_SHAPE, false);
            physXShape->setFlag(physx::PxShapeFlag::eTRIGGER_SHAPE, true);
        }

        shapes.push_back(physXShape);
        physXShape->setLocalPose(getPhysXLocalTransform(collisionShape));
        body->attachShape(*physXShape);
    }
}

void QPhysXActorBody::rebuildDirtyShapes(QPhysicsWorld *, PhysXWorld *physX)
{
    if (!shapesDirty())
        return;
    buildShapes(physX);
    setShapesDirty(false);
}

void QPhysXDynamicBody::rebuildDirtyShapes(QPhysicsWorld *world, PhysXWorld *physX)
{
    if (!shapesDirty())
        return;

    buildShapes(physX);

    QDynamicRigidBody *drb = static_cast<QDynamicRigidBody *>(frontendNode);

    // Density must be set after shapes so the inertia tensor is set
    if (!drb->hasStaticShapes()) {
        // Body with only dynamic shapes, set/calculate mass
        QPhysicsCommand *command = nullptr;
        switch (drb->massMode()) {
        case QDynamicRigidBody::MassMode::DefaultDensity: {
            command = new QPhysicsCommandSetDensity(world->defaultDensity());
            break;
        }
        case QDynamicRigidBody::MassMode::CustomDensity: {
            command = new QPhysicsCommandSetDensity(drb->density());
            break;
        }
        case QDynamicRigidBody::MassMode::Mass: {
            const float mass = qMax(drb->mass(), 0.f);
            command = new QPhysicsCommandSetMass(mass);
            break;
        }
        case QDynamicRigidBody::MassMode::MassAndInertiaTensor: {
            const float mass = qMax(drb->mass(), 0.f);
            command = new QPhysicsCommandSetMassAndInertiaTensor(mass, drb->inertiaTensor());
            break;
        }
        case QDynamicRigidBody::MassMode::MassAndInertiaMatrix: {
            const float mass = qMax(drb->mass(), 0.f);
            command = new QPhysicsCommandSetMassAndInertiaMatrix(mass, drb->inertiaMatrix());
            break;
        }
        }

        drb->commandQueue().enqueue(command);
    } else if (!drb->isKinematic()) {
        // Body with static shapes that is not kinematic, this is disallowed
        qWarning() << "Cannot make body containing trimesh/heightfield/plane non-kinematic, "
                      "forcing kinematic.";
        drb->setIsKinematic(true);
    }

    auto *dynamicBody = static_cast<physx::PxRigidDynamic *>(actor);
    dynamicBody->setRigidBodyFlag(physx::PxRigidBodyFlag::eKINEMATIC, drb->isKinematic());

    if (world->enableCCD() && !drb->isKinematic()) // CCD not supported for kinematic bodies
        dynamicBody->setRigidBodyFlag(physx::PxRigidBodyFlag::eENABLE_CCD, true);

    setShapesDirty(false);
}

static void processCommandQueue(QQueue<QPhysicsCommand *> &commandQueue,
                                const QDynamicRigidBody &rigidBody, physx::PxRigidBody &body)
{
    for (auto command : commandQueue) {
        command->execute(rigidBody, body);
        delete command;
    }

    commandQueue.clear();
}

static QMatrix4x4 calculateKinematicNodeTransform(QQuick3DNode *node,
                                                  QHash<QQuick3DNode *, QMatrix4x4> &transformCache)
{
    // already calculated transform
    if (transformCache.contains(node))
        return transformCache[node];

    QMatrix4x4 localTransform;

    // DynamicRigidBody vs StaticRigidBody use different values for calculating the local transform
    if (auto drb = qobject_cast<const QDynamicRigidBody *>(node); drb != nullptr) {
        if (!drb->isKinematic()) {
            qWarning() << "Non-kinematic body as a parent of a kinematic body is unsupported";
        }
        localTransform = QSSGRenderNode::calculateTransformMatrix(
                drb->kinematicPosition(), drb->scale(), drb->kinematicPivot(), drb->kinematicRotation());
    } else {
        localTransform = QSSGRenderNode::calculateTransformMatrix(node->position(), node->scale(),
                                                                  node->pivot(), node->rotation());
    }

    QQuick3DNode *parent = node->parentNode();
    if (!parent) // no parent, local transform is scene transform
        return localTransform;

    // calculate the parent scene transform and apply the nodes local transform
    QMatrix4x4 parentTransform = calculateKinematicNodeTransform(parent, transformCache);
    QMatrix4x4 sceneTransform = parentTransform * localTransform;

    transformCache[node] = sceneTransform;
    return sceneTransform;
}

static physx::PxRigidDynamicLockFlags getLockFlags(QDynamicRigidBody *body)
{
    const auto lockAngular = body->angularAxisLock();
    const auto lockLinear = body->linearAxisLock();
    const int flags = (lockAngular & QDynamicRigidBody::AxisLock::LockX
                               ? physx::PxRigidDynamicLockFlag::eLOCK_ANGULAR_X
                               : 0)
            | (lockAngular & QDynamicRigidBody::AxisLock::LockY
                       ? physx::PxRigidDynamicLockFlag::eLOCK_ANGULAR_Y
                       : 0)
            | (lockAngular & QDynamicRigidBody::AxisLock::LockZ
                       ? physx::PxRigidDynamicLockFlag::eLOCK_ANGULAR_Z
                       : 0)
            | (lockLinear & QDynamicRigidBody::AxisLock::LockX
                       ? physx::PxRigidDynamicLockFlag::eLOCK_LINEAR_X
                       : 0)
            | (lockLinear & QDynamicRigidBody::AxisLock::LockY
                       ? physx::PxRigidDynamicLockFlag::eLOCK_LINEAR_Y
                       : 0)
            | (lockLinear & QDynamicRigidBody::AxisLock::LockZ
                       ? physx::PxRigidDynamicLockFlag::eLOCK_LINEAR_Z
                       : 0);
    return static_cast<physx::PxRigidDynamicLockFlags>(flags);
}

static void updatePhysXMaterial(const QPhysicsMaterial *qtMaterial,
                                physx::PxMaterial *physXMaterial)
{
    const float staticFriction = qtMaterial->staticFriction();
    const float dynamicFriction = qtMaterial->dynamicFriction();
    const float restitution = qtMaterial->restitution();
    if (physXMaterial->getStaticFriction() != staticFriction)
        physXMaterial->setStaticFriction(staticFriction);
    if (physXMaterial->getDynamicFriction() != dynamicFriction)
        physXMaterial->setDynamicFriction(dynamicFriction);
    if (physXMaterial->getRestitution() != restitution)
        physXMaterial->setRestitution(restitution);
}

void QPhysXActorBody::sync(float /*deltaTime*/, QHash<QQuick3DNode *, QMatrix4x4> & /*transformCache*/)
{
    auto *body = static_cast<QAbstractPhysicsBody *>(frontendNode);
    if (QPhysicsMaterial *qtMaterial = body->physicsMaterial()) {
        updatePhysXMaterial(qtMaterial, material);
    }
}

DebugDrawBodyType QPhysXTriggerBody::getDebugDrawBodyType()
{
    return DebugDrawBodyType::Trigger;
}

void QPhysXTriggerBody::sync(float /*deltaTime*/, QHash<QQuick3DNode *, QMatrix4x4> & /*transformCache*/)
{
    auto *triggerBody = static_cast<QTriggerBody *>(frontendNode);
    actor->setGlobalPose(getPhysXWorldTransform(triggerBody));
}

void QPhysXDynamicBody::sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache)
{
    auto *dynamicRigidBody = static_cast<QDynamicRigidBody *>(frontendNode);
    // first update front end node from physx simulation
    dynamicRigidBody->updateFromPhysicsTransform(actor->getGlobalPose());

    auto *dynamicActor = static_cast<physx::PxRigidDynamic *>(actor);
    processCommandQueue(dynamicRigidBody->commandQueue(), *dynamicRigidBody, *dynamicActor);
    if (dynamicRigidBody->isKinematic()) {
        // Since this is a kinematic body we need to calculate the transform by hand and since
        // bodies can occur in other bodies we need to calculate the tranform recursively for all
        // parents. To save some computation we cache these transforms in 'transformCache'.
        QMatrix4x4 transform = calculateKinematicNodeTransform(dynamicRigidBody, transformCache);
        dynamicActor->setKinematicTarget(getPhysXWorldTransform(transform));
    } else {
        dynamicActor->setRigidDynamicLockFlags(getLockFlags(dynamicRigidBody));
    }
    QPhysXActorBody::sync(deltaTime, transformCache);
}

void QPhysXCharacterController::sync(float deltaTime,
                                     QHash<QQuick3DNode *, QMatrix4x4> & /*transformCache*/)
{
    Q_ASSERT(controller);
    auto pos = controller->getPosition();
    QVector3D qtPosition(pos.x, pos.y, pos.z);
    auto *characterController = static_cast<QCharacterController *>(frontendNode);

    // update node from physX
    const QQuick3DNode *parentNode = static_cast<QQuick3DNode *>(characterController->parentItem());
    if (!parentNode) {
        // then it is the same space
        characterController->setPosition(qtPosition);
    } else {
        characterController->setPosition(parentNode->mapPositionFromScene(qtPosition));
    }
    QVector3D teleportPos;
    bool teleport = characterController->getTeleport(teleportPos);
    if (teleport) {
        controller->setPosition({ teleportPos.x(), teleportPos.y(), teleportPos.z() });
    } else if (deltaTime > 0) {
        const auto displacement = QPhysicsUtils::toPhysXType(characterController->getDisplacement(deltaTime));
        auto collisions =
                controller->move(displacement, displacement.magnitude() / 100, deltaTime, {});
        characterController->setCollisions(QCharacterController::Collisions(uint(collisions)));
    }
    // QCharacterController has a material property, but we don't inherit from
    // QPhysXMaterialBody, so we create the material manually in init()
    // TODO: handle material changes
}

DebugDrawBodyType QPhysXStaticBody::getDebugDrawBodyType()
{
    return DebugDrawBodyType::Static;
}

void QPhysXStaticBody::sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache)
{
    auto *staticBody = static_cast<QStaticRigidBody *>(frontendNode);
    const physx::PxTransform poseNew = getPhysXWorldTransform(staticBody);
    const physx::PxTransform poseOld = actor->getGlobalPose();

    // For performance we only update static objects if they have been moved
    if (!fuzzyEquals(poseNew, poseOld))
        actor->setGlobalPose(poseNew);
    QPhysXActorBody::sync(deltaTime, transformCache);
}

/////////////////////////////////////////////////////////////////////////////

class SimulationWorker : public QObject
{
    Q_OBJECT
public:
    SimulationWorker(PhysXWorld *physx) : m_physx(physx) { }

public slots:
    void simulateFrame(float minTimestep, float maxTimestep)
    {
        if (!m_physx->isRunning) {
            m_timer.start();
            m_physx->isRunning = true;
        }

        // Assuming: 0 <= minTimestep <= maxTimestep

        constexpr auto MILLIONTH = 0.000001;

        // If not enough time has elapsed we sleep until it has
        auto deltaMS = m_timer.nsecsElapsed() * MILLIONTH;
        while (deltaMS < minTimestep) {
            auto sleepUSecs = (minTimestep - deltaMS) * 1000.f;
            QThread::usleep(sleepUSecs);
            deltaMS = m_timer.nsecsElapsed() * MILLIONTH;
        }
        m_timer.restart();

        auto deltaSecs = qMin(float(deltaMS), maxTimestep) * 0.001f;
        m_physx->scene->simulate(deltaSecs);
        m_physx->scene->fetchResults(true);

        emit frameDone(deltaSecs);
    }

signals:
    void frameDone(float deltaTime);

private:
    PhysXWorld *m_physx = nullptr;
    QElapsedTimer m_timer;
};

/////////////////////////////////////////////////////////////////////////////

struct QWorldManager
{
    QVector<QPhysicsWorld *> worlds;
    QVector<QAbstractPhysicsNode *> orphanNodes;
};

static QWorldManager worldManager = QWorldManager {};

void QPhysicsWorld::registerNode(QAbstractPhysicsNode *physicsNode)
{
    auto world = getWorld(physicsNode);
    if (world) {
        world->m_newPhysicsNodes.push_back(physicsNode);
    } else {
        worldManager.orphanNodes.push_back(physicsNode);
    }
}

void QPhysicsWorld::deregisterNode(QAbstractPhysicsNode *physicsNode)
{
    for (auto world : worldManager.worlds) {
        world->m_newPhysicsNodes.removeAll(physicsNode);
        if (physicsNode->m_backendObject) {
            physicsNode->m_backendObject->isRemoved = true;
            physicsNode->m_backendObject = nullptr;
        }
        QMutexLocker locker(&world->m_removedPhysicsNodesMutex);
        world->m_removedPhysicsNodes.insert(physicsNode);
    }
    worldManager.orphanNodes.removeAll(physicsNode);
}

QPhysicsWorld::QPhysicsWorld(QObject *parent) : QObject(parent)
{
    m_physx = new PhysXWorld;
    m_physx->createWorld();

    worldManager.worlds.push_back(this);
    matchOrphanNodes();
}

QPhysicsWorld::~QPhysicsWorld()
{
    m_workerThread.quit();
    m_workerThread.wait();
    m_physx->deleteWorld();
    delete m_physx;
    worldManager.worlds.removeAll(this);

    for (auto body : m_physXBodies) {
        delete body;
    }
}

void QPhysicsWorld::classBegin() {}

void QPhysicsWorld::componentComplete()
{
    if (!m_running || m_physicsInitialized)
        return;
    initPhysics();
    emit simulateFrame(m_minTimestep, m_maxTimestep);
}

QVector3D QPhysicsWorld::gravity() const
{
    return m_gravity;
}

bool QPhysicsWorld::running() const
{
    return m_running;
}

bool QPhysicsWorld::forceDebugDraw() const
{
    return m_forceDebugDraw;
}

bool QPhysicsWorld::enableCCD() const
{
    return m_enableCCD;
}

float QPhysicsWorld::typicalLength() const
{
    return m_typicalLength;
}

float QPhysicsWorld::typicalSpeed() const
{
    return m_typicalSpeed;
}

void QPhysicsWorld::registerOverlap(physx::PxRigidActor *triggerActor,
                                     physx::PxRigidActor *otherActor)
{
    QTriggerBody *trigger = static_cast<QTriggerBody *>(triggerActor->userData);
    QAbstractPhysicsNode *other = static_cast<QAbstractPhysicsNode *>(otherActor->userData);

    QMutexLocker locker(&m_removedPhysicsNodesMutex);
    if (!m_removedPhysicsNodes.contains(other) && !m_removedPhysicsNodes.contains(trigger))
        trigger->registerCollision(other);
}

void QPhysicsWorld::deregisterOverlap(physx::PxRigidActor *triggerActor,
                                       physx::PxRigidActor *otherActor)
{
    QTriggerBody *trigger = static_cast<QTriggerBody *>(triggerActor->userData);
    QAbstractPhysicsNode *other = static_cast<QAbstractPhysicsNode *>(otherActor->userData);

    QMutexLocker locker(&m_removedPhysicsNodesMutex);
    if (!m_removedPhysicsNodes.contains(other) && !m_removedPhysicsNodes.contains(trigger))
        trigger->deregisterCollision(other);
}

bool QPhysicsWorld::hasSendContactReports(QAbstractPhysicsNode *object)
{
    QMutexLocker locker(&m_removedPhysicsNodesMutex);
    return !m_removedPhysicsNodes.contains(object) && object->m_backendObject
            && object->sendContactReports();
}

bool QPhysicsWorld::hasReceiveContactReports(QAbstractPhysicsNode *object)
{
    QMutexLocker locker(&m_removedPhysicsNodesMutex);
    return !m_removedPhysicsNodes.contains(object) && object->m_backendObject
            && object->receiveContactReports();
}

void QPhysicsWorld::setGravity(QVector3D gravity)
{
    if (m_gravity == gravity)
        return;

    m_gravity = gravity;
    if (m_physx->scene) {
        m_physx->scene->setGravity(QPhysicsUtils::toPhysXType(m_gravity));
    }
    emit gravityChanged(m_gravity);
}

void QPhysicsWorld::setRunning(bool running)
{
    if (m_running == running)
        return;

    m_running = running;
    if (m_running && !m_physicsInitialized)
        initPhysics();
    if (m_running)
        emit simulateFrame(m_minTimestep, m_maxTimestep);
    emit runningChanged(m_running);
}

void QPhysicsWorld::setForceDebugDraw(bool forceDebugDraw)
{
    if (m_forceDebugDraw == forceDebugDraw)
        return;

    m_forceDebugDraw = forceDebugDraw;
    if (!m_forceDebugDraw)
        disableDebugDraw();
    else
        updateDebugDraw();
    emit forceDebugDrawChanged(m_forceDebugDraw);
}

QQuick3DNode *QPhysicsWorld::viewport() const
{
    return m_viewport;
}

void QPhysicsWorld::setHasIndividualDebugDraw()
{
    m_hasIndividualDebugDraw = true;
}

void QPhysicsWorld::setViewport(QQuick3DNode *viewport)
{
    if (m_viewport == viewport)
        return;

    m_viewport = viewport;

    // TODO: test this
    for (auto material : m_debugMaterials)
        delete material;
    m_debugMaterials.clear();

    for (auto &holder : m_collisionShapeDebugModels) {
        delete holder.model;
    }
    m_collisionShapeDebugModels.clear();

    emit viewportChanged(m_viewport);
}

void QPhysicsWorld::setMinimumTimestep(float minTimestep)
{
    if (qFuzzyCompare(m_minTimestep, minTimestep))
        return;

    if (minTimestep > m_maxTimestep) {
        qWarning("Minimum timestep greater than maximum timestep, value clamped");
        minTimestep = qMin(minTimestep, m_maxTimestep);
    }

    if (minTimestep < 0.f) {
        qWarning("Minimum timestep less than zero, value clamped");
        minTimestep = qMax(minTimestep, 0.f);
    }

    if (qFuzzyCompare(m_minTimestep, minTimestep))
        return;

    m_minTimestep = minTimestep;
    emit minimumTimestepChanged(m_minTimestep);
}

void QPhysicsWorld::setMaximumTimestep(float maxTimestep)
{
    if (qFuzzyCompare(m_maxTimestep, maxTimestep))
        return;

    if (maxTimestep < 0.f) {
        qWarning("Maximum timestep less than zero, value clamped");
        maxTimestep = qMax(maxTimestep, 0.f);
    }

    if (qFuzzyCompare(m_maxTimestep, maxTimestep))
        return;

    m_maxTimestep = maxTimestep;
    emit maximumTimestepChanged(maxTimestep);
}

void QPhysicsWorld::updateDebugDraw()
{
    if (!(m_forceDebugDraw || m_hasIndividualDebugDraw)) {
        // Nothing to draw, trash all previous models (if any) and return
        if (!m_collisionShapeDebugModels.isEmpty()) {
            for (const auto& holder : std::as_const(m_collisionShapeDebugModels))
                delete holder.model;
            m_collisionShapeDebugModels.clear();
        }
        return;
    }

    // Use scene node if no viewport has been specified
    auto sceneNode = m_viewport ? m_viewport : m_scene;

    if (sceneNode == nullptr)
        return;

    if (m_debugMaterials.isEmpty()) {
        // These colors match the indices of DebugDrawBodyType enum
        for (auto color : { QColorConstants::Svg::chartreuse, QColorConstants::Svg::cyan,
                            QColorConstants::Svg::lightsalmon, QColorConstants::Svg::red,
                            QColorConstants::Svg::black }) {
            auto debugMaterial = new QQuick3DDefaultMaterial();
            debugMaterial->setLineWidth(3);
            debugMaterial->setParentItem(sceneNode);
            debugMaterial->setParent(sceneNode);
            debugMaterial->setDiffuseColor(color);
            debugMaterial->setLighting(QQuick3DDefaultMaterial::NoLighting);
            debugMaterial->setCullMode(QQuick3DMaterial::NoCulling);
            m_debugMaterials.push_back(debugMaterial);
        }
    }

    m_hasIndividualDebugDraw = false;

    // Store the collision shapes we have now so we can clear out the removed ones
    QSet<QAbstractCollisionShape *> currentCollisionShapes;
    currentCollisionShapes.reserve(m_collisionShapeDebugModels.size());

    for (QAbstractPhysXNode *node : m_physXBodies) {
        if (!node->debugGeometryCapability())
            continue;

        const auto &collisionShapes = node->frontendNode->getCollisionShapesList();
        const int materialIdx = static_cast<int>(node->getDebugDrawBodyType());
        const int length = collisionShapes.length();
        if (node->shapes.length() < length)
            continue; // CharacterController has shapes, but not PhysX shapes
        for (int idx = 0; idx < length; idx++) {
            const auto collisionShape = collisionShapes[idx];
            const auto physXShape = node->shapes[idx];
            DebugModelHolder &holder = m_collisionShapeDebugModels[collisionShape];
            auto &model = holder.model;

            if (!m_forceDebugDraw && !collisionShape->enableDebugDraw())
                continue;

            currentCollisionShapes.insert(collisionShape);

            m_hasIndividualDebugDraw =
                    m_hasIndividualDebugDraw || collisionShape->enableDebugDraw();

            auto localPose = physXShape->getLocalPose();

            // Create/Update debug view infrastructure
            if (!model) {
                model = new QQuick3DModel();
                model->setParentItem(sceneNode);
                model->setParent(sceneNode);
                model->setCastsShadows(false);
                model->setReceivesShadows(false);
                model->setCastsReflections(false);
            }

            { // update or set material
                auto material = m_debugMaterials[materialIdx];
                QQmlListReference materialsRef(model, "materials");
                if (materialsRef.count() == 0 || materialsRef.at(0) != material) {
                    materialsRef.clear();
                    materialsRef.append(material);
                }
            }

            switch (physXShape->getGeometryType()) {
            case physx::PxGeometryType::eBOX: {
                physx::PxBoxGeometry boxGeometry;
                physXShape->getBoxGeometry(boxGeometry);
                const auto &halfExtentsOld = holder.halfExtents();
                const auto halfExtents = QPhysicsUtils::toQtType(boxGeometry.halfExtents);
                if (!qFuzzyCompare(halfExtentsOld, halfExtents)) {
                    auto geom = QDebugDrawHelper::generateBoxGeometry(halfExtents);
                    model->setGeometry(geom);
                    holder.setHalfExtents(halfExtents);
                }

            }
                break;

            case physx::PxGeometryType::eSPHERE: {
                physx::PxSphereGeometry sphereGeometry;
                physXShape->getSphereGeometry(sphereGeometry);
                const float radius = holder.radius();
                if (!qFuzzyCompare(sphereGeometry.radius, radius)) {
                    auto geom = QDebugDrawHelper::generateSphereGeometry(sphereGeometry.radius);
                    model->setGeometry(geom);
                    holder.setRadius(sphereGeometry.radius);
                }
            }
                break;

            case physx::PxGeometryType::eCAPSULE: {
                physx::PxCapsuleGeometry capsuleGeometry;
                physXShape->getCapsuleGeometry(capsuleGeometry);
                const float radius = holder.radius();
                const float halfHeight = holder.halfHeight();

                if (!qFuzzyCompare(capsuleGeometry.radius, radius)
                    || !qFuzzyCompare(capsuleGeometry.halfHeight, halfHeight)) {
                    auto geom = QDebugDrawHelper::generateCapsuleGeometry(
                            capsuleGeometry.radius, capsuleGeometry.halfHeight);
                    model->setGeometry(geom);
                    holder.setRadius(capsuleGeometry.radius);
                    holder.setHalfHeight(capsuleGeometry.halfHeight);
                }
            }
                break;

            case physx::PxGeometryType::ePLANE:{
                physx::PxPlaneGeometry planeGeometry;
                physXShape->getPlaneGeometry(planeGeometry);
                // Special rotation
                const QQuaternion rotation =
                        kMinus90YawRotation * QPhysicsUtils::toQtType(localPose.q);
                localPose = physx::PxTransform(localPose.p, QPhysicsUtils::toPhysXType(rotation));

                if (model->geometry() == nullptr) {
                    auto geom = QDebugDrawHelper::generatePlaneGeometry();
                    model->setGeometry(geom);
                }
            }
                break;

            case physx::PxGeometryType::eHEIGHTFIELD: {
                physx::PxHeightFieldGeometry heightFieldGeometry;
                physXShape->getHeightFieldGeometry(heightFieldGeometry);
                const float heightScale = holder.heightScale();
                const float rowScale = holder.rowScale();
                const float columnScale = holder.columnScale();

                if (!qFuzzyCompare(heightFieldGeometry.heightScale, heightScale)
                    || !qFuzzyCompare(heightFieldGeometry.rowScale, rowScale)
                    || !qFuzzyCompare(heightFieldGeometry.columnScale, columnScale)) {

                    auto geom = QDebugDrawHelper::generateHeightFieldGeometry(
                            heightFieldGeometry.heightField, heightFieldGeometry.heightScale,
                            heightFieldGeometry.rowScale, heightFieldGeometry.columnScale);
                    model->setGeometry(geom);
                    holder.setHeightScale(heightFieldGeometry.heightScale);
                    holder.setRowScale(heightFieldGeometry.rowScale);
                    holder.setColumnScale(heightFieldGeometry.columnScale);
                }
            }
                break;

            case physx::PxGeometryType::eCONVEXMESH: {
                physx::PxConvexMeshGeometry convexMeshGeometry;
                physXShape->getConvexMeshGeometry(convexMeshGeometry);
                const auto rotation = convexMeshGeometry.scale.rotation * localPose.q;
                localPose = physx::PxTransform(localPose.p, rotation);
                model->setScale(QPhysicsUtils::toQtType(convexMeshGeometry.scale.scale));

                if (model->geometry() == nullptr) {
                    auto geom = QDebugDrawHelper::generateConvexMeshGeometry(
                            convexMeshGeometry.convexMesh);
                    model->setGeometry(geom);
                }
            }
                break;

            case physx::PxGeometryType::eTRIANGLEMESH: {
                physx::PxTriangleMeshGeometry triangleMeshGeometry;
                physXShape->getTriangleMeshGeometry(triangleMeshGeometry);
                const auto rotation = triangleMeshGeometry.scale.rotation * localPose.q;
                localPose = physx::PxTransform(localPose.p, rotation);
                model->setScale(QPhysicsUtils::toQtType(triangleMeshGeometry.scale.scale));

                if (model->geometry() == nullptr) {
                    auto geom = QDebugDrawHelper::generateTriangleMeshGeometry(
                            triangleMeshGeometry.triangleMesh);
                    model->setGeometry(geom);
                }
            }
                break;

            case physx::PxGeometryType::eINVALID:
            case physx::PxGeometryType::eGEOMETRY_COUNT:
                // should not happen
                Q_UNREACHABLE();
            }

            model->setVisible(true);

            auto globalPose = node->getGlobalPose();
            auto finalPose = globalPose.transform(localPose);

            model->setRotation(QPhysicsUtils::toQtType(finalPose.q));
            model->setPosition(QPhysicsUtils::toQtType(finalPose.p));
        }
    }

    // Remove old collision shapes
    m_collisionShapeDebugModels.removeIf(
            [&](QHash<QAbstractCollisionShape *, DebugModelHolder>::iterator it) {
                auto shape = it.key();
                auto holder = it.value();
                if (!currentCollisionShapes.contains(shape)) {
                    if (holder.model)
                        delete holder.model;
                    return true;
                }
                return false;
            });
}

void QPhysicsWorld::disableDebugDraw()
{
    m_hasIndividualDebugDraw = false;

    for (QAbstractPhysXNode *body : m_physXBodies) {
        const auto &collisionShapes = body->frontendNode->getCollisionShapesList();
        const int length = collisionShapes.length();
        for (int idx = 0; idx < length; idx++) {
            const auto collisionShape = collisionShapes[idx];
            if (collisionShape->enableDebugDraw()) {
                m_hasIndividualDebugDraw = true;
                return;
            }
        }
    }
}

void QPhysicsWorld::setEnableCCD(bool enableCCD)
{
    if (m_enableCCD == enableCCD)
        return;

    if (m_physicsInitialized) {
        qWarning()
                << "Warning: Changing 'enableCCD' after physics is initialized will have no effect";
        return;
    }

    m_enableCCD = enableCCD;
    emit enableCCDChanged(m_enableCCD);
}

void QPhysicsWorld::setTypicalLength(float typicalLength)
{
    if (qFuzzyCompare(typicalLength, m_typicalLength))
        return;

    if (typicalLength <= 0.f) {
        qWarning() << "Warning: 'typicalLength' value less than zero, ignored";
        return;
    }

    if (m_physicsInitialized) {
        qWarning() << "Warning: Changing 'typicalLength' after physics is initialized will have "
                      "no effect";
        return;
    }

    m_typicalLength = typicalLength;

    emit typicalLengthChanged(typicalLength);
}

void QPhysicsWorld::setTypicalSpeed(float typicalSpeed)
{
    if (qFuzzyCompare(typicalSpeed, m_typicalSpeed))
        return;

    if (m_physicsInitialized) {
        qWarning() << "Warning: Changing 'typicalSpeed' after physics is initialized will have "
                      "no effect";
        return;
    }

    m_typicalSpeed = typicalSpeed;

    emit typicalSpeedChanged(typicalSpeed);
}

float QPhysicsWorld::defaultDensity() const
{
    return m_defaultDensity;
}

float QPhysicsWorld::minimumTimestep() const
{
    return m_minTimestep;
}

float QPhysicsWorld::maximumTimestep() const
{
    return m_maxTimestep;
}

void QPhysicsWorld::setDefaultDensity(float defaultDensity)
{
    if (qFuzzyCompare(m_defaultDensity, defaultDensity))
        return;
    m_defaultDensity = defaultDensity;

    // Go through all dynamic rigid bodies and update the default density
    for (QAbstractPhysXNode *body : m_physXBodies)
        body->updateDefaultDensity(m_defaultDensity);

    emit defaultDensityChanged(defaultDensity);
}

// Remove physics world items that no longer exist

void QPhysicsWorld::cleanupRemovedNodes()
{
    m_physXBodies.removeIf([this](QAbstractPhysXNode *body) {
                               return body->cleanupIfRemoved(m_physx);
                           });
    // We don't need to lock the mutex here since the simulation
    // worker is waiting
    m_removedPhysicsNodes.clear();
}

void QPhysicsWorld::initPhysics()
{
    Q_ASSERT(!m_physicsInitialized);

    m_physx->createScene(m_typicalLength, m_typicalSpeed, m_gravity, m_enableCCD, this);

    // Setup worker thread
    SimulationWorker *worker = new SimulationWorker(m_physx);
    worker->moveToThread(&m_workerThread);
    connect(&m_workerThread, &QThread::finished, worker, &QObject::deleteLater);
    connect(this, &QPhysicsWorld::simulateFrame, worker, &SimulationWorker::simulateFrame);
    connect(worker, &SimulationWorker::frameDone, this, &QPhysicsWorld::frameFinished);
    m_workerThread.start();

    m_physicsInitialized = true;
}

void QPhysicsWorld::frameFinished(float deltaTime)
{
    matchOrphanNodes();
    cleanupRemovedNodes();
    for (auto *node : std::as_const(m_newPhysicsNodes)) {
        auto *body = QPhysXFactory::createBackend(node);
        body->init(this, m_physx);
        m_physXBodies.push_back(body);
    }
    m_newPhysicsNodes.clear();

    QHash<QQuick3DNode *, QMatrix4x4> transformCache;

    // TODO: Use dirty flag/dirty list to avoid redoing things that didn't change
    for (auto *physXBody : std::as_const(m_physXBodies)) {
        physXBody->markDirtyShapes();
        physXBody->rebuildDirtyShapes(this, m_physx);

        // Sync the physics world and the scene
        physXBody->sync(deltaTime, transformCache);
    }

    updateDebugDraw();

    if (m_running)
        emit simulateFrame(m_minTimestep, m_maxTimestep);
    emit frameDone(deltaTime * 1000);
}

QPhysicsWorld *QPhysicsWorld::getWorld(QQuick3DNode *node)
{
    for (QPhysicsWorld *world : worldManager.worlds) {
        if (!world->m_scene) {
            continue;
        }

        QQuick3DNode *nodeCurr = node;

        // Maybe pointless but check starting node
        if (nodeCurr == world->m_scene)
            return world;

        while (nodeCurr->parentNode()) {
            nodeCurr = nodeCurr->parentNode();
            if (nodeCurr == world->m_scene)
                return world;
        }
    }

    return nullptr;
}

void QPhysicsWorld::matchOrphanNodes()
{
    // FIXME: does this need thread safety?
    if (worldManager.orphanNodes.isEmpty())
        return;

    qsizetype numNodes = worldManager.orphanNodes.length();
    qsizetype idx = 0;

    while (idx < numNodes) {
        auto node = worldManager.orphanNodes[idx];
        auto world = getWorld(node);
        if (world == this) {
            world->m_newPhysicsNodes.push_back(node);
            // swap-erase
            worldManager.orphanNodes.swapItemsAt(idx, numNodes - 1);
            worldManager.orphanNodes.pop_back();
            numNodes--;
        } else {
            idx++;
        }
    }
}

void QPhysicsWorld::findPhysicsNodes()
{
    // This method finds the physics nodes inside the scene pointed to by the
    // scene property. This method is necessary to run whenever the scene
    // property is changed.
    if (m_scene == nullptr)
        return;

    // Recursively go through all children and add all QAbstractPhysicsNode's
    QList<QQuick3DObject *> children = m_scene->childItems();
    while (!children.empty()) {
        auto child = children.takeFirst();
        if (auto converted = qobject_cast<QAbstractPhysicsNode *>(child); converted != nullptr) {
            // This should never happen but check anyway.
            if (converted->m_backendObject != nullptr) {
                qWarning() << "Warning: physics node already associated with a backend node.";
                continue;
            }

            m_newPhysicsNodes.push_back(converted);
            worldManager.orphanNodes.removeAll(converted); // No longer orphan
        }
        children.append(child->childItems());
    }
}

physx::PxPhysics *QPhysicsWorld::getPhysics()
{
    return s_physx.physics;
}

physx::PxCooking *QPhysicsWorld::getCooking()
{
    return s_physx.cooking;
}

physx::PxControllerManager *QPhysicsWorld::controllerManager()
{
    if (m_physx->scene && !m_physx->controllerManager) {
        m_physx->controllerManager = PxCreateControllerManager(*m_physx->scene);
        qCDebug(lcQuick3dPhysics) << "Created controller manager" << m_physx->controllerManager;
    }
    return m_physx->controllerManager;
}

QQuick3DNode *QPhysicsWorld::scene() const
{
    return m_scene;
}

void QPhysicsWorld::setScene(QQuick3DNode *newScene)
{
    if (m_scene == newScene)
        return;

    m_scene = newScene;

    // Delete all nodes since they are associated with the previous scene
    for (auto body : m_physXBodies) {
        deregisterNode(body->frontendNode);
    }

    // Check if scene is already used by another world
    bool sceneOK = true;
    for (QPhysicsWorld *world : worldManager.worlds) {
        if (world != this && world->scene() == newScene) {
            sceneOK = false;
            qWarning() << "Warning: scene already associated with physics world";
        }
    }

    if (sceneOK)
        findPhysicsNodes();
    emit sceneChanged();
}

QT_END_NAMESPACE

#include "qphysicsworld.moc"
