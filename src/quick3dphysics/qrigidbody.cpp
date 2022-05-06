/****************************************************************************
**
** Copyright (C) 2021 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Quick 3D Physics Module.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "qrigidbody_p.h"
#include "qphysicscommands_p.h"
#include "qdynamicsworld_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmltype DynamicRigidBody
    \inqmlmodule QtQuick3DPhysics
    \inherits PhysicsBody
    \since 6.4
    \brief Dynamic rigid body.

    This is the dynamic rigid body. A dynamic rigid body is an object that is part of the physics
    scene and behaves like a physical object with mass and velocity. Note that triangle mesh,
    heightfield and plane geometry shapes are only allowed as collision shapes when \l
    {DynamicRigidBody::} {isKinematic} is \c true.
*/

/*!
    \qmlproperty float DynamicRigidBody::mass
    This property defines the mass of the body. If the value is less than or equal to zero then the
    \c density property is used instead. Default value is \c -1.
*/

/*!
    \qmlproperty float DynamicRigidBody::density
    This property defines the density of the body. This is only used when \c mass is a non-positive
    value. When this property is non-positive, this body will use the \l {DynamicsWorld::}
    {defaultDensity} value. Default value is \c -1.
*/

/*!
    \qmlproperty vector3d DynamicRigidBody::linearVelocity
    This property defines the linear velocity of the body.
*/

/*!
    \qmlproperty vector3d DynamicRigidBody::angularVelocity
    This property defines the angular velocity of the body.
*/

/*!
    \qmlproperty bool DynamicRigidBody::axisLockLinearX
    This property locks the linear velocity of the body along the X-axis.
*/

/*!
    \qmlproperty bool DynamicRigidBody::axisLockLinearY
    This property locks the linear velocity of the body along the Y-axis.
*/

/*!
    \qmlproperty bool DynamicRigidBody::axisLockLinearZ
    This property locks the linear velocity of the body along the Z-axis.
*/

/*!
    \qmlproperty bool DynamicRigidBody::axisLockAngularX
    This property locks the angular velocity of the body along the X-axis.
*/

/*!
    \qmlproperty bool DynamicRigidBody::axisLockAngularY
    This property locks the angular velocity of the body along the Y-axis.
*/

/*!
    \qmlproperty bool DynamicRigidBody::axisLockAngularZ
    This property locks the angular velocity of the body along the Z-axis.
*/

/*!
    \qmlproperty bool DynamicRigidBody::isKinematic
    This property defines whether the object is kinematic or not. A kinematic object does not get
    influenced by external forces and can be seen as an object of infinite mass. If this property is
    set then in every simulation frame the physical object will be moved to its target position
    regardless of external forces.
*/

/*!
    \qmlproperty bool DynamicRigidBody::gravityEnabled
    This property defines whether the object is going to be affected by gravity or not.
*/

/*!
    \qmlmethod DynamicRigidBody::applyCentralForce(vector3d force)
    Apply a \a force on the center of the body.
*/

/*!
    \qmlmethod DynamicRigidBody::applyForce(vector3d force, vector3d position)
    Apply a \a force at a \a position on the body.
*/

/*!
    \qmlmethod DynamicRigidBody::applyTorque(vector3d torque)
    Apply \a torque on the body.
*/

/*!
    \qmlmethod DynamicRigidBody::applyCentralImpulse(vector3d impulse)
    Apply an \a impulse on the center of the body.
*/

/*!
    \qmlmethod DynamicRigidBody::applyImpulse(vector3d impulse, vector3d position)
    Apply an \a impulse at a \a position on the body.
*/

/*!
    \qmlmethod DynamicRigidBody::applyTorqueImpulse(vector3d impulse)
    Apply a torque \a impulse on the body.
*/

/*!
    \qmlmethod DynamicRigidBody::reset(vector3d position, vector3d eulerRotation)
    Reset the body's \a position and \a eulerRotation.
*/

QDynamicRigidBody::QDynamicRigidBody() = default;

QDynamicRigidBody::~QDynamicRigidBody()
{
    qDeleteAll(m_commandQueue);
    m_commandQueue.clear();
}

float QDynamicRigidBody::mass() const
{
    return m_mass;
}

QVector3D QDynamicRigidBody::linearVelocity() const
{
    return m_linearVelocity;
}

bool QDynamicRigidBody::isKinematic() const
{
    return m_isKinematic;
}

bool QDynamicRigidBody::gravityEnabled() const
{
    return m_gravityEnabled;
}

void QDynamicRigidBody::setMass(float mass)
{
    if (qFuzzyCompare(m_mass, mass))
        return;

    if (!(m_mass <= 0.f && mass <= 0.f)) // Skip when sign is still non-positive
        m_commandQueue.enqueue(new QPhysicsCommandSetMass(mass));

    m_mass = mass;
    emit massChanged(m_mass);
}

float QDynamicRigidBody::density() const
{
    return m_density;
}

void QDynamicRigidBody::setDensity(float density)
{
    if (qFuzzyCompare(m_density, density))
        return;

    if (!(m_density <= 0.f && density <= 0.f)) // Skip when sign is still non-positive
        m_commandQueue.enqueue(new QPhysicsCommandSetDensity(density));

    m_density = density;
    emit densityChanged(m_density);
}

void QDynamicRigidBody::setLinearVelocity(QVector3D linearVelocity)
{
    if (m_linearVelocity == linearVelocity)
        return;

    m_linearVelocity = linearVelocity;
    m_commandQueue.enqueue(new QPhysicsCommandSetLinearVelocity(m_linearVelocity));
    emit linearVelocityChanged(m_linearVelocity);
}

void QDynamicRigidBody::setIsKinematic(bool isKinematic)
{
    if (m_isKinematic == isKinematic)
        return;

    m_isKinematic = isKinematic;
    m_commandQueue.enqueue(new QPhysicsCommandSetIsKinematic(m_isKinematic));
    emit isKinematicChanged(m_isKinematic);
}

void QDynamicRigidBody::setGravityEnabled(bool gravityEnabled)
{
    if (m_gravityEnabled == gravityEnabled)
        return;

    m_gravityEnabled = gravityEnabled;
    m_commandQueue.enqueue(new QPhysicsCommandSetGravityEnabled(m_gravityEnabled));
    emit gravityEnabledChanged();
}

const QVector3D &QDynamicRigidBody::angularVelocity() const
{
    return m_angularVelocity;
}

void QDynamicRigidBody::setAngularVelocity(const QVector3D &newAngularVelocity)
{
    if (m_angularVelocity == newAngularVelocity)
        return;
    m_angularVelocity = newAngularVelocity;
    m_commandQueue.enqueue(new QPhysicsCommandSetAngularVelocity(m_angularVelocity));
    emit angularVelocityChanged();
}

bool QDynamicRigidBody::axisLockLinearX() const
{
    return m_axisLockLinearX;
}

void QDynamicRigidBody::setAxisLockLinearX(bool newAxisLockLinearX)
{
    if (m_axisLockLinearX == newAxisLockLinearX)
        return;
    m_axisLockLinearX = newAxisLockLinearX;
    emit axisLockLinearXChanged();
}

bool QDynamicRigidBody::axisLockLinearY() const
{
    return m_axisLockLinearY;
}

void QDynamicRigidBody::setAxisLockLinearY(bool newAxisLockLinearY)
{
    if (m_axisLockLinearY == newAxisLockLinearY)
        return;
    m_axisLockLinearY = newAxisLockLinearY;
    emit axisLockLinearYChanged();
}

bool QDynamicRigidBody::axisLockLinearZ() const
{
    return m_axisLockLinearZ;
}

void QDynamicRigidBody::setAxisLockLinearZ(bool newAxisLockLinearZ)
{
    if (m_axisLockLinearZ == newAxisLockLinearZ)
        return;
    m_axisLockLinearZ = newAxisLockLinearZ;
    emit axisLockLinearZChanged();
}

bool QDynamicRigidBody::axisLockAngularX() const
{
    return m_axisLockAngularX;
}

void QDynamicRigidBody::setAxisLockAngularX(bool newAxisLockAngularX)
{
    if (m_axisLockAngularX == newAxisLockAngularX)
        return;
    m_axisLockAngularX = newAxisLockAngularX;
    emit axisLockAngularXChanged();
}

bool QDynamicRigidBody::axisLockAngularY() const
{
    return m_axisLockAngularY;
}

void QDynamicRigidBody::setAxisLockAngularY(bool newAxisLockAngularY)
{
    if (m_axisLockAngularY == newAxisLockAngularY)
        return;
    m_axisLockAngularY = newAxisLockAngularY;
    emit axisLockAngularYChanged();
}

bool QDynamicRigidBody::axisLockAngularZ() const
{
    return m_axisLockAngularZ;
}

void QDynamicRigidBody::setAxisLockAngularZ(bool newAxisLockAngularZ)
{
    if (m_axisLockAngularZ == newAxisLockAngularZ)
        return;
    m_axisLockAngularZ = newAxisLockAngularZ;
    emit axisLockAngularZChanged();
}

QQueue<QPhysicsCommand *> &QDynamicRigidBody::commandQueue()
{
    return m_commandQueue;
}

void QDynamicRigidBody::updateDefaultDensity(float defaultDensity)
{
    if (m_density <= 0.f)
        m_commandQueue.enqueue(new QPhysicsCommandSetDensity(defaultDensity));
}

void QDynamicRigidBody::applyCentralForce(const QVector3D &force)
{
    m_commandQueue.enqueue(new QPhysicsCommandApplyCentralForce(force));
}

void QDynamicRigidBody::applyForce(const QVector3D &force, const QVector3D &position)
{
    m_commandQueue.enqueue(new QPhysicsCommandApplyForce(force, position));
}

void QDynamicRigidBody::applyTorque(const QVector3D &torque)
{
    m_commandQueue.enqueue(new QPhysicsCommandApplyTorque(torque));
}

void QDynamicRigidBody::applyCentralImpulse(const QVector3D &impulse)
{
    m_commandQueue.enqueue(new QPhysicsCommandApplyCentralImpulse(impulse));
}

void QDynamicRigidBody::applyImpulse(const QVector3D &impulse, const QVector3D &position)
{
    m_commandQueue.enqueue(new QPhysicsCommandApplyImpulse(impulse, position));
}

void QDynamicRigidBody::applyTorqueImpulse(const QVector3D &impulse)
{
    m_commandQueue.enqueue(new QPhysicsCommandApplyTorqueImpulse(impulse));
}

void QDynamicRigidBody::reset(const QVector3D &position, const QVector3D &eulerRotation)
{
    m_commandQueue.enqueue(new QPhysicsCommandReset(position, eulerRotation));
}

/*!
    \qmltype StaticRigidBody
    \inqmlmodule QtQuick3DPhysics
    \inherits PhysicsBody
    \since 6.4
    \brief Static rigid body.

    This is an immovable and static rigid body. It is technically possible to move the body but it
    will incur a performance penalty. Any collision shape is allowed for this body.
*/

QStaticRigidBody::QStaticRigidBody() = default;

QT_END_NAMESPACE
