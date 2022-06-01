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

#include "qdynamicsworld_p.h"
#include "qphysicscommands_p.h"
#include "qphysicsutils_p.h"
#include "qrigidbody_p.h"
#include "PxPhysicsAPI.h"

QT_BEGIN_NAMESPACE

QPhysicsCommandApplyCentralForce::QPhysicsCommandApplyCentralForce(const QVector3D &inForce)
    : QPhysicsCommand(), force(inForce)
{
}

void QPhysicsCommandApplyCentralForce::execute(const QDynamicRigidBody &rigidBody,
                                               physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    const auto isKinematic =
            static_cast<bool>(body.getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC);
    if (!isKinematic)
        body.addForce(QPhysicsUtils::toPhysXType(force));
}

QPhysicsCommandApplyForce::QPhysicsCommandApplyForce(const QVector3D &inForce,
                                                     const QVector3D &inPosition)
    : QPhysicsCommand(), force(inForce), position(inPosition)
{
}

void QPhysicsCommandApplyForce::execute(const QDynamicRigidBody &rigidBody,
                                        physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    const auto isKinematic =
            static_cast<bool>(body.getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC);
    if (!isKinematic)
        physx::PxRigidBodyExt::addForceAtPos(body, QPhysicsUtils::toPhysXType(force),
                                             QPhysicsUtils::toPhysXType(position));
}

QPhysicsCommandApplyTorque::QPhysicsCommandApplyTorque(const QVector3D &inTorque)
    : QPhysicsCommand(), torque(inTorque)
{
}

void QPhysicsCommandApplyTorque::execute(const QDynamicRigidBody &rigidBody,
                                         physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    const auto isKinematic =
            static_cast<bool>(body.getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC);
    if (!isKinematic)
        body.addTorque(QPhysicsUtils::toPhysXType(torque));
}

QPhysicsCommandApplyCentralImpulse::QPhysicsCommandApplyCentralImpulse(const QVector3D &inImpulse)
    : QPhysicsCommand(), impulse(inImpulse)
{
}

void QPhysicsCommandApplyCentralImpulse::execute(const QDynamicRigidBody &rigidBody,
                                                 physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    const auto isKinematic =
            static_cast<bool>(body.getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC);
    if (!isKinematic)
        body.addForce(QPhysicsUtils::toPhysXType(impulse), physx::PxForceMode::eIMPULSE);
}

QPhysicsCommandApplyImpulse::QPhysicsCommandApplyImpulse(const QVector3D &inImpulse,
                                                         const QVector3D &inPosition)
    : QPhysicsCommand(), impulse(inImpulse), position(inPosition)
{
}

void QPhysicsCommandApplyImpulse::execute(const QDynamicRigidBody &rigidBody,
                                          physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    const auto isKinematic =
            static_cast<bool>(body.getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC);
    if (!isKinematic)
        physx::PxRigidBodyExt::addForceAtPos(body, QPhysicsUtils::toPhysXType(impulse),
                                             QPhysicsUtils::toPhysXType(position),
                                             physx::PxForceMode::eIMPULSE);
}

QPhysicsCommandApplyTorqueImpulse::QPhysicsCommandApplyTorqueImpulse(const QVector3D &inImpulse)
    : QPhysicsCommand(), impulse(inImpulse)
{
}

void QPhysicsCommandApplyTorqueImpulse::execute(const QDynamicRigidBody &rigidBody,
                                                physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    const auto isKinematic =
            static_cast<bool>(body.getRigidBodyFlags() & physx::PxRigidBodyFlag::eKINEMATIC);
    if (!isKinematic)
        body.addTorque(QPhysicsUtils::toPhysXType(impulse), physx::PxForceMode::eIMPULSE);
}

QPhysicsCommandSetAngularVelocity::QPhysicsCommandSetAngularVelocity(
        const QVector3D &inAngularVelocity)
    : QPhysicsCommand(), angularVelocity(inAngularVelocity)
{
}

void QPhysicsCommandSetAngularVelocity::execute(const QDynamicRigidBody &rigidBody,
                                                physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    body.setAngularVelocity(QPhysicsUtils::toPhysXType(angularVelocity));
}

QPhysicsCommandSetLinearVelocity::QPhysicsCommandSetLinearVelocity(
        const QVector3D &inLinearVelocity)
    : QPhysicsCommand(), linearVelocity(inLinearVelocity)
{
}

void QPhysicsCommandSetLinearVelocity::execute(const QDynamicRigidBody &rigidBody,
                                               physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    body.setLinearVelocity(QPhysicsUtils::toPhysXType(linearVelocity));
}

QPhysicsCommandSetMass::QPhysicsCommandSetMass(float inMass) : QPhysicsCommand(), mass(inMass) { }

void QPhysicsCommandSetMass::execute(const QDynamicRigidBody &rigidBody, physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    physx::PxRigidBodyExt::setMassAndUpdateInertia(body, mass);
}

void QPhysicsCommandSetMassAndInertiaTensor::execute(const QDynamicRigidBody &rigidBody,
                                                     physx::PxRigidBody &body)
{
    body.setMass(mass);
    body.setCMassLocalPose(
            physx::PxTransform(QPhysicsUtils::toPhysXType(rigidBody.centerOfMassPosition()),
                               QPhysicsUtils::toPhysXType(rigidBody.centerOfMassRotation())));
    body.setMassSpaceInertiaTensor(QPhysicsUtils::toPhysXType(inertia));
}

QPhysicsCommandSetMassAndInertiaMatrix::QPhysicsCommandSetMassAndInertiaMatrix(
        float inMass, const QMatrix3x3 &inInertia)
    : QPhysicsCommand(), mass(inMass), inertia(inInertia)
{
}

void QPhysicsCommandSetMassAndInertiaMatrix::execute(const QDynamicRigidBody &rigidBody,
                                                     physx::PxRigidBody &body)
{
    physx::PxQuat massFrame;
    physx::PxVec3 diagTensor = physx::PxDiagonalize(QPhysicsUtils::toPhysXType(inertia), massFrame);
    if ((diagTensor.x <= 0.0f) || (diagTensor.y <= 0.0f) || (diagTensor.z <= 0.0f))
        return; // FIXME: print error?

    body.setCMassLocalPose(physx::PxTransform(
            QPhysicsUtils::toPhysXType(rigidBody.centerOfMassPosition()), massFrame));
    body.setMass(mass);
    body.setMassSpaceInertiaTensor(diagTensor);
}

QPhysicsCommandSetDensity::QPhysicsCommandSetDensity(float inDensity)
    : QPhysicsCommand(), density(inDensity)
{
}

void QPhysicsCommandSetDensity::execute(const QDynamicRigidBody &rigidBody,
                                        physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    physx::PxRigidBodyExt::updateMassAndInertia(body, density);
}

QPhysicsCommandSetIsKinematic::QPhysicsCommandSetIsKinematic(bool inIsKinematic)
    : QPhysicsCommand(), isKinematic(inIsKinematic)
{
}

void QPhysicsCommandSetIsKinematic::execute(const QDynamicRigidBody &rigidBody,
                                            physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    body.setRigidBodyFlag(physx::PxRigidBodyFlag::eKINEMATIC, isKinematic);
}

QPhysicsCommandSetGravityEnabled::QPhysicsCommandSetGravityEnabled(bool inGravityEnabled)
    : QPhysicsCommand(), gravityEnabled(inGravityEnabled)
{
}

void QPhysicsCommandSetGravityEnabled::execute(const QDynamicRigidBody &rigidBody,
                                               physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    body.setActorFlag(physx::PxActorFlag::eDISABLE_GRAVITY, !gravityEnabled);
}

QPhysicsCommandReset::QPhysicsCommandReset(QVector3D inPosition, QVector3D inEulerRotation)
    : QPhysicsCommand(), position(inPosition), eulerRotation(inEulerRotation)
{
}

void QPhysicsCommandReset::execute(const QDynamicRigidBody &rigidBody, physx::PxRigidBody &body)
{
    Q_UNUSED(rigidBody)
    body.setLinearVelocity(physx::PxVec3(0, 0, 0));
    body.setAngularVelocity(physx::PxVec3(0, 0, 0));
    body.setGlobalPose(physx::PxTransform(
            QPhysicsUtils::toPhysXType(position),
            QPhysicsUtils::toPhysXType(QQuaternion::fromEulerAngles(eulerRotation))));
}

QPhysicsCommandSetMassAndInertiaTensor::QPhysicsCommandSetMassAndInertiaTensor(
        float inMass, const QVector3D &inInertia)
    : QPhysicsCommand(), mass(inMass), inertia(inInertia)
{
}

QT_END_NAMESPACE
