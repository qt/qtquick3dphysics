// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef CHARACTERCONTROLLER_H
#define CHARACTERCONTROLLER_H

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
#include <QtQuick3DPhysics/private/qabstractphysicsbody_p.h>
#include <QtQml/QQmlEngine>
#include <QVector3D>

QT_BEGIN_NAMESPACE

class QPhysXCharacterController;

class Q_QUICK3DPHYSICS_EXPORT QCharacterController : public QAbstractPhysicsBody
{
    Q_OBJECT
    Q_PROPERTY(QVector3D movement READ movement WRITE setMovement NOTIFY movementChanged)
    Q_PROPERTY(QVector3D gravity READ gravity WRITE setGravity NOTIFY gravityChanged)
    Q_PROPERTY(bool midAirControl READ midAirControl WRITE setMidAirControl NOTIFY
                       midAirControlChanged)
    Q_PROPERTY(Collisions collisions READ collisions NOTIFY collisionsChanged)
    Q_PROPERTY(bool enableShapeHitCallback READ enableShapeHitCallback WRITE
                       setEnableShapeHitCallback NOTIFY enableShapeHitCallbackChanged)
    Q_PROPERTY(float maximumStepHeight READ maximumStepHeight WRITE setMaximumStepHeight NOTIFY
                       maximumStepHeightChanged REVISION(6, 13))
    Q_PROPERTY(float slopeLimit READ slopeLimit WRITE setSlopeLimit NOTIFY
                       slopeLimitChanged REVISION(6, 13))
    Q_PROPERTY(bool sliding READ isSliding NOTIFY slidingChanged REVISION(6, 13))
    Q_PROPERTY(bool slideOnSteepSlopes READ slideOnSteepSlopes WRITE setSlideOnSteepSlopes NOTIFY
                       slideOnSteepSlopesChanged REVISION(6, 13))
    Q_PROPERTY(MovementMode movementMode READ movementMode WRITE setMovementMode NOTIFY
                       movementModeChanged REVISION(6, 13))
    Q_PROPERTY(QQuaternion gravityOrientation READ gravityOrientation NOTIFY gravityOrientationChanged
               REVISION(6, 13))

    QML_NAMED_ELEMENT(CharacterController)
public:
    QCharacterController();

    enum class MovementMode {
        ForwardBased,
        Free
    };

    Q_ENUM(MovementMode)

    enum class Collision {
        None = 0,
        Side = 1 << 0,
        Up = 1 << 1,
        Down = 1 << 2,
    };
    Q_DECLARE_FLAGS(Collisions, Collision)
    Q_FLAG(Collisions)

    const QVector3D &movement() const;
    void setMovement(const QVector3D &newMovement);
    const QVector3D &gravity() const;
    void setGravity(const QVector3D &newGravity);
    QVector3D getDisplacement(float deltaTime);
    bool getTeleport(QVector3D &position);

    bool midAirControl() const;
    void setMidAirControl(bool newMidAirControl);

    Q_INVOKABLE void teleport(const QVector3D &position);

    const Collisions &collisions() const;
    void setCollisions(const Collisions &newCollisions);
    QAbstractPhysXNode *createPhysXBackend() final;

    Q_REVISION(6, 6) bool enableShapeHitCallback() const;
    Q_REVISION(6, 6) void setEnableShapeHitCallback(bool newEnableShapeHitCallback);

    // What GravityFields contribute this frame, on top of
    // the gravity property. Cleared at the end of every sync().
    void addEnvironmentGravity(const QVector3D &gravity);
    void clearEnvironmentGravity();
    QVector3D effectiveGravity() const;
    Q_REVISION(6, 13) float maximumStepHeight() const;
    Q_REVISION(6, 13) void setMaximumStepHeight(float newMaximumStepHeight);

    Q_REVISION(6, 13) float slopeLimit() const;
    Q_REVISION(6, 13) void setSlopeLimit(float newSlopeLimit);

    Q_REVISION(6, 13) bool slideOnSteepSlopes() const;
    Q_REVISION(6, 13) void setSlideOnSteepSlopes(bool newSlideOnSteepSlopes);

    Q_REVISION(6, 13) MovementMode movementMode() const;
    Q_REVISION(6, 13) void setMovementMode(MovementMode newMovementMode);

    Q_REVISION(6, 13) QQuaternion gravityOrientation() const;

    Q_REVISION(6, 13) bool isSliding() const;

signals:
    void movementChanged();
    void gravityChanged();

    void midAirControlChanged();

    void collisionsChanged();
    void enableShapeHitCallbackChanged();
    void shapeHit(QAbstractPhysicsNode *body, const QVector3D &position, const QVector3D &impulse,
                  const QVector3D &normal);

    Q_REVISION(6, 13) void slidingChanged();

    Q_REVISION(6, 13) void maximumStepHeightChanged();
    Q_REVISION(6, 13) void slopeLimitChanged();

    Q_REVISION(6, 13) void slideOnSteepSlopesChanged();

    Q_REVISION(6, 13) void landed(float speed);

    Q_REVISION(6, 13) void movementModeChanged();

    Q_REVISION(6, 13) void gravityOrientationChanged();

private:
    friend class QPhysXCharacterController;

    Q_REVISION(6, 13) void setGravityOrientation(const QQuaternion &newRotation);
    Q_REVISION(6, 13) void setSliding(bool sliding);

    QVector3D m_movement;
    QVector3D m_gravity;
    QVector3D m_environmentGravity; // what the fields contributed this frame
    bool m_midAirControl = true;

    QVector3D m_freeFallVelocity; // actual speed at start of next tick, if free fall

    QVector3D m_teleportPosition;
    bool m_teleport = false;
    Collisions m_collisions;

    bool m_enableShapeHitCallback = false;
    bool m_sliding = false;
    float m_maximumStepHeight = -1.f;
    float m_slopeLimit = 45.f;

    bool m_lastGrounded = false;
    QVector3D m_jumpVelocity; // launch velocity: what was applied on the last grounded frame
    bool m_slideOnSteepSlopes = false;
    MovementMode m_movementMode = MovementMode::ForwardBased;
    QQuaternion m_gravityOrientation;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(QCharacterController::Collisions)

QT_END_NAMESPACE

#endif // CHARACTERCONTROLLER_H
