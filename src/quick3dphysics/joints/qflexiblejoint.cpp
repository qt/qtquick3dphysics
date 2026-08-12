// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qflexiblejoint_p.h"

#include <extensions/PxJoint.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype FlexibleJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.13
    \inherits PhysicsJoint
    \brief Base type for flexible joints with configurable spring stiffness and damping.

    This is the abstract base type for all joints that support customizable spring stiffness
    and damping factors for soft constraints and joint limits.

    Whether a joint limit is hard or soft, and how it behaves when soft, depends on the
    combination of \l stiffness and \l damping, as seen in the following table:

    \table
    \header
    \li \l stiffness
    \li \l damping
    \li Behavior
    \row
    \li \c 0.0
    \li \c 0.0
    \li Hard constraint: the limit cannot be penetrated (the default).
    \row
    \li greater than \c 0.0
    \li \c 0.0
    \li Soft spring, undamped: the body bounces against the limit indefinitely.
    \row
    \li greater than \c 0.0
    \li greater than \c 0.0
    \li Soft spring, damped: the body bounces against the limit and settles.
    \row
    \li \c 0.0
    \li greater than \c 0.0
    \li Soft, viscous drag only: motion is resisted, but no positional restoring force is
    applied.
    \endtable

    \note At least one of the connected bodies needs to be dynamic.

    \sa {FixedJoint}
    \sa {DistanceJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
    \sa {D6Joint}
*/

/*!
    \qmlproperty real FlexibleJoint::stiffness
    \since 6.13
    \default 0.0

    This property holds the spring stiffness for joint limits. See the table above for how it
    combines with \l damping to determine whether the limit is hard or soft.

    When greater than \c 0.0, the higher the value, the stronger the restorative force pulling
    the body back once it crosses the limit boundary, and the less penetration is allowed before
    the body is pushed back. The right value depends on the mass and geometry of the connected
    bodies. A value that feels stiff for a light body with a short lever arm may feel soft for a
    heavier body or a longer lever arm, so start from a small value and increase it until the
    limit feels sufficiently rigid for your scene.

    Range: \c{[0, \inf)}

    \sa damping, PhysicsWorld::typicalLength, PhysicsWorld::defaultDensity
*/

/*!
    \qmlproperty real FlexibleJoint::damping
    \since 6.13
    \default 0.0

    This property holds the energy dissipation (damping factor) for soft joint limits. See the
    table above for how it combines with \l stiffness to determine whether the limit is hard or
    soft.

    When \l stiffness is greater than \c 0.0, this property controls how quickly oscillations
    around the limit boundary settle: with \c 0.0 (the default), no energy is lost and the body
    bounces indefinitely; increasing the value suppresses the bounce, though too little leaves
    the body oscillating before it settles, while too much makes the motion near the limit feel
    heavy or sluggish.

    When \l stiffness is \c 0.0, this property instead applies a resistive (viscous) force with
    no positional restoring effect.

    Range: \c{[0, \inf)}

    \sa stiffness, PhysicsWorld::typicalLength, PhysicsWorld::defaultDensity
*/

float QFlexibleJoint::stiffness() const
{
    return m_stiffness;
}

void QFlexibleJoint::setStiffness(float stiffness)
{
    stiffness = qMax(0.f, stiffness);
    if (qFuzzyCompare(m_stiffness, stiffness))
        return;
    m_stiffness = stiffness;
    m_dirtyProperties = true;
    emit stiffnessChanged();
}

float QFlexibleJoint::damping() const
{
    return m_damping;
}

void QFlexibleJoint::setDamping(float damping)
{
    damping = qMax(0.f, damping);
    if (qFuzzyCompare(m_damping, damping))
        return;
    m_damping = damping;
    m_dirtyProperties = true;
    emit dampingChanged();
}

QT_END_NAMESPACE
