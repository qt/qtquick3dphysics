// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qphysxgravity_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qcharactercontroller_p.h"
#include "qdynamicrigidbody_p.h"
#include "qphysicsutils_p.h"

#include "PxRigidDynamic.h"

QT_BEGIN_NAMESPACE

// The actor of a dynamic body that takes forces right now, or null.
static physx::PxRigidDynamic *simulatedActorOf(QAbstractPhysicsNode *node,
                                               QAbstractPhysXNode *backend)
{
    auto *body = qobject_cast<QDynamicRigidBody *>(node);
    if (!body || !backend)
        return nullptr;
    // eDISABLE_GRAVITY only takes the scene's gravity off the body, so a body
    // that turned gravity off has to be skipped here.
    if (!body->gravityEnabled())
        return nullptr;
    auto *actor = static_cast<QPhysXActorBody *>(backend)->actor;
    if (!actor)
        return nullptr;
    // Asked of the actor rather than the frontend: a body made dynamic, or put
    // back in the simulation, is only updated in its own sync(), and PhysX
    // rejects a force on an actor that is kinematic or not simulated.
    auto *dynamicActor = static_cast<physx::PxRigidDynamic *>(actor);
    if (dynamicActor->getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC)
        return nullptr;
    if (dynamicActor->getActorFlags() & physx::PxActorFlag::eDISABLE_SIMULATION)
        return nullptr;
    return dynamicActor;
}

void QPhysXGravity::apply(const QPhysicsGravity &gravity, QPhysicsGravity::Target target,
                          QAbstractPhysicsNode *node, QAbstractPhysXNode *backend, bool wake)
{
    if (!backend)
        return;

    switch (target) {
    case QPhysicsGravity::Target::None:
        return;
    case QPhysicsGravity::Target::Character: {
        // A controller is not moved by forces: it integrates its gravity
        // itself in getDisplacement(), during its sync() later this frame.
        auto *character = static_cast<QCharacterController *>(node);
        if (const auto accel = gravity.accelerationAt(character->scenePosition()))
            character->addEnvironmentGravity(*accel);
        return;
    }
    case QPhysicsGravity::Target::DynamicBody: {
        auto *actor = simulatedActorOf(node, backend);
        if (!actor)
            return;
        // A body at rest is allowed to sleep under a gravity, as under the
        // world's, and is only woken when the gravity changes or arrives.
        if (actor->isSleeping()) {
            if (!wake)
                return;
            actor->wakeUp();
        }
        // The simulated position, which the frontend only catches up with in
        // the body's own sync().
        const QVector3D position = QPhysicsUtils::toQtType(actor->getGlobalPose().p);
        if (const auto accel = gravity.accelerationAt(position))
            actor->addForce(QPhysicsUtils::toPhysXType(*accel), physx::PxForceMode::eACCELERATION,
                            false);
        return;
    }
    }
}

void QPhysXGravity::wake(QAbstractPhysicsNode *node, QAbstractPhysXNode *backend)
{
    if (auto *actor = simulatedActorOf(node, backend))
        actor->wakeUp();
}

QT_END_NAMESPACE
