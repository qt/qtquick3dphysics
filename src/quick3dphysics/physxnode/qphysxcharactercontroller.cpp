// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qphysxcharactercontroller_p.h"

#include "PxRigidDynamic.h"
#include "PxShape.h"
#include "characterkinematic/PxController.h"
#include "characterkinematic/PxControllerManager.h"
#include "characterkinematic/PxCapsuleController.h"

#include "qcapsuleshape_p.h"
#include "qfilterdata_p.h"
#include "qphysicsutils_p.h"
#include "qphysicsworld_p.h"
#include "qcharactercontroller_p.h"

#define PHYSX_RELEASE(x)                                                                           \
    if (x != nullptr) {                                                                            \
        x->release();                                                                              \
        x = nullptr;                                                                               \
    }

QT_BEGIN_NAMESPACE

class ControllerCallback : public physx::PxUserControllerHitReport
{
public:
    ControllerCallback(QPhysicsWorld *worldIn) : world(worldIn) { }

    void onShapeHit(const physx::PxControllerShapeHit &hit) override
    {
        QAbstractPhysicsNode *other = static_cast<QAbstractPhysicsNode *>(hit.actor->userData);
        QCharacterController *trigger =
                static_cast<QCharacterController *>(hit.controller->getUserData());

        if (!trigger || !other)
            return;

        // Before either is read: one PxController::move() reports every shape
        // it hits, and the handler for the first is free to delete a node the
        // second one points at.
        if (world->isNodeRemoved(other) || world->isNodeRemoved(trigger))
            return;

        if (!trigger->enableShapeHitCallback())
            return;

        QVector3D position = QPhysicsUtils::toQtType(physx::toVec3(hit.worldPos));
        QVector3D impulse = QPhysicsUtils::toQtType(hit.dir * hit.length);
        QVector3D normal = QPhysicsUtils::toQtType(hit.worldNormal);

        emit trigger->shapeHit(other, position, impulse, normal);
    }
    void onControllerHit(const physx::PxControllersHit & /*hit*/) override { }
    void onObstacleHit(const physx::PxControllerObstacleHit & /*hit*/) override { }

private:
    QPhysicsWorld *world = nullptr;
};

// The one shape a controller's actor is created with, its capsule.
static physx::PxShape *shapeOf(const physx::PxController &controller)
{
    physx::PxShape *shape = nullptr;
    auto *actor = controller.getActor();
    if (actor && actor->getShapes(&shape, 1) == 1)
        return shape;
    return nullptr;
}

// Decides what a controller's move() is stopped by. Two bodies are kept apart
// or not by the simulation filter shader in QPhysXWorld, which reads their
// groups off the simulation filter data of their shapes. A controller does not
// move through the simulation but through scene queries of its own, which
// never reach that shader, so the same question is asked here of every shape
// it sweeps against and of every other controller it meets, off the same data.
class ControllerFilter : public physx::PxQueryFilterCallback,
                         public physx::PxControllerFilterCallback
{
public:
    physx::PxQueryHitType::Enum preFilter(const physx::PxFilterData & /*queryData*/,
                                          const physx::PxShape *shape,
                                          const physx::PxRigidActor * /*actor*/,
                                          physx::PxHitFlags & /*queryFlags*/) override
    {
        const QFilterData other = QPhysicsUtils::toQtType(shape->getSimulationFilterData());
        return QPhysicsUtils::isFilteredOut(self, other) ? physx::PxQueryHitType::eNONE
                                                         : physx::PxQueryHitType::eBLOCK;
    }

    // Never called: the controller is given no ePOSTFILTER flag.
    physx::PxQueryHitType::Enum postFilter(const physx::PxFilterData & /*queryData*/,
                                           const physx::PxQueryHit & /*hit*/,
                                           const physx::PxShape * /*shape*/,
                                           const physx::PxRigidActor * /*actor*/) override
    {
        return physx::PxQueryHitType::eBLOCK;
    }

    bool filter(const physx::PxController &a, const physx::PxController &b) override
    {
        const auto dataOf = [](const physx::PxController &controller) {
            auto *shape = shapeOf(controller);
            return shape ? QPhysicsUtils::toQtType(shape->getSimulationFilterData())
                         : QFilterData();
        };
        return !QPhysicsUtils::isFilteredOut(dataOf(a), dataOf(b));
    }

    // This controller's own groups, kept in step with its shape by
    // QPhysXCharacterController::applyFilterData().
    QFilterData self;
};

QPhysXCharacterController::QPhysXCharacterController(QCharacterController *frontEnd)
    : QAbstractPhysXNode(frontEnd)
{
}

void QPhysXCharacterController::cleanup(QPhysXWorld *physX)
{
    PHYSX_RELEASE(controller);
    delete reportCallback;
    reportCallback = nullptr;
    delete filter;
    filter = nullptr;
    QAbstractPhysXNode::cleanup(physX);
}

void QPhysXCharacterController::init(QPhysicsWorld *world, QPhysXWorld * /*physX*/)
{
    Q_ASSERT(!controller);

    auto *characterController = static_cast<QCharacterController *>(frontendNode);

    auto shapes = characterController->getCollisionShapesList();
    if (shapes.length() != 1) {
        qWarning() << "CharacterController: invalid collision shapes list.";
        return;
    }
    auto *capsule = qobject_cast<QCapsuleShape *>(shapes.first());
    if (!capsule) {
        qWarning() << "CharacterController: collision shape is not a capsule.";
        return;
    }
    auto *mgr = world->controllerManager();
    if (!mgr) {
        qWarning() << "QtQuick3DPhysics internal error: missing controller manager.";
        return;
    }

    updateMaterial();

    const QVector3D scale = characterController->sceneScale();
    const qreal heightScale = scale.y();
    const qreal radiusScale = scale.x();
    physx::PxCapsuleControllerDesc desc;
    reportCallback = new ControllerCallback(world);
    desc.reportCallback = reportCallback;
    filter = new ControllerFilter;
    desc.radius = 0.5f * radiusScale * capsule->diameter();
    desc.height = heightScale * capsule->height();
    desc.stepOffset = 0.25f * desc.height; // TODO: API

    desc.material = material;
    const QVector3D pos = characterController->scenePosition();
    desc.position = { pos.x(), pos.y(), pos.z() };
    // Safe to static_cast since createController will always return a PxCapsuleController
    // if desc is of type PxCapsuleControllerDesc
    controller = static_cast<physx::PxCapsuleController *>(mgr->createController(desc));

    if (!controller) {
        qWarning() << "QtQuick3DPhysics internal error: could not create controller.";
        return;
    }

    controller->setUserData(static_cast<void *>(frontendNode));

    auto *actor = controller->getActor();
    if (actor)
        actor->userData = characterController;
    else
        qWarning() << "QtQuick3DPhysics internal error: CharacterController created without actor.";

    applyFilterData();

    // No collision shape in the userData here, unlike the shapes a body builds,
    // which is how a trigger tells one body's pairs apart. A controller has
    // exactly one shape, checked above, so its pairs are one per trigger shape
    // either way, and pointing at the capsule would go stale: the controller's
    // shape is never rebuilt, so swapping the capsule would re-report nothing.
}

void QPhysXCharacterController::sync(float deltaTime,
                                     QHash<QQuick3DNode *, QMatrix4x4> & /*transformCache*/)
{
    if (!frontendNode)
        return;

    auto *characterController = static_cast<QCharacterController *>(frontendNode);

    if (controller == nullptr) {
        // getDisplacement() is never reached to consume this frame's gravity, so
        // clear it here rather than let it pile up until the controller exists.
        characterController->clearEnvironmentGravity();
        return;
    }

    // Update capsule height, radius, stepOffset
    const auto &shapes = characterController->getCollisionShapesList();
    auto capsule = shapes.length() == 1 ? qobject_cast<QCapsuleShape *>(shapes.front()) : nullptr;

    if (shapes.length() != 1) {
        qWarning() << "CharacterController: invalid collision shapes list.";
    } else if (!capsule) {
        qWarning() << "CharacterController: collision shape is not a capsule.";
    } else {
        const QVector3D sceneScale = characterController->sceneScale();
        const qreal heightScale = sceneScale.y();
        const qreal radiusScale = sceneScale.x();

        // Update height
        const float heightNew = heightScale * capsule->height();
        // Update radius
        const float radiusNew = 0.5f * radiusScale * capsule->diameter();

        if (!qIsFinite(heightNew) || heightNew <= 0.f || !qIsFinite(radiusNew)
            || radiusNew <= 0.f) {
            qWarning() << "CharacterController: scaled capsule height/radius must be finite "
                          "and positive, ignoring.";
        } else {
            if (!qFuzzyCompare(controller->getHeight(), heightNew))
                controller->resize(heightNew);
            if (!qFuzzyCompare(controller->getRadius(), radiusNew))
                controller->setRadius(radiusNew);
        }
        // Update stepOffset
        const float stepOffsetNew = 0.25f * heightNew;
        if (!qFuzzyCompare(controller->getStepOffset(), stepOffsetNew))
            controller->setStepOffset(stepOffsetNew);
    }

    // update node from physX
    QVector3D position = QPhysicsUtils::toQtType(physx::toVec3(controller->getPosition()));
    const QQuick3DNode *parentNode = static_cast<QQuick3DNode *>(characterController->parentItem());
    if (!parentNode) {
        // then it is the same space
        characterController->setPosition(position);
    } else {
        characterController->setPosition(parentNode->mapPositionFromScene(position));
    }

    // setPosition() ran the controller's bindings, which can delete it.
    if (!frontendNode)
        return;

    QVector3D teleportPos;
    bool teleport = characterController->getTeleport(teleportPos);
    if (teleport) {
        controller->setPosition({ teleportPos.x(), teleportPos.y(), teleportPos.z() });
    } else if (deltaTime > 0) {
        const auto displacement =
                QPhysicsUtils::toPhysXType(characterController->getDisplacement(deltaTime));
        // No filter data on the query itself: PhysX's own query stage would
        // match it against query filter data the shapes were never given, and
        // let nothing through. The callback does the filtering instead.
        const physx::PxControllerFilters filters(nullptr, filter, filter);
        auto collisions = controller->move(displacement, displacement.magnitude() / 100,
                                           deltaTime, filters);
        // PxController::move() reports what it hits, and a handler for that
        // can delete the controller.
        if (!frontendNode)
            return;
        characterController->setCollisions(QCharacterController::Collisions(uint(collisions)));
    }

    // setCollisions() ran the controller's bindings, which can delete it.
    if (!frontendNode)
        return;

    // A teleport, or a frame with no time in it, never reaches getDisplacement()
    // to consume this frame's gravity, so clear it here.
    characterController->clearEnvironmentGravity();

    // Materials are shared between nodes, so a change of the material properties moves this
    // node to another material, which the shape of the controller then has to be pointed at.
    // The shape is created exclusive to the actor of the controller, so it stays writable.
    if (updateMaterial() && material) {
        if (auto *shape = shapeOf(*controller))
            shape->setMaterials(&material, 1);
    }
}

QPhysicsMaterial *QPhysXCharacterController::qtMaterial() const
{
    return static_cast<QCharacterController *>(frontendNode)->physicsMaterial();
}

bool QPhysXCharacterController::debugGeometryCapability()
{
    return true;
}

DebugDrawBodyType QPhysXCharacterController::getDebugDrawBodyType()
{
    return DebugDrawBodyType::Character;
}

void QPhysXCharacterController::updateFilters(QPhysXWorld * /*physX*/)
{
    if (!controller || !frontendNode || !filtersDirty())
        return;
    applyFilterData();
}

// Writes the frontend's groups to the controller's shape, which is where the
// simulation filter shader reads them for the bodies and triggers the
// controller's actor is paired with, and to the filter its own move() asks.
void QPhysXCharacterController::applyFilterData()
{
    auto *shape = shapeOf(*controller);
    if (!shape)
        return;
    const QFilterData data = frontendNode->filterData();
    shape->setSimulationFilterData(QPhysicsUtils::toPhysXType(data));
    filter->self = data;
    // PxController caches the shapes near it, based on the filter settings,
    // so we must invalidate that cache for the change to take effect.
    controller->invalidateCache();
    setFiltersDirty(false);
}

void QPhysXCharacterController::detachFrontend()
{
    if (controller) {
        controller->setUserData(nullptr);
        if (auto *actor = controller->getActor())
            actor->userData = nullptr;
    }

    QAbstractPhysXNode::detachFrontend();
}

QT_END_NAMESPACE
