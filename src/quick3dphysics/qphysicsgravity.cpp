// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qphysicsgravity_p.h"

#include "qcharactercontroller_p.h"
#include "qdynamicrigidbody_p.h"

#include <QtCore/qdebug.h>

QT_BEGIN_NAMESPACE

QPhysicsGravity::Target QPhysicsGravity::targetOf(const QAbstractPhysicsNode *node)
{
    // By type and not by state: a body that is kinematic, out of the
    // simulation or asleep can stop being so at any time, so those are
    // skipped when the gravity is applied instead.
    if (qobject_cast<const QDynamicRigidBody *>(node))
        return Target::DynamicBody;
    if (qobject_cast<const QCharacterController *>(node))
        return Target::Character;
    return Target::None;
}

bool QPhysicsGravity::setDirection(const QVector3D &newDirection, const char *owner)
{
    // It is used normalized, and QVector3D::normalized() gives a null vector
    // for anything shorter than about 1e-6.
    if (!qIsFinite(newDirection.x()) || !qIsFinite(newDirection.y())
        || !qIsFinite(newDirection.z()) || newDirection.normalized().isNull()) {
        qWarning().nospace() << owner
                             << ": direction must be finite and non-zero, ignoring "
                             << newDirection;
        return false;
    }

    if (qFuzzyCompare(direction, newDirection))
        return false;
    direction = newDirection;
    return true;
}

bool QPhysicsGravity::setGravity(float newGravity, const char *owner)
{
    if (!qIsFinite(newGravity)) {
        qWarning().nospace() << owner << ": gravity must be finite, ignoring " << newGravity;
        return false;
    }

    if (qFuzzyCompare(gravity, newGravity))
        return false;
    gravity = newGravity;
    return true;
}

bool QPhysicsGravity::setUnitDistance(float newUnitDistance, const char *owner)
{
    if (!qIsFinite(newUnitDistance) || newUnitDistance < 0.0f) {
        qWarning().nospace() << owner
                             << ": unitDistance must be finite and non-negative, ignoring "
                             << newUnitDistance;
        return false;
    }

    if (qFuzzyCompare(unitDistance, newUnitDistance))
        return false;
    unitDistance = newUnitDistance;
    return true;
}

QT_END_NAMESPACE
