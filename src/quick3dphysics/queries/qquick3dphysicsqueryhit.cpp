// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qquick3dphysicsqueryhit_p.h"
#include <PxQueryReport.h>
#include <PxRigidActor.h>

QT_BEGIN_NAMESPACE

/*!
    \qmlvaluetype queryHit
    \inqmlmodule QtQuick3D.Physics
    \since 6.13
    \brief Represents the result of a spatial physics query hit (raycast, sweep, or overlap).

    The \c queryHit struct provides hit information returned by spatial
    queries in the physics world.

    \sa PhysicsNode, CollisionShape
*/

/*!
    \qmlproperty PhysicsNode queryHit::body
    \readonly
    \since 6.13

    Holds the physical body (\c PhysicsNode) intersected by the spatial query.
*/

/*!
    \qmlproperty CollisionShape queryHit::shape
    \readonly
    \since 6.13

    Holds the specific collision shape (\c CollisionShape) intersected by the spatial query.
    Returns \c null if the underlying PhysX shape has no associated Qt collision shape.

    \note When a query intersects a \l CharacterController, the \c body property
    is populated, but the \c shape property will be \c null because character
    controllers do not assign individual shape metadata.
*/

QQuick3DPhysicsQueryHit::QQuick3DPhysicsQueryHit() = default;

QQuick3DPhysicsQueryHit::QQuick3DPhysicsQueryHit(const physx::PxQueryHit &/*hit*/,
                                                 const physx::PxActorShape &actorShape)
    : m_body(actorShape.actor ? static_cast<QAbstractPhysicsNode *>(actorShape.actor->userData) : nullptr),
      m_shape(actorShape.shape ? static_cast<QAbstractCollisionShape *>(actorShape.shape->userData) : nullptr)
{
}

QAbstractPhysicsNode *QQuick3DPhysicsQueryHit::body() const
{
    return m_body;
}

QAbstractCollisionShape *QQuick3DPhysicsQueryHit::shape() const
{
    return m_shape;
}

QT_END_NAMESPACE
