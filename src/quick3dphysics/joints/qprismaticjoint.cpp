// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qprismaticjoint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxPrismaticJoint.h>

#include <PxPhysics.h>

#include <foundation/PxSimpleTypes.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype PrismaticJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \brief A prismatic joint.

    A prismatic joint permits relative translational movement between two bodies along an axis, but
    no relative rotational movement. the axis on each body is defined as the line containing the
    origin of the joint frame and extending along the x-axis of that frame

    \sa {DistanceJoint}
    \sa {FixedJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
*/

/*!
    \qmlproperty real PrismaticJoint::lowerLimit
    \since 6.12
    \default 0.0

    The lower limit of the constraint, i.e. how far along the negative x-axis the joint can extend.

    Range: \c{[-inf, inf]}

    \sa upperLimit
*/

/*!
    \qmlproperty real PrismaticJoint::upperLimit
    \since 6.12
    \default 0.0

    The upper limit of the constraint, i.e. how far along the positive x-axis the joint can extend.

    Range: \c{[-inf, inf]}

    \sa lowerLimit
*/

physx::PxJoint *QPrismaticJoint::createPhysxJoint(physx::PxRigidActor *actorA,
                                                  physx::PxRigidActor *actorB,
                                                  const physx::PxTransform &trfA,
                                                  const physx::PxTransform &trfB)
{
    return physx::PxPrismaticJointCreate(*StaticPhysXObjects::getReference().physics, actorA, trfA,
                                         actorB, trfB);
}

void QPrismaticJoint::setJointProperties()
{
    physx::PxPrismaticJoint *joint = static_cast<physx::PxPrismaticJoint *>(m_joint);
    const physx::PxTolerancesScale scale =
            StaticPhysXObjects::getReference().physics->getTolerancesScale();
    const float lowerLimit = qMin(m_lowerLimit, m_upperLimit);
    const float upperLimit = qMax(m_lowerLimit, m_upperLimit);
    joint->setLimit(physx::PxJointLinearLimitPair(scale, lowerLimit, upperLimit));
    joint->setPrismaticJointFlag(physx::PxPrismaticJointFlag::eLIMIT_ENABLED, true);
}

float QPrismaticJoint::lowerLimit() const
{
    return m_lowerLimit;
}

void QPrismaticJoint::setLowerLimit(float newLowerLimit)
{
    newLowerLimit = qBound(-PX_MAX_F32, newLowerLimit, PX_MAX_F32);
    if (qFuzzyCompare(m_lowerLimit, newLowerLimit))
        return;
    m_lowerLimit = newLowerLimit;
    m_dirtyProperties = true;
    emit lowerLimitChanged();
}

float QPrismaticJoint::upperLimit() const
{
    return m_upperLimit;
}

void QPrismaticJoint::setUpperLimit(float newUpperLimit)
{
    newUpperLimit = qBound(-PX_MAX_F32, newUpperLimit, PX_MAX_F32);
    if (qFuzzyCompare(m_upperLimit, newUpperLimit))
        return;
    m_upperLimit = newUpperLimit;
    m_dirtyProperties = true;
    emit upperLimitChanged();
}

QT_END_NAMESPACE
