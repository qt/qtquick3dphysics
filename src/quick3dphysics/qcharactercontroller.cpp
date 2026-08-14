// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qcharactercontroller_p.h"
#include "qphysicsutils_p.h"

#include "physxnode/qphysxcharactercontroller_p.h"

#include <QtCore/QPointer>

QT_BEGIN_NAMESPACE

/*!
    \qmltype CharacterController
    \inqmlmodule QtQuick3D.Physics
    \inherits PhysicsBody
    \since 6.4
    \brief Controls the motion of a character.

    The CharacterController type controls the motion of a character.

    A character is an entity that moves under external control, but is still constrained
    by physical barriers and (optionally) subject to gravity.  This is in contrast to
    \l{DynamicRigidBody}{dynamic rigid bodies} which are either completely controlled by
    the physics simulation (for non-kinematic bodies); or move exactly where placed,
    regardless of barriers (for kinematic objects).

    To control the motion of a character controller, set \l movement to the desired velocity.

    For a first-person view, the camera is typically placed inside a character controller.

    \note \l {PhysicsNode::collisionShapes}{collisionShapes} must be set to
    a single \l {CapsuleShape}. No other shapes are supported.

    \sa {Qt Quick 3D Physics Shapes, Bodies and Joints}
*/

/*!
    \qmlproperty vector3d CharacterController::movement

    This property defines the controlled motion of the character. This is the velocity the character
    would move in the absence of gravity and without interacting with other physics objects.

    This property does not reflect the actual velocity of the character. If the character is stuck
    against terrain, the character can move slower than the speed defined by \c movement. Conversely, if the
    character is in free fall, it may move much faster.

    Default value: \c{(0, 0, 0)}
*/

/*!
    \qmlproperty vector3d CharacterController::gravity

    This property defines the gravitational acceleration that applies to the character.
    For a character that walks on the ground, it should typically be set to
    \l{PhysicsWorld::gravity}{PhysicsWorld.gravity}. A floating character that has movement
    controls in three dimensions will normally have gravity \c{(0, 0, 0)}.

    A \l GravityField adds its own gravity to this one: one without collision
    shapes wherever the character is, and one with collision shapes for as
    long as the character is inside them. A character that is to keep to its
    own gravity while everything else falls, for instance one swimming or
    climbing a ladder, is kept out of a field with
    \l{PhysicsNode::filterGroup}{filterGroup} and
    \l{PhysicsNode::filterIgnoreGroups}{filterIgnoreGroups}.

    Setting this property to zero stops the character falling at once, which is
    how a character grabs a ladder or enters water. Leaving a field's shapes
    does not: the character keeps the speed it built up under the field's
    gravity, with
    \l movement applying as usual, until it lands on something.

    \note The character's up direction, used for \l collisions, slopes, steps and
    \l gravityOrientation, is opposite to this gravity plus the gravity of any
    \l GravityField acting on it.

    Default value: \c{(0, 0, 0)}.
*/

/*!
    \qmlproperty bool CharacterController::midAirControl

    This property defines whether the \l movement property has effect when the character is in free
    fall. The character is in free fall while its own \l gravity or a \l GravityField is pulling
    on it, or while it is still moving at the speed it built up under a field whose shapes it has
    left. A value of \c true means that the character will change direction in
    mid-air when \c movement changes. A value of \c false means that the character will continue
    on its current trajectory until it hits another object.

    Default value: \c true
*/

/*!
    \qmlproperty Collisions CharacterController::collisions
    \readonly

    This property holds the current collision state of the character. It is either \c None for no
    collision, or an OR combination of \c Side, \c Up, and \c Down:

     \value   CharacterController.None
         The character is not touching anything. If gravity is non-null, this means that the
         character is in free fall.
     \value   CharacterController.Side
         The character is touching something on its side.
     \value   CharacterController.Up
         The character is touching something above it.
     \value   CharacterController.Down
         The character is touching something below it. In standard gravity, this means
         that the character is on the ground.

    The directions are relative to the character's up direction, which is opposite
    to its gravity: \l gravity plus the gravity of any \l GravityField acting on it.
    If that gravity is zero, the last up direction is kept.
*/

/*!
    \qmlproperty bool CharacterController::enableShapeHitCallback
    \since 6.6

    This property enables/disables the \l {CharacterController::shapeHit} callback for this
    character controller.

    Default value: \c{false}
*/

/*!
    \qmlmethod void CharacterController::teleport(vector3d position)
    Immediately move the character to \a position without checking for collisions.
    The caller is responsible for avoiding overlap with static objects.
*/

/*!
    \qmlsignal CharacterController::shapeHit(PhysicsNode *body, vector3D position, vector3D impulse,
    vector3D normal)
    \since 6.6

    This signal is emitted when \l {CharacterController::}{movement} has been
    called and it would result
    in a collision with a \l {DynamicRigidBody} or a \l {StaticRigidBody} and
    \l {CharacterController::} {enableShapeHitCallback} is set to \c true.
    The parameters \a body, \a position, \a impulse and \a normal contain the body, position,
    impulse force and normal for the contact point.
*/

/*!
    \qmlproperty real CharacterController::maximumStepHeight
    \since 6.13

    This property defines the maximum height step that the character controller can automatically
    climb over when moving on a surface.

    A value of \c 0 disables stepping. A negative value, which is the default,
    makes the controller pick a step height from the size of its capsule.

    The step height picked for a negative value is currently a quarter of
    the capsule's height, but this may change in future versions. To keep a
    fixed relation to the capsule, bind the property to it instead:

    \qml
    CharacterController {
        maximumStepHeight: capsule.height * 0.25
        collisionShapes: CapsuleShape { id: capsule }
    }
    \endqml

    \default -1

    \note When using a \l CapsuleShape, the rounded bottom of the capsule interacts with sharp step
    edges as if they were inclined surfaces. As a result, the controller may scale steps higher
    than the defined \c maximumStepHeight if the step height is smaller than the bottom sphere radius of
    the capsule and the surface angle does not exceed \l slopeLimit.

    \sa slopeLimit
*/

/*!
    \qmlproperty real CharacterController::slopeLimit
    \since 6.13

    This property defines the steepest slope, as an angle in degrees, that the
    character controller can climb. The angle is measured from the plane
    perpendicular to the character's up direction, so \c 0 only allows
    flat ground and \c 90 allows any slope.

    Range: \c{[0.0, 90.0]}

    \default 45

    \note The slope limit only applies to slopes on static bodies, such as a
    \l StaticRigidBody, and not to \l SphereShape or \l CapsuleShape shapes. On a
    dynamic or kinematic body, or on a sphere or capsule, it has no effect, and
    neither has \l slideOnSteepSlopes.

    \sa maximumStepHeight
    \sa slideOnSteepSlopes
    \sa sliding
*/

/*!
    \qmlproperty bool CharacterController::sliding
    \since 6.13

    This read-only property is \c true while the character is on a slope steeper
    than \l slopeLimit and \l slideOnSteepSlopes is \c true, so that the character
    slides down instead of following its movement. It is always \c false when
    \l slideOnSteepSlopes is \c false.

    Use it to tell the character's animations and input handling that the
    movement is being limited by the surface.

    \sa slopeLimit
    \sa slideOnSteepSlopes
*/

/*!
    \qmlproperty bool CharacterController::slideOnSteepSlopes
    \since 6.13

    This property defines whether the character slides down slopes steeper than
    \l slopeLimit. The character can never climb such a slope; with this
    property \c false, it stays where it is on one, and with \c true, it slides
    down, and \l sliding is \c true while it does.

    \default false

    \sa slopeLimit
    \sa sliding
*/

/*!
    \qmlproperty enumeration CharacterController::movementMode
    \since 6.13

    This property defines how the character controller uses the movement vector.

    \value CharacterController.ForwardBased
        The character moves relative to its own orientation. Gravity is applied if defined, and
        \l landed is emitted.
    \value CharacterController.Free
        The character uses the movement vector as a global movement vector in the scene. In this mode,
        gravity, midAirControl, and landed are ignored, though gravity is still used to determine the up
        direction of the node.

    \default CharacterController.ForwardBased

    \sa gravity
    \sa movement
    \sa midAirControl
    \sa landed
*/

/*!
    \qmlsignal CharacterController::landed(real speed)
    \since 6.13

    This signal is emitted when the character lands after being in the air.
    The \a speed parameter is how fast, in scene units per second, the character
    was falling at the moment of impact. It is always positive.

    \note This signal is not emitted when \l movementMode is
    \c CharacterController.Free. It doesn't need \l enableShapeHitCallback.
*/

/*!
    \qmlproperty quaternion CharacterController::gravityOrientation
    \since 6.13

    This property holds the rotation that turns the scene's up axis, positive y, into
    the character's current up direction, which is opposite to its gravity. Use it
    when the direction of gravity changes, such as on a planet, to keep the
    character upright on the surface.

    The rotation follows changes in the direction of gravity a small step at a time,
    rather than being calculated from a fixed reference direction. This keeps it free
    of sudden spins anywhere on a sphere, including at its poles. As a result, the
    rotation depends on the path the character took, not only on where it is.

    If the gravity is zero, the rotation keeps its last value.

    Combine it with the player's look direction to rotate the character:

    \qml
    CharacterController {
        id: playerController
        property real playerYaw: 0

        rotation: playerController.gravityOrientation
                  .times(Quaternion.fromEulerAngles(0, playerYaw, 0))
    }
    \endqml

    \sa gravity
*/

QCharacterController::QCharacterController() = default;

const QVector3D &QCharacterController::movement() const
{
    return m_movement;
}

void QCharacterController::setMovement(const QVector3D &newMovement)
{
    if (!QPhysicsUtils::isFinite(newMovement)) {
        qWarning() << "CharacterController: movement must be finite, ignoring" << newMovement;
        return;
    }

    if (m_movement == newMovement)
        return;
    m_movement = newMovement;
    emit movementChanged();
}

const QVector3D &QCharacterController::gravity() const
{
    return m_gravity;
}

void QCharacterController::setGravity(const QVector3D &newGravity)
{
    if (!QPhysicsUtils::isFinite(newGravity)) {
        qWarning() << "CharacterController: gravity must be finite, ignoring" << newGravity;
        return;
    }

    if (m_gravity == newGravity)
        return;
    m_gravity = newGravity;
    // Zero is how an application stops the character falling, for a ladder or
    // water, so drop the speed it built up. Leaving a GravityField is not,
    // and getDisplacement() lets the character coast on after that.
    if (newGravity.isNull())
        m_freeFallVelocity = QVector3D(0.0f, 0.0f, 0.0f);
    emit gravityChanged();
}

void QCharacterController::addEnvironmentGravity(const QVector3D &gravity)
{
    m_environmentGravity += gravity;
}

void QCharacterController::clearEnvironmentGravity()
{
    m_environmentGravity = QVector3D(0.0f, 0.0f, 0.0f);
}

QVector3D QCharacterController::effectiveGravity() const
{
    return m_gravity + m_environmentGravity;
}

// Calculates character displacement based on movement input and gravity field
QVector3D QCharacterController::getDisplacement(float deltaTime)
{
    if (deltaTime <= 0.0f) {
        return QVector3D(0.0f, 0.0f, 0.0f);
    }

    // In Free mode, use the movement vector directly as provided.
    // Custom movement mechanics and physics are managed externally by the user.
    if (m_movementMode == MovementMode::Free) {
        return m_movement * deltaTime;
    }

    // Transform local movement velocity relative to the character's orientation in the scene
    const QVector3D moveVelocity = sceneRotation() * m_movement;
    QVector3D displacement = moveVelocity * deltaTime;

    // This frame's gravity, including what GravityFields contribute
    const QVector3D g = effectiveGravity();
    if (g.isNull() && m_freeFallVelocity.isNull()) {
        return displacement;
    }

    const bool hasGravity = !g.isNull();
    const QVector3D gravityDir = hasGravity ? g.normalized() : QVector3D(0.0f, 0.0f, 0.0f);

    // Grounded check: verifies if the character is currently touching the surface below
    const bool grounded = (m_collisions & Collision::Down);

    // Detect state transitions (leaving ground vs landing)
    const bool landing = (!m_lastGrounded && grounded);

    m_lastGrounded = grounded;

    // Upon landing, report the speed along the direction of gravity at the
    // moment of impact. Lateral motion comes from movement input, or from
    // the launch velocity when mid-air control is off.
    if (landing) {
        const QVector3D impactVelocity = m_freeFallVelocity + (m_midAirControl ? moveVelocity : m_jumpVelocity);
        // Without gravity, a character coasting on the speed it built up under a
        // GravityField lands along the way it was falling.
        const QVector3D fallDir = hasGravity ? gravityDir : m_freeFallVelocity.normalized();
        const float impactSpeed = QVector3D::dotProduct(impactVelocity, fallDir);
        if (impactSpeed > 0.0f) {
            const QPointer<QCharacterController> self(this);
            emit landed(impactSpeed);
            // A handler for landed can delete the controller.
            if (!self)
                return QVector3D(0.0f, 0.0f, 0.0f);
        }
    }

    const QVector3D gravityStepDisp = 0.5f * g * deltaTime * deltaTime;

    if (grounded) {
        // Contact consumes any free-fall velocity built up in the air, and the
        // surface velocity is recorded so a take-off can lock onto it.
        m_freeFallVelocity = QVector3D(0.0f, 0.0f, 0.0f);
        m_jumpVelocity = moveVelocity;

        const bool jump = QVector3D::dotProduct(gravityStepDisp + displacement, gravityDir) < 0.0f
                && !landing;

        if (m_sliding) {
            // Slide down a slope too steep to stand on at a constant speed: the
            // speed a free fall reaches after slideTime seconds. A jump has to
            // be faster than that to leave the slope.
            // TODO: Compute the slide speed from the slope angle and the material friction.
            constexpr float slideTime = 0.7f;
            return displacement + g * slideTime * deltaTime;
        }

        if (!jump) {
            // Keep ground contact on steps and slopes with one frame's worth of
            // gravity, as when the character starts to fall, so that walking off
            // a ledge doesn't drop it further than falling would.
            return displacement + gravityStepDisp;
        }
    }

    // If mid-air control is disabled, lock motion strictly to the launch velocity
    if (!m_midAirControl) {
        displacement = m_jumpVelocity * deltaTime;
    }

    // Accumulate gravity over time and apply free-fall velocity to total displacement
    displacement += m_freeFallVelocity * deltaTime;
    m_freeFallVelocity += g * deltaTime;

    const bool hitCeiling = (m_collisions & Collision::Up);
    if (!m_midAirControl && hitCeiling && hasGravity) {
        // Remove only the velocity component of m_jumpVelocity pointing opposite to gravity
        const QVector3D upDir = -gravityDir;
        const float upSpeed = QVector3D::dotProduct(m_jumpVelocity, upDir);
        if (upSpeed > 0.0f) {
            m_jumpVelocity -= upDir * upSpeed;
        }
    }

    return displacement;
}

bool QCharacterController::midAirControl() const
{
    return m_midAirControl;
}

void QCharacterController::setMidAirControl(bool newMidAirControl)
{
    if (m_midAirControl == newMidAirControl)
        return;
    m_midAirControl = newMidAirControl;
    emit midAirControlChanged();
}

void QCharacterController::teleport(const QVector3D &position)
{
    if (!QPhysicsUtils::isFinite(position)) {
        qWarning() << "CharacterController: teleport() position must be finite, ignoring"
                   << position;
        return;
    }

    m_teleport = true;
    m_teleportPosition = position;
    m_freeFallVelocity = {};
}

bool QCharacterController::getTeleport(QVector3D &position)
{
    if (m_teleport) {
        position = m_teleportPosition;
        m_teleport = false;
        return true;
    }
    return false;
}

const QCharacterController::Collisions &QCharacterController::collisions() const
{
    return m_collisions;
}

void QCharacterController::setCollisions(const Collisions &newCollisions)
{
    if (m_collisions == newCollisions)
        return;
    m_collisions = newCollisions;
    emit collisionsChanged();
}

bool QCharacterController::enableShapeHitCallback() const
{
    return m_enableShapeHitCallback;
}

QAbstractPhysXNode *QCharacterController::createPhysXBackend()
{
    return new QPhysXCharacterController(this);
}

void QCharacterController::setEnableShapeHitCallback(bool newEnableShapeHitCallback)
{
    if (m_enableShapeHitCallback == newEnableShapeHitCallback)
        return;
    m_enableShapeHitCallback = newEnableShapeHitCallback;
    emit enableShapeHitCallbackChanged();
}

float QCharacterController::maximumStepHeight() const
{
    return m_maximumStepHeight;
}

void QCharacterController::setMaximumStepHeight(float newMaximumStepHeight)
{
    if (!qIsFinite(newMaximumStepHeight)) {
        qWarning() << "CharacterController: maximumStepHeight must be finite, ignoring"
                   << newMaximumStepHeight;
        return;
    }

    if (newMaximumStepHeight < 0.f)
        newMaximumStepHeight = -1.f;

    if (qFuzzyCompare(m_maximumStepHeight, newMaximumStepHeight))
        return;

    m_maximumStepHeight = newMaximumStepHeight;
    emit maximumStepHeightChanged();
}

float QCharacterController::slopeLimit() const
{
    return m_slopeLimit;
}

void QCharacterController::setSlopeLimit(float newSlopeLimit)
{
    if (!qIsFinite(newSlopeLimit)) {
        qWarning() << "CharacterController: slopeLimit must be finite, ignoring"
                   << newSlopeLimit;
        return;
    }

    newSlopeLimit = qBound(0.f, newSlopeLimit, 90.f);

    if (qFuzzyCompare(m_slopeLimit, newSlopeLimit))
        return;
    m_slopeLimit = newSlopeLimit;
    emit slopeLimitChanged();
}

bool QCharacterController::slideOnSteepSlopes() const
{
    return m_slideOnSteepSlopes;
}

void QCharacterController::setSlideOnSteepSlopes(bool newSlideOnSteepSlopes)
{
    if (m_slideOnSteepSlopes == newSlideOnSteepSlopes)
        return;
    m_slideOnSteepSlopes = newSlideOnSteepSlopes;
    emit slideOnSteepSlopesChanged();
}

QCharacterController::MovementMode QCharacterController::movementMode() const
{
    return m_movementMode;
}

void QCharacterController::setMovementMode(MovementMode newMovementMode)
{
    if (m_movementMode == newMovementMode)
        return;
    m_movementMode = newMovementMode;
    emit movementModeChanged();
}

QQuaternion QCharacterController::gravityOrientation() const
{
    return m_gravityOrientation;
}

bool QCharacterController::isSliding() const
{
    return m_sliding;
}

void QCharacterController::setSliding(bool sliding)
{
    if (m_sliding == sliding)
        return;
    m_sliding = sliding;
    emit slidingChanged();
}

void QCharacterController::setGravityOrientation(const QQuaternion &newRotation)
{
    if (m_gravityOrientation != newRotation) {
        m_gravityOrientation = newRotation;
        emit gravityOrientationChanged();
    }
}

QT_END_NAMESPACE
