// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qraycaster_p.h"

#include "qabstractphysicsnode_p.h"
#include "qphysicsutils_p.h"
#include "qphysicsworld_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmltype Raycaster
    \inherits Node
    \inqmlmodule QtQuick3D.Physics
    \since 6.13
    \brief Casts a ray into the physics scene on every physics frame.

    Raycaster casts a ray from its scene position in \l direction and reports the closest physics
    body it intersects. The \l hit property is updated once per physics frame, after the bodies
    have been synchronized with the scene and before \l PhysicsWorld::frameDone, so a frameDone
    handler reads the result of the frame it is reporting on.

    \qml
    Raycaster {
        direction: Qt.vector3d(0, -1, 0)
        maxDistance: 50
        includeDynamic: false
        onBodyEntered: (body) => console.log("Hit", body)
    }
    \endqml

    The ray is a scene query, so it sees the same bodies as
    \l {PhysicsWorld::singleRaycastQuery} {PhysicsWorld.singleRaycastQuery} and is bound by the
    same rules: \l {PhysicsNode::filterGroup} {filterGroup} and
    \l {PhysicsNode::filterIgnoreGroups} {filterIgnoreGroups} have no effect on it, and a
    \l TriggerBody never appears in the result. Use \l includeStatic and \l includeDynamic to
    narrow that by kind, and \l excludeParentBody and \l excludedBodies to leave out particular
    bodies. Those two matter more here than for a query method, since the ray reports only its
    closest hit and there is nothing left to filter afterwards.

    \sa PhysicsWorld, locationHit, {Qt Quick 3D Physics Scene Queries},
        {Qt Quick 3D Physics - Raycaster Example}
*/

/*!
    \qmlproperty bool Raycaster::enabled

    Controls whether the ray is cast on each physics frame. Disabling the ray clears \l hit and
    sets \l isColliding to false.

    The default value is \c true.
*/

/*!
    \qmlproperty vector3d Raycaster::direction

    The ray direction in local coordinates. It is transformed to scene coordinates and normalized
    before the ray is cast. A zero vector produces no hit. Non-finite values are ignored.

    The default value is \c{Qt.vector3d(0, 0, -1)}.
*/

/*!
    \qmlproperty real Raycaster::maxDistance

    The maximum distance of the ray in scene units. A value of zero produces no hit. Negative and
    non-finite values are ignored.

    The default value is \c 100.
*/

/*!
    \qmlproperty bool Raycaster::excludeParentBody

    When true, every \l PhysicsNode ancestor of the ray is excluded from the query, not only the
    nearest one. A ray mounted on a body starts inside that body's own shapes, and a raycast does
    report the shape it starts inside, so without this the ray reports the body carrying it at a
    distance of zero and never sees anything beyond.

    The default value is \c true.

    \sa excludedBodies
*/

/*!
    \qmlproperty list<PhysicsNode> Raycaster::excludedBodies

    Bodies the ray never reports, whether or not they are ancestors of it. Use this for a body the
    ray has to ignore but is not mounted on, such as the character carrying the weapon a ray is
    fired from, where the two are siblings rather than one inside the other.

    Because the ray reports only its closest hit, there is no way to filter its result afterwards
    the way the \l PhysicsWorld query methods allow, so anything that has to be left out has to be
    named here or covered by \l excludeParentBody.

    The list is empty by default. A body destroyed after it was added stops being excluded and
    reads back as \c null, rather than being removed from the list.

    \sa excludeParentBody
*/

/*!
    \qmlproperty bool Raycaster::includeStatic

    Whether static physics bodies are included in the query.

    The default value is \c true.
*/

/*!
    \qmlproperty bool Raycaster::includeDynamic

    Whether dynamic physics bodies are included in the query.

    The default value is \c true.

    When both \l includeStatic and includeDynamic are false, the ray produces no hit.
*/

/*!
    \qmlproperty bool Raycaster::isColliding
    \readonly

    Whether the ray currently intersects a physics body.
*/

/*!
    \qmlproperty locationHit Raycaster::hit
    \readonly

    The closest intersection reported by the ray. The value contains the intersected body and
    collision shape, along with the scene-space position and normal and the distance from the ray
    origin. It is a default-constructed \l locationHit when \l isColliding is false.
*/

/*!
    \qmlsignal Raycaster::bodyEntered(PhysicsNode body)

    Emitted when the ray starts intersecting \a body. When the intersected body changes,
    \l bodyExited is emitted for the old body before this signal is emitted for the new body.
*/

/*!
    \qmlsignal Raycaster::bodyExited(PhysicsNode body)

    Emitted when the ray stops intersecting \a body.
*/

QRaycaster::QRaycaster(QQuick3DNode *parent) : QQuick3DNode(parent)
{
    QPhysicsWorld::registerRaycaster(this);
}

QRaycaster::~QRaycaster()
{
    QPhysicsWorld::deregisterRaycaster(this);
}

bool QRaycaster::enabled() const
{
    return m_enabled;
}

void QRaycaster::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    if (!m_enabled)
        clearHit();
    emit enabledChanged();
}

QVector3D QRaycaster::direction() const
{
    return m_direction;
}

void QRaycaster::setDirection(const QVector3D &direction)
{
    if (m_direction == direction)
        return;
    if (!QPhysicsUtils::isFinite(direction)) {
        qWarning() << "Raycaster: direction must be finite, ignoring.";
        return;
    }
    m_direction = direction;
    if (m_direction.isNull())
        clearHit();
    emit directionChanged();
}

float QRaycaster::maxDistance() const
{
    return m_maxDistance;
}

void QRaycaster::setMaxDistance(float maxDistance)
{
    if (qFuzzyCompare(m_maxDistance, maxDistance))
        return;
    if (!qIsFinite(maxDistance) || maxDistance < 0.0f) {
        qWarning() << "Raycaster: maxDistance must be finite and non-negative, ignoring.";
        return;
    }
    m_maxDistance = maxDistance;
    if (m_maxDistance == 0.0f)
        clearHit();
    emit maxDistanceChanged();
}

bool QRaycaster::excludeParentBody() const
{
    return m_excludeParentBody;
}

void QRaycaster::setExcludeParentBody(bool excludeParentBody)
{
    if (m_excludeParentBody == excludeParentBody)
        return;
    m_excludeParentBody = excludeParentBody;
    emit excludeParentBodyChanged();
}

bool QRaycaster::includeStatic() const
{
    return m_includeStatic;
}

void QRaycaster::setIncludeStatic(bool includeStatic)
{
    if (m_includeStatic == includeStatic)
        return;
    m_includeStatic = includeStatic;
    if (!m_includeStatic && !m_includeDynamic)
        clearHit();
    emit includeStaticChanged();
}

bool QRaycaster::includeDynamic() const
{
    return m_includeDynamic;
}

void QRaycaster::setIncludeDynamic(bool includeDynamic)
{
    if (m_includeDynamic == includeDynamic)
        return;
    m_includeDynamic = includeDynamic;
    if (!m_includeStatic && !m_includeDynamic)
        clearHit();
    emit includeDynamicChanged();
}

bool QRaycaster::isColliding() const
{
    return m_isColliding;
}

QQuick3DPhysicsLocationHit QRaycaster::hit() const
{
    return m_hit;
}

QQmlListProperty<QAbstractPhysicsNode> QRaycaster::excludedBodies()
{
    return QQmlListProperty<QAbstractPhysicsNode>(
            this, nullptr, QRaycaster::qmlAppendExcludedBody, QRaycaster::qmlExcludedBodyCount,
            QRaycaster::qmlExcludedBodyAt, QRaycaster::qmlClearExcludedBodies);
}

void QRaycaster::qmlAppendExcludedBody(QQmlListProperty<QAbstractPhysicsNode> *list,
                                       QAbstractPhysicsNode *body)
{
    if (body)
        static_cast<QRaycaster *>(list->object)->m_excludedBodies.push_back(body);
}

QAbstractPhysicsNode *QRaycaster::qmlExcludedBodyAt(QQmlListProperty<QAbstractPhysicsNode> *list,
                                                    qsizetype index)
{
    auto *self = static_cast<QRaycaster *>(list->object);
    if (index < 0 || index >= self->m_excludedBodies.size())
        return nullptr;
    return self->m_excludedBodies.at(index).data();
}

qsizetype QRaycaster::qmlExcludedBodyCount(QQmlListProperty<QAbstractPhysicsNode> *list)
{
    return static_cast<QRaycaster *>(list->object)->m_excludedBodies.size();
}

void QRaycaster::qmlClearExcludedBodies(QQmlListProperty<QAbstractPhysicsNode> *list)
{
    static_cast<QRaycaster *>(list->object)->m_excludedBodies.clear();
}

// Four inline covers what scenes produce, one ancestor body being the usual answer.
void QRaycaster::gatherExcludedBodies(
        QVarLengthArray<const QAbstractPhysicsNode *, 4> &excluded) const
{
    if (m_excludeParentBody) {
        // Every body above the ray, not only the nearest. Bodies nest, and a ray inside the
        // inner one of a pair would otherwise report the outer one at distance 0.
        for (QQuick3DNode *node = parentNode(); node; node = node->parentNode()) {
            if (auto *body = qobject_cast<QAbstractPhysicsNode *>(node))
                excluded.append(body);
        }
    }

    if (m_excludedBodies.isEmpty())
        return;

    excluded.reserve(excluded.size() + m_excludedBodies.size());
    for (const QPointer<QAbstractPhysicsNode> &body : m_excludedBodies) {
        if (!body.isNull())
            excluded.append(body.data());
    }
}

void QRaycaster::updateRaycast(QPhysicsWorld *world)
{
    if (!m_enabled || m_maxDistance == 0.0f || (!m_includeStatic && !m_includeDynamic)) {
        clearHit();
        return;
    }

    // Null for a null direction, and also for a ray whose node is scaled to zero.
    const QVector3D direction = mapDirectionToScene(m_direction);
    if (direction.isNull()) {
        clearHit();
        return;
    }

    QVarLengthArray<const QAbstractPhysicsNode *, 4> excluded;
    gatherExcludedBodies(excluded);
    updateHit(world->closestRaycastHit(scenePosition(), direction, m_maxDistance, m_includeStatic,
                                       m_includeDynamic, excluded));
}

// Holds both bodies and this ray weakly, since the first of the reports below can leave the
// rest with a body or a ray that is gone: they run inside the frame, so a handler deletes on
// the spot rather than between frames. The same reason QTriggerBody::reportEntered does it.
void QRaycaster::updateHit(const QQuick3DPhysicsLocationHit &hit)
{
    const QPointer<QRaycaster> self(this);
    const QPointer<QAbstractPhysicsNode> previousBody(m_hit.body());
    const QPointer<QAbstractPhysicsNode> body(hit.body());
    const bool isColliding = !body.isNull();
    const bool hitHasChanged = m_hit.body() != body || m_hit.shape() != hit.shape()
            || m_hit.position() != hit.position() || m_hit.normal() != hit.normal()
            || !qFuzzyCompare(m_hit.distance(), hit.distance());
    const bool collisionChanged = m_isColliding != isColliding;

    m_hit = hit;
    m_isColliding = isColliding;

    if (hitHasChanged)
        emit hitChanged();
    if (collisionChanged && !self.isNull())
        emit isCollidingChanged();

    if (!self.isNull() && previousBody != body) {
        if (!previousBody.isNull())
            emit bodyExited(previousBody);
        if (!self.isNull() && !body.isNull())
            emit bodyEntered(body);
    }
}

void QRaycaster::clearHit()
{
    updateHit({});
}

QT_END_NAMESPACE
