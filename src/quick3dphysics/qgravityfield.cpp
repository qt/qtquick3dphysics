// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qgravityfield_p.h"
#include "physxnode/qphysxgravityfield_p.h"

#include <utility>

QT_BEGIN_NAMESPACE

/*!
    \qmltype GravityField
    \inherits PhysicsNode
    \inqmlmodule QtQuick3D.Physics
    \since 6.13
    \brief A gravity of its own, for the whole scene or a region of it.

    A GravityField applies its own gravity to every \l DynamicRigidBody and
    \l CharacterController it acts on, on top of the gravity they already
    have: the \l{PhysicsWorld::gravity}{world's gravity} for a dynamic rigid
    body, and its own \l{CharacterController::gravity}{gravity} property for a
    character controller.

    A field with no \l{PhysicsNode::collisionShapes}{collisionShapes} acts on
    every body in the scene, wherever it is. A field with collision shapes
    acts only on the bodies that overlap them, and stops acting on a body when
    it leaves them. That is how you build a low gravity room, an updraft, a
    corridor where down is sideways, or the space around a planet.

    In the default \c Directional \l mode the gravity points the same way and
    has the same strength everywhere, as world gravity does; it is uniform
    rather than Newtonian. In \c Point mode it points at the field's own
    position, which is how you build a spherical or planetary world: bodies
    fall toward it from any direction, and with \l unitDistance set the gravity
    weakens with distance, as Newtonian gravity does.

    A negative \l gravity reverses either mode. A \c Point field with a
    negative gravity pushes bodies away from its position instead of pulling
    them in, which is how you build a repulsor.

    A body does \e not need
    \l{PhysicsNode::sendTriggerReports}{sendTriggerReports} set to be affected
    by a field with collision shapes, and the field does not report the bodies
    inside it either: it has no equivalent of TriggerBody's
    \l{TriggerBody::bodyEntered}{bodyEntered} and
    \l{TriggerBody::bodyExited}{bodyExited} signals or its
    \l{TriggerBody::collisionCount}{collisionCount} property, and a body's
    \l{PhysicsNode::enteredTriggerBody}{enteredTriggerBody} and
    \l{PhysicsNode::exitedTriggerBody}{exitedTriggerBody} signals are not
    emitted for it. To be notified of what enters the shapes, or to count what
    is inside them, place a \l TriggerBody with the same shapes alongside the
    field. The contact and trigger report properties of PhysicsNode have no
    effect on a GravityField.

    A field \e adds its gravity to what a body already has rather than
    replacing it, so fields compose with world gravity, with each other, and
    with a character controller's own gravity. A field never overwrites a
    value, or a binding, that you set yourself, and a field stopping to act on
    a body simply stops its contribution. A \l DynamicRigidBody with
    \l{DynamicRigidBody::gravityEnabled}{gravityEnabled} set to \c false is not
    affected by a field either.

    A CharacterController has no such switch. Setting its
    \l{CharacterController::gravity}{gravity} to zero only takes away its own
    gravity, not that of the fields acting on it, so a character that is to be
    free of gravity altogether, for instance while it swims or climbs a
    ladder, has to be kept out of the fields with the filter groups described
    below.

    A field respects \l{PhysicsNode::filterGroup}{filterGroup} and
    \l{PhysicsNode::filterIgnoreGroups}{filterIgnoreGroups}: a body in a group
    the field ignores, or one that ignores the field's group, is left alone.
    For a field without collision shapes this is how part of the scene is kept
    out of it, which world gravity cannot do.

    For example, the following weakens gravity inside a box by pushing back
    against it, so that bodies inside fall at a fifth of the usual rate:

    \qml
    GravityField {
        gravity: -785
        collisionShapes: BoxShape { extents: Qt.vector3d(400, 400, 400) }
    }
    \endqml

    and this defines a planet that bodies fall toward from any direction and
    any distance:

    \qml
    PhysicsWorld {
        // Required: world gravity would otherwise keep pulling everything
        // down on top of the planet's gravity.
        gravity: Qt.vector3d(0, 0, 0)
    }

    StaticRigidBody {
        id: planet
        collisionShapes: SphereShape { diameter: 280 }
    }

    GravityField {
        position: planet.position
        mode: GravityField.Point
        gravity: 981
        unitDistance: 140
    }
    \endqml

    Note that \l{PhysicsWorld::gravity}{PhysicsWorld.gravity} has to be set to
    a zero vector here. World gravity defaults to pulling everything down, and
    a field adds to it rather than replacing it, so without that the bodies
    would fall down past the planet instead of onto it.

    Fields add up, so two \c Point fields with \l unitDistance set give the
    combined gravity of a planet and its moon, weakening with distance from
    each.

    The two ways of finding bodies differ in what they cost. A field with
    collision shapes finds what is inside them the way a \l TriggerBody does,
    which costs the simulation one collision pair per body it overlaps,
    updated on every step for as long as that body is awake. That is cheap for
    shapes that cover part of a scene. A field without collision shapes goes
    through every body in the scene, one at a time, before every step, and is
    applied to the awake ones it acts on, which costs more in a scene with
    many bodies.

    This also decides what moving a field costs. Moving a field with shapes
    only involves the bodies inside them, however many bodies the scene has.
    A field that moves around should therefore be given shapes, sized to the
    area it should affect. A \c Point field without shapes wakes every body it
    acts on on each step it moves, so moving one keeps all of those bodies
    awake. Moving a \c Directional field without shapes changes nothing, since
    its gravity does not depend on where it is.

    A \c Directional field without shapes or filter groups does what world
    gravity does; prefer world gravity then, which is applied to all bodies at
    once as part of each simulation step, and so performs better, since you do
    not pay for filtering that you do not use. Keep in mind that world gravity
    does not act on a \l CharacterController, so a character then needs its
    own \l{CharacterController::gravity}{gravity} set.

    \note A \l CharacterController is pulled by a \c Point field like any other
    body, but it still stands and walks with respect to the world's up axis, so
    it cannot walk on the side of a planet built this way. It falls toward the
    field's position, and lands on, walks over, and steps up whatever is below
    it in world space.

    \note A body resting on a surface is still allowed to go to sleep, exactly
    as it would under world gravity. Bodies are woken when the field starts or
    stops acting on them, for instance as they enter or leave its shapes or as
    filter groups change, when its gravity changes, when a \c Point field
    moves, and when the field is destroyed, not continuously while the field
    acts on them.

    \sa TriggerBody, DynamicRigidBody, CharacterController
*/

/*!
    \qmlproperty enumeration GravityField::mode
    \since 6.13

    This property defines which way the field's gravity points.

    \value GravityField.Directional Along \l direction, the same everywhere.
            This is the default.
    \value GravityField.Point Toward the field's own position, so bodies fall
            in from any direction, or away from it with a negative \l gravity.
            \l unitDistance applies in this mode only.

    \default GravityField.Directional

    \sa direction, gravity
*/

/*!
    \qmlproperty vector3d GravityField::direction
    \since 6.13

    This property defines the direction the field's gravity points in, when
    \l mode is \c GravityField.Directional. It need not be normalized; only its
    direction is used, with \l gravity giving the magnitude. It is ignored in
    \c Point mode.

    It is in scene space, like \l{PhysicsWorld::gravity}{the world's own
    gravity}, so rotating the field turns its collision shapes without turning
    the gravity.

    \default Qt.vector3d(0, -1, 0)

    \sa mode, gravity
*/

/*!
    \qmlproperty real GravityField::gravity
    \since 6.13

    This property defines the gravitational acceleration applied to bodies,
    along \l direction in Directional mode or toward the field's position in
    Point mode. In Point mode with \l unitDistance set, it is the acceleration
    at that distance from the field's position, and weaker elsewhere. A
    negative value reverses it: against \l direction, or away from the field's
    position rather than toward it, which makes a Point field a repulsor.

    \default 981

    \sa unitDistance, PhysicsWorld::gravity
*/

/*!
    \qmlproperty real GravityField::unitDistance
    \since 6.13

    This property defines, in \c Point \l mode, the distance from the field's
    position at which the acceleration equals \l gravity. Beyond it the
    acceleration falls off with the inverse square of the distance, as
    Newtonian gravity does, so at twice the distance it is a quarter as strong.
    Inside it the acceleration falls off linearly toward the centre, as it
    would inside a solid sphere of uniform density, so at half the distance it
    is half as strong, and at the centre there is none. For example, for a
    planet with a radius of 100 and a surface gravity of 4, set \l gravity to
    \c 4 and \c unitDistance to \c 100.

    A value of \c 0 disables falloff, giving the same acceleration everywhere.
    A body exactly at the field's position then has no direction to fall in
    and is given no acceleration.

    It is ignored in \c Directional mode.

    Range: \c{[0, inf)}

    \default 0

    \sa mode, gravity
*/

static_assert(int(QGravityField::Mode::Directional) == int(QPhysicsGravity::Mode::Directional)
              && int(QGravityField::Mode::Point) == int(QPhysicsGravity::Mode::Point));

QGravityField::QGravityField() = default;

QGravityField::~QGravityField()
{
    // What the field acted on loses its gravity, so whatever is asleep under
    // it has to be woken to fall under what is left. The backend outlives the
    // field, and hands them to the world as it is deregistered.
    QPhysXGravityField::fieldDestroyed(this);
}

QGravityField::Mode QGravityField::mode() const
{
    return Mode(m_gravity.mode);
}

void QGravityField::setMode(Mode mode)
{
    if (this->mode() == mode)
        return;
    m_gravity.mode = QPhysicsGravity::Mode(mode);
    m_pendingWakeAll = true;
    emit modeChanged();
}

const QVector3D &QGravityField::direction() const
{
    return m_gravity.direction;
}

void QGravityField::setDirection(const QVector3D &direction)
{
    if (!m_gravity.setDirection(direction, "GravityField"))
        return;
    if (m_gravity.readsDirection())
        m_pendingWakeAll = true;
    emit directionChanged();
}

float QGravityField::gravity() const
{
    return m_gravity.gravity;
}

void QGravityField::setGravity(float gravity)
{
    if (!m_gravity.setGravity(gravity, "GravityField"))
        return;
    m_pendingWakeAll = true;
    emit gravityChanged();
}

float QGravityField::unitDistance() const
{
    return m_gravity.unitDistance;
}

void QGravityField::setUnitDistance(float unitDistance)
{
    if (!m_gravity.setUnitDistance(unitDistance, "GravityField"))
        return;
    if (m_gravity.readsUnitDistance())
        m_pendingWakeAll = true;
    emit unitDistanceChanged();
}

const QPhysicsGravity &QGravityField::gravityState() const
{
    return m_gravity;
}

bool QGravityField::isSceneWide() const
{
    return getCollisionShapesList().isEmpty();
}

bool QGravityField::countsBody(const QAbstractPhysicsNode *body) const
{
    // What the field can act on, whatever the body asked for with
    // sendTriggerReports.
    return QPhysicsGravity::targetOf(body) != QPhysicsGravity::Target::None;
}

void QGravityField::queueWake(QAbstractPhysicsNode *body)
{
    // Only a dynamic body has a sleep state.
    if (QPhysicsGravity::targetOf(body) == QPhysicsGravity::Target::DynamicBody
        && !m_pendingWakes.contains(body)) {
        m_pendingWakes.append(body);
    }
}

void QGravityField::bodyDidEnter(QAbstractPhysicsNode *body)
{
    queueWake(body);
}

void QGravityField::bodyDidExit(QAbstractPhysicsNode *body)
{
    // A sleeping body cannot leave by itself, but the field can move off it,
    // change shape, or have its pair with the body filtered out, and then the
    // body has to fall under whatever gravity is left.
    queueWake(body);
}

QList<QPointer<QAbstractPhysicsNode>> QGravityField::trackedBodies() const
{
    QList<QPointer<QAbstractPhysicsNode>> bodies;
    const auto &tracked = collisions();
    for (auto it = tracked.cbegin(), end = tracked.cend(); it != end; ++it) {
        if (it->reports)
            bodies.append(it.key());
    }
    return bodies;
}

QAbstractPhysXNode *QGravityField::createPhysXBackend()
{
    return new QPhysXGravityField(this);
}

QT_END_NAMESPACE
