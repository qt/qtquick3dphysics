// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qrevolutejoint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxRevoluteJoint.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype RevoluteJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \inherits FlexibleJoint
    \brief A revolute joint.

    A revolute joint, commonly referred to as a a hinge keeps the origins and x-axes
    of the frames together, and allows free rotation around this common axis.

    \sa {DistanceJoint}
    \sa {FixedJoint}
    \sa {PrismaticJoint}
    \sa {SphericalJoint}
    \sa {D6Joint}
*/

/*!
    \qmlproperty real RevoluteJoint::angularLimitLower
    \since 6.12
    \default -pi/2

    The lower angular limit (in radians) of the joint constraint.

    Range: \c{[-2*pi, 2*pi]}

    \sa angularLimitUpper
*/

/*!
    \qmlproperty real RevoluteJoint::angularLimitUpper
    \since 6.12
    \default pi/2

    The Upper angular limit (in radians) of the joint constraint.

    Range: \c{[-2*pi, 2*pi]}

    \sa angularLimitLower
*/

/*!
    \qmlproperty bool RevoluteJoint::enableAngularLimit
    \since 6.12
    \default false

    Enable the angular limit constraint for the joint.
*/

float QRevoluteJoint::angularLimitLower() const
{
    return m_angularLimitLower;
}

void QRevoluteJoint::setAngularLimitLower(float newAngularLimitLower)
{
    newAngularLimitLower = qBound(-2.0f * physx::PxPi, newAngularLimitLower, 2.0f * physx::PxPi);
    if (qFuzzyCompare(m_angularLimitLower, newAngularLimitLower))
        return;
    m_angularLimitLower = newAngularLimitLower;
    m_dirtyProperties = true;
    emit angularLimitLowerChanged();
}

float QRevoluteJoint::angularLimitUpper() const
{
    return m_angularLimitUpper;
}

void QRevoluteJoint::setAngularLimitUpper(float newAngularLimitUpper)
{
    newAngularLimitUpper = qBound(-2.0f * physx::PxPi, newAngularLimitUpper, 2.0f * physx::PxPi);
    if (qFuzzyCompare(m_angularLimitUpper, newAngularLimitUpper))
        return;
    m_angularLimitUpper = newAngularLimitUpper;
    m_dirtyProperties = true;
    emit angularLimitUpperChanged();
}

bool QRevoluteJoint::enableAngularLimit() const
{
    return m_enableAngularLimit;
}

void QRevoluteJoint::setEnableAngularLimit(bool newEnableAngularLimit)
{
    if (m_enableAngularLimit == newEnableAngularLimit)
        return;
    m_enableAngularLimit = newEnableAngularLimit;
    m_dirtyProperties = true;
    emit enableAngularLimitChanged();
}

physx::PxJoint *QRevoluteJoint::createPhysxJoint(physx::PxRigidActor *actorA,
                                                 physx::PxRigidActor *actorB,
                                                 const physx::PxTransform &trfA,
                                                 const physx::PxTransform &trfB)
{
    return physx::PxRevoluteJointCreate(*StaticPhysXObjects::getReference().physics, actorA, trfA,
                                        actorB, trfB);
}

void QRevoluteJoint::setJointProperties()
{
    physx::PxRevoluteJoint *joint = static_cast<physx::PxRevoluteJoint *>(m_joint);
    const float lower = qMin(m_angularLimitLower, m_angularLimitUpper);
    const float upper = qMax(m_angularLimitLower, m_angularLimitUpper);

    physx::PxJointAngularLimitPair limit(lower, upper);
    limit.stiffness = m_stiffness;
    limit.damping = m_damping;

    joint->setLimit(limit);
    joint->setRevoluteJointFlag(physx::PxRevoluteJointFlag::eLIMIT_ENABLED, m_enableAngularLimit);
}

QT_END_NAMESPACE
