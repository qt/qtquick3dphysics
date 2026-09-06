// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qquick3dphysicslocationhit_p.h"
#include <PxQueryReport.h>

QT_BEGIN_NAMESPACE

/*!
    \qmlvaluetype locationHit
    \inqmlmodule QtQuick3D.Physics
    \since 6.13
    \inherits queryHit
    \brief Holds positional and normal information for a physics query hit.

    \c locationHit extends \l queryHit to provide detailed spatial
    data about an intersection, such as the exact hit point, surface normal, and distance.

    This object is usually returned as a result of raycast or sweep queries in the physics scene.
*/

/*!
    \qmlproperty vector3d locationHit::position
    \readonly
    \since 6.13

    This property holds the world position of the intersection point.
*/

/*!
    \qmlproperty vector3d locationHit::normal
    \readonly
    \since 6.13

    This property holds the surface normal vector at the point of impact in world coordinates.
*/

/*!
    \qmlproperty real locationHit::distance
    \readonly
    \since 6.13

    This property holds the distance from the query ray/sweep origin to the intersection point.

    \note For sweep queries this is negative when the swept shape already overlapped the hit
    body at its starting position, and its magnitude is the penetration depth.
*/

QQuick3DPhysicsLocationHit::QQuick3DPhysicsLocationHit() = default;

QQuick3DPhysicsLocationHit::QQuick3DPhysicsLocationHit(const physx::PxLocationHit &hit,
                                                       const physx::PxActorShape &actorShape)
    : QQuick3DPhysicsQueryHit(hit, actorShape), m_distance(hit.distance)
{
    if (hit.flags & physx::PxHitFlag::ePOSITION)
        m_position = QVector3D(hit.position.x, hit.position.y, hit.position.z);

    if (hit.flags & physx::PxHitFlag::eNORMAL)
        m_normal = QVector3D(hit.normal.x, hit.normal.y, hit.normal.z);
}

QVector3D QQuick3DPhysicsLocationHit::position() const
{
    return m_position;
}

QVector3D QQuick3DPhysicsLocationHit::normal() const
{
    return m_normal;
}

float QQuick3DPhysicsLocationHit::distance() const
{
    return m_distance;
}

QT_END_NAMESPACE
