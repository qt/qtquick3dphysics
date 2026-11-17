// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qphysxgravityfield_p.h"

#include "physxnode/qphysxgravity_p.h"
#include "qgravityfield_p.h"
#include "qphysicsutils_p.h"
#include "qphysicsworld_p.h"

#include "PxRigidActor.h"

#include <utility>

QT_BEGIN_NAMESPACE

QPhysXGravityField::QPhysXGravityField(QGravityField *frontEnd) : QPhysXActorBody(frontEnd) { }

void QPhysXGravityField::init(QPhysicsWorld *world, QPhysXWorld *physX)
{
    QPhysXActorBody::init(world, physX);
    // The world walks its fields, rather than every body to find them, so
    // that a scene without fields pays nothing for them.
    world->registerGravityField(this);
}

DebugDrawBodyType QPhysXGravityField::getDebugDrawBodyType()
{
    return DebugDrawBodyType::Trigger;
}

static bool operator!=(const QFilterData &a, const QFilterData &b)
{
    return a.group != b.group || a.ignoreGroups != b.ignoreGroups;
}

std::optional<QPhysXGravityField::SceneGravity>
QPhysXGravityField::applyGravity(QList<QFilterData> &staleFilters)
{
    auto *field = static_cast<QGravityField *>(frontendNode);

    const bool sceneWide = field->isSceneWide();
    const QFilterData filterData = field->filterData();
    bool wakeAll = std::exchange(field->m_pendingWakeAll, false);

    // A field with shapes needs no extra handling when its shapes or filter
    // change: PhysX refilters the pairs and reports the bodies entering and
    // leaving, and the field wakes them in response (bodyDidEnter() and
    // bodyDidExit()). A field without shapes has no pairs, so what it stopped
    // acting on is woken by the world, and what it now acts on by applying it.
    if (m_applied && m_sceneWide && (!sceneWide || filterData != m_filterData)) {
        staleFilters.append(m_filterData);
        wakeAll = true;
    }
    if (m_applied && sceneWide && !m_sceneWide)
        wakeAll = true;
    m_applied = true;
    m_sceneWide = sceneWide;
    m_filterData = filterData;

    // Queued from the trigger callback, where waking is not allowed.
    const auto pendingWakes = std::exchange(field->m_pendingWakes, {});
    for (const QPointer<QAbstractPhysicsNode> &node : pendingWakes) {
        if (node)
            QPhysXGravity::wake(node, backendOf(node));
    }

    // Centred on the pose the actor had in the last step, which for a field
    // with shapes is the one that reported what is inside them, and which is
    // also always finite.
    QPhysicsGravity gravity = field->gravityState();
    gravity.center = QPhysicsUtils::toQtType(actor->getGlobalPose().p);

    if (sceneWide) {
        SceneGravity scene;
        scene.gravity = gravity;
        scene.filterData = filterData;
        scene.wake = wakeAll;
        return scene;
    }

    const auto &tracked = field->collisions();
    for (auto it = tracked.cbegin(), end = tracked.cend(); it != end; ++it) {
        if (!it->reports)
            continue;
        QAbstractPhysicsNode *node = it.key();
        QPhysXGravity::apply(gravity, QPhysicsGravity::targetOf(node), node, backendOf(node),
                             wakeAll);
    }
    return std::nullopt;
}

void QPhysXGravityField::fieldDestroyed(QGravityField *field)
{
    auto *backend = static_cast<QPhysXGravityField *>(backendOf(field));
    if (!backend)
        return;

    backend->wakesOnRemoval = std::exchange(field->m_pendingWakes, {});
    backend->wakesOnRemoval.append(field->trackedBodies());
    if (backend->m_applied && backend->m_sceneWide)
        backend->staleFilterOnRemoval = backend->m_filterData;
}

void QPhysXGravityField::sync(float /*deltaTime*/,
                              QHash<QQuick3DNode *, QMatrix4x4> & /*transformCache*/)
{
    // Not chained to QPhysXActorBody::sync(): like a trigger body, a field has
    // no physicsMaterial.
    auto *field = static_cast<QGravityField *>(frontendNode);
    const physx::PxTransform pose =
            QPhysicsUtils::toPhysXTransform(field->scenePosition(), field->sceneRotation());
    if (!pose.isSane()) {
        qWarning() << "GravityField: position/rotation is not finite, keeping previous pose.";
        return;
    }

    // Only when it has moved, as for QPhysXTriggerBody, so that bodies inside
    // a field standing still can sleep.
    const physx::PxTransform previous = actor->getGlobalPose();
    if (QPhysicsUtils::fuzzyEquals(pose, previous))
        return;
    actor->setGlobalPose(pose);

    // In Point mode the position is the centre of the gravity, so moving it
    // wakes what the field acts on. Turning it changes nothing, so the
    // positions are compared on their own: a field parented to a spinning node
    // would otherwise keep everything it acts on awake.
    if (field->gravityState().readsCenter()
        && !qFuzzyCompare(QPhysicsUtils::toQtType(pose.p), QPhysicsUtils::toQtType(previous.p))) {
        field->m_pendingWakeAll = true;
    }
}

QT_END_NAMESPACE
