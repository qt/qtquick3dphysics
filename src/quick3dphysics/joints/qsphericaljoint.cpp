// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qsphericaljoint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxSphericalJoint.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype SphericalJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \brief A spherical joint.

    A spherical joint, also known as a ball-and-socket joint, keeps the origins
    together, but allows the orientations to vary freely.

    \sa {DistanceJoint}
    \sa {FixedJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
*/

/*!
    \qmlproperty real SphericalJoint::coneLimitY
    \since 6.12
    \default 0.0

    The y limit (in radians) of the joint's cone constraint.
*/

/*!
    \qmlproperty real SphericalJoint::coneLimitZ
    \since 6.12
    \default 0.0

    The z limit (in radians) of the joint's cone constraint.
*/

/*!
    \qmlproperty bool SphericalJoint::enableConeLimit
    \since 6.12
    \default false

    Enable the cone limit constraint for the joint.
*/

float QSphericalJoint::coneLimitY() const
{
    return m_coneLimitY;
}

void QSphericalJoint::setConeLimitY(float newConeLimitY)
{
    if (qFuzzyCompare(m_coneLimitY, newConeLimitY))
        return;
    m_coneLimitY = newConeLimitY;
    m_dirtyProperties = true;
    emit coneLimitYChanged();
}

float QSphericalJoint::coneLimitZ() const
{
    return m_coneLimitZ;
}

void QSphericalJoint::setConeLimitZ(float newConeLimitZ)
{
    if (qFuzzyCompare(m_coneLimitZ, newConeLimitZ))
        return;
    m_coneLimitZ = newConeLimitZ;
    m_dirtyProperties = true;
    emit coneLimitZChanged();
}

bool QSphericalJoint::enableConeLimit() const
{
    return m_enableConeLimit;
}

void QSphericalJoint::setEnableConeLimit(bool newEnableConeLimit)
{
    if (m_enableConeLimit == newEnableConeLimit)
        return;
    m_enableConeLimit = newEnableConeLimit;
    m_dirtyProperties = true;
    emit enableConeLimitChanged();
}

physx::PxJoint *QSphericalJoint::createPhysxJoint(physx::PxRigidActor *actorA,
                                                  physx::PxRigidActor *actorB,
                                                  const physx::PxTransform &trfA,
                                                  const physx::PxTransform &trfB)
{
    return physx::PxSphericalJointCreate(*StaticPhysXObjects::getReference().physics, actorA, trfA,
                                         actorB, trfB);
}

void QSphericalJoint::setJointProperties()
{
    physx::PxSphericalJoint *joint = static_cast<physx::PxSphericalJoint *>(m_joint);
    joint->setLimitCone(physx::PxJointLimitCone(m_coneLimitY, m_coneLimitZ));
    joint->setSphericalJointFlag(physx::PxSphericalJointFlag::eLIMIT_ENABLED, m_enableConeLimit);
}

QT_END_NAMESPACE
