// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qd6joint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxD6Joint.h>
#include <PxPhysics.h>

QT_BEGIN_NAMESPACE


/*!
    \qmltype D6Joint
    \inqmlmodule QtQuick3D.Physics
    \since 6.13
    \brief A configurable joint with up to 6 degrees of freedom (3 linear, 3 angular).

    The D6Joint allows custom configuration for each axis of movement and rotation.
    Each degree of freedom can be set to \c Locked, \c Limited, or \c Free using the \l Motion enum.
    Soft limits with spring stiffness and damping can be configured for linear and angular constraints.

    \sa {DistanceJoint}
    \sa {FixedJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
*/

/*!
    \qmlproperty enumeration D6Joint::xMotion
    \since 6.13
    \default D6Joint.Locked

    Available options:

    \value D6Joint.Locked
    The degree of freedom is completely restricted and cannot move.
    \value D6Joint.Limited
    The degree of freedom is constrained within specified lower and upper limits.
    \value D6Joint.Free
    The degree of freedom is unconstrained and moves freely.

    This property holds the motion constraint along the X axis.
*/

/*!
    \qmlproperty enumeration D6Joint::yMotion
    \since 6.13
    \default D6Joint.Locked

    Available options:

    \value D6Joint.Locked
    The degree of freedom is completely restricted and cannot move.
    \value D6Joint.Limited
    The degree of freedom is constrained within specified lower and upper limits.
    \value D6Joint.Free
    The degree of freedom is unconstrained and moves freely.

    This property holds the motion constraint along the Y axis.
*/

/*!
    \qmlproperty enumeration D6Joint::zMotion
    \since 6.13
    \default D6Joint.Locked

    Available options:

    \value D6Joint.Locked
    The degree of freedom is completely restricted and cannot move.
    \value D6Joint.Limited
    The degree of freedom is constrained within specified lower and upper limits.
    \value D6Joint.Free
    The degree of freedom is unconstrained and moves freely.

    This property holds the motion constraint along the Z axis.
*/

/*!
    \qmlproperty enumeration D6Joint::twistMotion
    \since 6.13
    \default D6Joint.Locked

    Available options:

    \value D6Joint.Locked
    The degree of freedom is completely restricted and cannot move.
    \value D6Joint.Limited
    The degree of freedom is constrained within specified lower and upper limits.
    \value D6Joint.Free
    The degree of freedom is unconstrained and moves freely.

    This property holds the rotational constraint around the X axis (twist).
*/

/*!
    \qmlproperty enumeration D6Joint::swingMotionY
    \since 6.13
    \default D6Joint.Locked

    Available options:

    \value D6Joint.Locked
    The degree of freedom is completely restricted and cannot move.
    \value D6Joint.Limited
    The degree of freedom is constrained within specified lower and upper limits.
    \value D6Joint.Free
    The degree of freedom is unconstrained and moves freely.

    This property holds the rotational constraint around the Y axis (swing Y).
*/

/*!
    \qmlproperty enumeration D6Joint::swingMotionZ
    \since 6.13
    \default D6Joint.Locked

    Available options:

    \value D6Joint.Locked
    The degree of freedom is completely restricted and cannot move.
    \value D6Joint.Limited
    The degree of freedom is constrained within specified lower and upper limits.
    \value D6Joint.Free
    The degree of freedom is unconstrained and moves freely.

    This property holds the rotational constraint around the Z axis (swing Z).
*/

/*!
    \qmlproperty real D6Joint::linearLimitXLower
    \since 6.13
    \default -1.0

    This property holds the lower limit of movement along the X axis.
    The value must be less than or equal to \l linearLimitXUpper.

    Range: \c{(-\inf, \inf)}
*/

/*!
    \qmlproperty real D6Joint::linearLimitXUpper
    \since 6.13
    \default 1.0

    This property holds the upper limit of movement along the X axis.
    The value must be greater than or equal to \l linearLimitXLower.

    Range: \c{(-\inf, \inf)}
*/

/*!
    \qmlproperty real D6Joint::linearLimitYLower
    \since 6.13
    \default -1.0

    This property holds the lower limit of movement along the Y axis.
    The value must be less than or equal to \l linearLimitYUpper.

    Range: \c{(-\inf, \inf)}
*/

/*!
    \qmlproperty real D6Joint::linearLimitYUpper
    \since 6.13
    \default 1.0

    This property holds the upper limit of movement along the Y axis.
    The value must be greater than or equal to \l linearLimitYLower.

    Range: \c{(-\inf, \inf)}
*/

/*!
    \qmlproperty real D6Joint::linearLimitZLower
    \since 6.13
    \default -1.0

    This property holds the lower limit of movement along the Z axis.
    The value must be less than or equal to \l linearLimitZUpper.

    Range: \c{(-\inf, \inf)}
*/

/*!
    \qmlproperty real D6Joint::linearLimitZUpper
    \since 6.13
    \default 1.0

    This property holds the upper limit of movement along the Z axis.
    The value must be greater than or equal to \l linearLimitZLower.

    Range: \c{(-\inf, \inf)}
*/

/*!
    \qmlproperty real D6Joint::twistLimitLower
    \since 6.13
    \default -pi/4

    This property holds the lower angular limit (in radians) around the X axis.
    The value must be less than or equal to \l twistLimitUpper.

    Range: \c{(-2pi, 2pi)}
*/

/*!
    \qmlproperty real D6Joint::twistLimitUpper
    \since 6.13
    \default pi/4

    This property holds the upper angular limit (in radians) around the X axis.
    The value must be greater than or equal to \l twistLimitLower.

    Range: \c{(-2pi, 2pi)}
*/

/*!
    \qmlproperty real D6Joint::swingLimitAngleY
    \since 6.13
    \default pi/4

    This property holds the maximum swing angle limit (in radians) around the Y axis.

    Range: \c{(0, pi)}
*/

/*!
    \qmlproperty real D6Joint::swingLimitAngleZ
    \since 6.13
    \default pi/4

    This property holds the maximum swing angle limit (in radians) around the Z axis.

    Range: \c{(0, pi)}
*/

/*!
    \qmlproperty real D6Joint::linearStiffness
    \since 6.13
    \default 0.0

    This property holds the spring stiffness for linear motion constraints.
    When set to a value greater than 0, linear limits act as soft constraints (springs).

    Range: \c{[0, \inf)}
*/

/*!
    \qmlproperty real D6Joint::linearDamping
    \since 6.13
    \default 0.0

    This property holds the spring damping for linear motion constraints.

    Range: \c{[0, \inf)}
*/

/*!
    \qmlproperty real D6Joint::angularStiffness
    \since 6.13
    \default 0.0

    This property holds the spring stiffness for angular motion constraints.
    When set to a value greater than 0, angular limits act as soft constraints (springs).

    Range: \c{[0, \inf)}
*/

/*!
    \qmlproperty real D6Joint::angularDamping
    \since 6.13
    \default 0.0

    This property holds the spring damping for angular motion constraints.

    Range: \c{[0, \inf)}
*/

namespace  {
physx::PxD6Motion::Enum toPxEnum(QD6Joint::Motion val)
{
    switch (val) {
    case QD6Joint::Motion::Locked: return physx::PxD6Motion::eLOCKED;
    case QD6Joint::Motion::Limited: return physx::PxD6Motion::eLIMITED;
    case QD6Joint::Motion::Free: return physx::PxD6Motion::eFREE;
    }

    Q_UNREACHABLE_RETURN(physx::PxD6Motion::eLOCKED);
}
}

QD6Joint::QD6Joint() = default;

QD6Joint::Motion QD6Joint::xMotion() const
{
    return m_xMotion;
}

void QD6Joint::setXMotion(Motion motion)
{
    if (m_xMotion == motion)
        return;
    m_xMotion = motion;
    m_dirtyProperties = true;
    emit xMotionChanged();
}

QD6Joint::Motion QD6Joint::yMotion() const
{
    return m_yMotion;
}

void QD6Joint::setYMotion(Motion motion)
{
    if (m_yMotion == motion)
        return;
    m_yMotion = motion;
    m_dirtyProperties = true;
    emit yMotionChanged();
}

QD6Joint::Motion QD6Joint::zMotion() const
{
    return m_zMotion;
}

void QD6Joint::setZMotion(Motion motion)
{
    if (m_zMotion == motion)
        return;
    m_zMotion = motion;
    m_dirtyProperties = true;
    emit zMotionChanged();
}

QD6Joint::Motion QD6Joint::twistMotion() const
{
    return m_twistMotion;
}

void QD6Joint::setTwistMotion(Motion motion)
{
    if (m_twistMotion == motion)
        return;
    m_twistMotion = motion;
    m_dirtyProperties = true;
    emit twistMotionChanged();
}

float QD6Joint::linearLimitXLower() const
{
    return m_linearLimitXLower;
}

void QD6Joint::setLinearLimitXLower(float limit)
{
    if (qFuzzyCompare(m_linearLimitXLower, limit))
        return;
    m_linearLimitXLower = limit;
    m_dirtyProperties = true;
    emit linearLimitXLowerChanged();
}

float QD6Joint::linearLimitXUpper() const
{
    return m_linearLimitXUpper;
}

void QD6Joint::setLinearLimitXUpper(float limit)
{
    if (qFuzzyCompare(m_linearLimitXUpper, limit))
        return;
    m_linearLimitXUpper = limit;
    m_dirtyProperties = true;
    emit linearLimitXUpperChanged();
}

float QD6Joint::linearLimitYLower() const
{
    return m_linearLimitYLower;
}

void QD6Joint::setLinearLimitYLower(float limit)
{
    if (qFuzzyCompare(m_linearLimitYLower, limit))
        return;
    m_linearLimitYLower = limit;
    m_dirtyProperties = true;
    emit linearLimitYLowerChanged();
}

float QD6Joint::linearLimitYUpper() const
{
    return m_linearLimitYUpper;
}

void QD6Joint::setLinearLimitYUpper(float limit)
{
    if (qFuzzyCompare(m_linearLimitYUpper, limit))
        return;
    m_linearLimitYUpper = limit;
    m_dirtyProperties = true;
    emit linearLimitYUpperChanged();
}

float QD6Joint::linearLimitZLower() const
{
    return m_linearLimitZLower;
}

void QD6Joint::setLinearLimitZLower(float limit)
{
    if (qFuzzyCompare(m_linearLimitZLower, limit))
        return;
    m_linearLimitZLower = limit;
    m_dirtyProperties = true;
    emit linearLimitZLowerChanged();
}

float QD6Joint::linearLimitZUpper() const
{
    return m_linearLimitZUpper;
}

void QD6Joint::setLinearLimitZUpper(float limit)
{
    if (qFuzzyCompare(m_linearLimitZUpper, limit))
        return;
    m_linearLimitZUpper = limit;
    m_dirtyProperties = true;
    emit linearLimitZUpperChanged();
}

float QD6Joint::twistLimitLower() const
{
    return m_twistLimitLower;
}

void QD6Joint::setTwistLimitLower(float limit)
{
    // PhysX requires the twist limit to be strictly within (-2*Pi, 2*Pi)
    limit = qBound(-float(M_PI * 2) + 0.0001f, limit, float(M_PI * 2) - 0.0001f);

    if (qFuzzyCompare(m_twistLimitLower, limit))
        return;
    m_twistLimitLower = limit;
    m_dirtyProperties = true;
    emit twistLimitLowerChanged();
}

float QD6Joint::twistLimitUpper() const
{
    return m_twistLimitUpper;
}

void QD6Joint::setTwistLimitUpper(float limit)
{
    // PhysX requires the twist limit to be strictly within (-2*Pi, 2*Pi)
    limit = qBound(-float(M_PI * 2) + 0.0001f, limit, float(M_PI * 2) - 0.0001f);

    if (qFuzzyCompare(m_twistLimitUpper, limit))
        return;
    m_twistLimitUpper = limit;
    m_dirtyProperties = true;
    emit twistLimitUpperChanged();
}

float QD6Joint::linearStiffness() const
{
    return m_linearStiffness;
}

void QD6Joint::setLinearStiffness(float stiffness)
{
    stiffness = qMax(0.f, stiffness);

    if (qFuzzyCompare(m_linearStiffness, stiffness))
        return;
    m_linearStiffness = stiffness;
    m_dirtyProperties = true;
    emit linearStiffnessChanged();
}

float QD6Joint::linearDamping() const
{
    return m_linearDamping;
}

void QD6Joint::setLinearDamping(float damping)
{
    damping = qMax(0.f, damping);

    if (qFuzzyCompare(m_linearDamping, damping))
        return;
    m_linearDamping = damping;
    m_dirtyProperties = true;
    emit linearDampingChanged();
}

float QD6Joint::angularStiffness() const
{
    return m_angularStiffness;
}

void QD6Joint::setAngularStiffness(float stiffness)
{
    stiffness = qMax(0.f, stiffness);
    if (qFuzzyCompare(m_angularStiffness, stiffness))
        return;
    m_angularStiffness = stiffness;
    m_dirtyProperties = true;
    emit angularStiffnessChanged();
}

float QD6Joint::angularDamping() const
{
    return m_angularDamping;
}

void QD6Joint::setAngularDamping(float damping)
{
    damping = qMax(0.f, damping);
    if (qFuzzyCompare(m_angularDamping, damping))
        return;
    m_angularDamping = damping;
    m_dirtyProperties = true;
    emit angularDampingChanged();
}


QD6Joint::Motion QD6Joint::swingMotionY() const
{
    return m_swingMotionY;
}

void QD6Joint::setSwingMotionY(Motion newSwingMotionY)
{
    if (m_swingMotionY == newSwingMotionY)
        return;
    m_swingMotionY = newSwingMotionY;
    m_dirtyProperties = true;
    emit swingMotionYChanged();
}

QD6Joint::Motion QD6Joint::swingMotionZ() const
{
    return m_swingMotionZ;
}

void QD6Joint::setSwingMotionZ(Motion newSwingMotionZ)
{
    if (m_swingMotionZ == newSwingMotionZ)
        return;
    m_swingMotionZ = newSwingMotionZ;
    m_dirtyProperties = true;
    emit swingMotionZChanged();
}

float QD6Joint::swingLimitAngleY() const
{
    return m_swingLimitAngleY;
}

void QD6Joint::setSwingLimitAngleY(float newSwingLimitAngleY)
{
    // Clamp swing angle between Math standard (0, Pi)
    newSwingLimitAngleY = qBound(0.0001f, newSwingLimitAngleY, float(M_PI) - 0.0001f);

    if (qFuzzyCompare(m_swingLimitAngleY, newSwingLimitAngleY))
        return;
    m_swingLimitAngleY = newSwingLimitAngleY;
    m_dirtyProperties = true;
    emit swingLimitAngleYChanged();
}

float QD6Joint::swingLimitAngleZ() const
{
    return m_swingLimitAngleZ;
}

void QD6Joint::setSwingLimitAngleZ(float newSwingLimitAngleZ)
{
    // Clamp swing angle between Math standard (0, Pi)
    newSwingLimitAngleZ = qBound(0.0001f, newSwingLimitAngleZ, float(M_PI) - 0.0001f);

    if (qFuzzyCompare(m_swingLimitAngleZ, newSwingLimitAngleZ))
        return;
    m_swingLimitAngleZ = newSwingLimitAngleZ;
    m_dirtyProperties = true;
    emit swingLimitAngleZChanged();
}

physx::PxJoint *QD6Joint::createPhysxJoint(physx::PxRigidActor *actorA,
                                           physx::PxRigidActor *actorB,
                                           const physx::PxTransform &trfA,
                                           const physx::PxTransform &trfB)
{
    return physx::PxD6JointCreate(*StaticPhysXObjects::getReference().physics,
                                  actorA, trfA, actorB, trfB);
}

void QD6Joint::setJointProperties()
{
    auto *d6Joint = static_cast<physx::PxD6Joint *>(m_joint);
    if (!d6Joint)
        return;

    const physx::PxTolerancesScale scale =
            StaticPhysXObjects::getReference().physics->getTolerancesScale();

    d6Joint->setMotion(physx::PxD6Axis::eX, toPxEnum(m_xMotion));
    d6Joint->setMotion(physx::PxD6Axis::eY, toPxEnum(m_yMotion));
    d6Joint->setMotion(physx::PxD6Axis::eZ, toPxEnum(m_zMotion));
    d6Joint->setMotion(physx::PxD6Axis::eTWIST, toPxEnum(m_twistMotion));
    d6Joint->setMotion(physx::PxD6Axis::eSWING1, toPxEnum(m_swingMotionY));
    d6Joint->setMotion(physx::PxD6Axis::eSWING2, toPxEnum(m_swingMotionZ));

    if (m_xMotion == Motion::Limited) {
        physx::PxJointLinearLimitPair limit(scale, qMin(m_linearLimitXLower, m_linearLimitXUpper),
                                            qMax(m_linearLimitXLower, m_linearLimitXUpper));
        limit.stiffness = m_linearStiffness; // Use linear stiffness for linear limits
        limit.damping = m_linearDamping;     // Use linear damping for linear limits
        d6Joint->setLinearLimit(physx::PxD6Axis::eX, limit);
    }

    if (m_yMotion == Motion::Limited) {
        physx::PxJointLinearLimitPair limit(scale, qMin(m_linearLimitYLower, m_linearLimitYUpper),
                                            qMax(m_linearLimitYLower, m_linearLimitYUpper));
        limit.stiffness = m_linearStiffness; // Use linear stiffness for linear limits
        limit.damping = m_linearDamping;     // Use linear damping for linear limits
        d6Joint->setLinearLimit(physx::PxD6Axis::eY, limit);
    }

    if (m_zMotion == Motion::Limited) {
        physx::PxJointLinearLimitPair limit(scale, qMin(m_linearLimitZLower, m_linearLimitZUpper),
                                            qMax(m_linearLimitZLower, m_linearLimitZUpper));
        limit.stiffness = m_linearStiffness; // Use linear stiffness for linear limits
        limit.damping = m_linearDamping;     // Use linear damping for linear limits
        d6Joint->setLinearLimit(physx::PxD6Axis::eZ, limit);
    }

    if (m_twistMotion == Motion::Limited) {
        physx::PxJointAngularLimitPair limit(qMin(m_twistLimitLower, m_twistLimitUpper),
                                             qMax(m_twistLimitLower, m_twistLimitUpper));
        limit.stiffness = m_angularStiffness; // Use angular stiffness for twist limit
        limit.damping = m_angularDamping;     // Use angular damping for twist limit
        d6Joint->setTwistLimit(limit);
    }

    if (m_swingMotionY == Motion::Limited || m_swingMotionZ == Motion::Limited) {
        // PhysX requires cone angles to be strictly within (0, Pi) range
        const float angleY = qBound(0.0001f, m_swingLimitAngleY, float(M_PI) - 0.0001f);
        const float angleZ = qBound(0.0001f, m_swingLimitAngleZ, float(M_PI) - 0.0001f);

        physx::PxJointLimitCone limit(angleY, angleZ);
        limit.stiffness = m_angularStiffness;
        limit.damping = m_angularDamping;
        d6Joint->setSwingLimit(limit);
    }
}

QT_END_NAMESPACE

