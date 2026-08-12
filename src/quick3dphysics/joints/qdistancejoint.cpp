// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qdistancejoint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxDistanceJoint.h>

#include <foundation/PxSimpleTypes.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype DistanceJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \inherits FlexibleJoint
    \brief A distance joint.

    A distance joint that will keep the origins of the joint within the
    distance range specified by \l{DistanceJoint::}{minDistance} and
    \l{DistanceJoint::}{maxDistance}.

    \sa {FixedJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
    \sa {D6Joint}
*/

/*!
    \qmlproperty real DistanceJoint::minDistance
    \since 6.12
    \default 0.0

    The minimum distance of the joint constraint. The constraint is only
    enforced when this value is greater than \c 0.0.

    Range: \c{[0, inf]}

    \sa maxDistance
*/

/*!
    \qmlproperty real DistanceJoint::maxDistance
    \since 6.12
    \default 0.0

    The maximum distance of the joint constraint. The constraint is only
    enforced when this value is greater than \c 0.0.

    Range: \c{[0, inf]}

    \sa minDistance
*/

float QDistanceJoint::minDistance() const
{
    return m_minDistance;
}

void QDistanceJoint::setMinDistance(float newMinDistance)
{
    newMinDistance = qBound(0.0f, newMinDistance, PX_MAX_F32);
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
    newMaxDistance = qBound(0.0f, newMaxDistance, PX_MAX_F32);
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

    float minDistance = m_minDistance;
    float maxDistance = m_maxDistance;

    // PhysX doesn't enforce minDistance <= maxDistance itself, but violating
    // it produces a constraint that can never be satisfied. Only reorder when
    // both limits are actually active - a value left at the 0 "disabled"
    // default must never be treated as "smaller than" an actively-configured
    // limit on the other side.
    if (m_minDistance > 0 && m_maxDistance > 0) {
        minDistance = qMin(m_minDistance, m_maxDistance);
        maxDistance = qMax(m_minDistance, m_maxDistance);
    }

    joint->setMinDistance(minDistance);
    joint->setMaxDistance(maxDistance);
    joint->setDistanceJointFlag(physx::PxDistanceJointFlag::eMIN_DISTANCE_ENABLED, minDistance > 0);
    joint->setDistanceJointFlag(physx::PxDistanceJointFlag::eMAX_DISTANCE_ENABLED, maxDistance > 0);

    joint->setStiffness(m_stiffness);
    joint->setDamping(m_damping);

    const bool enableSpring = (m_stiffness > 0.0f) || (m_damping > 0.0f);
    joint->setDistanceJointFlag(physx::PxDistanceJointFlag::eSPRING_ENABLED, enableSpring);
}

QT_END_NAMESPACE
