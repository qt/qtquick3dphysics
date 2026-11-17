// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef PHYSICSGRAVITY_H
#define PHYSICSGRAVITY_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>
#include <QtCore/qnumeric.h>
#include <QtGui/qvector3d.h>

#include <optional>

QT_BEGIN_NAMESPACE

class QAbstractPhysicsNode;

// The gravity of a GravityField: the values an author sets and the
// acceleration they come to at a point. Kept apart from the field so that the
// backend and the world can carry it around and evaluate it without it.
struct Q_QUICK3DPHYSICS_EXPORT QPhysicsGravity
{
    // Same order as GravityField.Mode.
    enum class Mode { Directional, Point };

    // What a gravity can act on. A static body can never be moved by one, and
    // a trigger region has nothing to move.
    enum class Target { None, DynamicBody, Character };
    static Target targetOf(const QAbstractPhysicsNode *node);

    // Each validates the value, warning in the name of `owner` and keeping the
    // old value if it is unusable, and returns whether the value changed.
    bool setDirection(const QVector3D &direction, const char *owner);
    bool setGravity(float gravity, const char *owner);
    bool setUnitDistance(float unitDistance, const char *owner);

    // Whether the current mode reads a value, which is whether changing it is
    // a reason to wake the bodies asleep under the gravity.
    bool readsDirection() const { return mode == Mode::Directional; }
    bool readsUnitDistance() const { return mode == Mode::Point; }
    bool readsCenter() const { return mode == Mode::Point; }

    // The acceleration at `position`, or nothing when there is no direction to
    // aim at: a body (numerically) on the centre of a Point gravity without
    // falloff, or at a non-finite position.
    std::optional<QVector3D> accelerationAt(const QVector3D &position) const
    {
        if (mode == Mode::Directional)
            return direction.normalized() * gravity;

        const QVector3D toCenter = center - position;
        const float distance = toCenter.length();
        if (!qIsFinite(distance))
            return std::nullopt;

        if (unitDistance > 0.0f) {
            // As inside a solid sphere of uniform density: linear, down to
            // nothing at the centre, so that a body there is at rest rather
            // than pulled back and forth across it at full strength. Written
            // without dividing by the distance, so the centre itself needs no
            // special case.
            if (distance < unitDistance)
                return toCenter * (gravity / unitDistance);

            // Inverse square. Computed as a squared ratio, since squaring a
            // large unitDistance on its own overflows.
            const float ratio = unitDistance / distance;
            return (toCenter / distance) * (gravity * ratio * ratio);
        }

        // No falloff: full strength everywhere, so there is no direction to
        // aim at on the centre itself.
        if (qFuzzyIsNull(distance))
            return std::nullopt;
        return (toCenter / distance) * gravity;
    }

    Mode mode = Mode::Directional;
    QVector3D direction { 0.0f, -1.0f, 0.0f };
    // The magnitude of PhysicsWorld's default gravity.
    float gravity = 981.0f;
    float unitDistance = 0.0f;
    // What Point mode aims at.
    QVector3D center;
};

QT_END_NAMESPACE

#endif // PHYSICSGRAVITY_H
