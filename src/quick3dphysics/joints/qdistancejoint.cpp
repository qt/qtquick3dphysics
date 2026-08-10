// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qdistancejoint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxDistanceJoint.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype DistanceJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \brief A distance joint.

    A distance joint that will keep the origins of the joint within the
    distance range specified by \l{DistanceJoint::}{minDistance} and
    \l{DistanceJoint::}{maxDistance}.

    \sa {FixedJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
*/

/*!
    \qmlproperty real DistanceJoint::minDistance
    \since 6.12
    \default 0.0

    The minimum distance of the joint constraint. The constraint is only
    enforced when this value is greater than \c 0.0.
*/

/*!
    \qmlproperty real DistanceJoint::maxDistance
    \since 6.12
    \default 0.0

    The maximum distance of the joint constraint. The constraint is only
    enforced when this value is greater than \c 0.0.
*/

float QDistanceJoint::minDistance() const
{
    return m_minDistance;
}

void QDistanceJoint::setMinDistance(float newMinDistance)
{
    if (qFuzzyCompare(m_minDistance, newMinDistance))
        return;
    m_minDistance = newMinDistance;
    m_dirtyProperties = true;
    emit minDistanceChanged();
}

float QDistanceJoint::maxDistance() const
{
    return m_maxDistance;
}

void QDistanceJoint::setMaxDistance(float newMaxDistance)
{
    if (qFuzzyCompare(m_maxDistance, newMaxDistance))
        return;
    m_maxDistance = newMaxDistance;
    m_dirtyProperties = true;
    emit maxDistanceChanged();
}

physx::PxJoint *QDistanceJoint::createPhysxJoint(physx::PxRigidActor *actorA,
                                                 physx::PxRigidActor *actorB,
                                                 const physx::PxTransform &trfA,
                                                 const physx::PxTransform &trfB)
{
    return physx::PxDistanceJointCreate(*StaticPhysXObjects::getReference().physics, actorA, trfA,
                                        actorB, trfB);
}

void QDistanceJoint::setJointProperties()
{
    physx::PxDistanceJoint *joint = static_cast<physx::PxDistanceJoint *>(m_joint);
    joint->setMinDistance(m_minDistance);
    joint->setMaxDistance(m_maxDistance);

    joint->setDistanceJointFlag(physx::PxDistanceJointFlag::eMIN_DISTANCE_ENABLED,
                                m_minDistance > 0);
    joint->setDistanceJointFlag(physx::PxDistanceJointFlag::eMAX_DISTANCE_ENABLED,
                                m_maxDistance > 0);
}

QT_END_NAMESPACE
