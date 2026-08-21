// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qjoint_p.h"

#include "physxnode/qabstractphysxnode_p.h"
#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qphysicsutils_p.h"
#include "qphysicsworld_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxJoint.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype PhysicsJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \brief Base type for joints.

    This is the abstract base type for all joints.

    All joints have two bodies, and for each body a position and an orientation of the joint
    relative to its local frame. If one of the bodies is not set then the joint will be
    connected to the world.

    \note At least one of the bodies needs to be dynamic.

    \sa {DistanceJoint}
    \sa {FixedJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
    \sa {FlexibleJoint}
    \sa {D6Joint}
*/

/*!
    \qmlproperty PhysicsBody* PhysicsJoint::bodyA
    \since 6.12
    \default null

    This property defines the first of the bodies this joint connects to.
*/

/*!
    \qmlproperty PhysicsBody* PhysicsJoint::bodyB
    \since 6.12
    \default null

    This property defines the second of the bodies this joint connects to.
*/

/*!
    \qmlproperty vector3d PhysicsJoint::positionA
    \since 6.12
    \default (0, 0, 0)

    The position of the joint relative to PhysicsJoint::bodyA.
*/

/*!
    \qmlproperty vector3d PhysicsJoint::positionB
    \since 6.12
    \default (0, 0, 0)

    The position of the joint relative to PhysicsJoint::bodyB.
*/

/*!
    \qmlproperty quaternion PhysicsJoint::orientationA
    \since 6.12
    \default (1, 0, 0, 0)

    The orientation of the joint relative to PhysicsJoint::bodyA.
*/

/*!
    \qmlproperty quaternion PhysicsJoint::orientationB
    \since 6.12
    \default (1, 0, 0, 0)

    The orientation of the joint relative to PhysicsJoint::bodyB.
*/

QPhysicsJoint::QPhysicsJoint()
{
    QPhysicsWorld::registerJoint(this);
};

QPhysicsJoint::~QPhysicsJoint()
{
    QPhysicsWorld::deregisterJoint(this);
};

QAbstractPhysicsBody *QPhysicsJoint::bodyA() const
{
    return m_bodyA;
}

void QPhysicsJoint::setBodyA(QAbstractPhysicsBody *newBodyA)
{
    if (m_bodyA == newBodyA)
        return;

    if (m_bodyA)
        m_bodyA->disconnect(this);
    if (newBodyA)
        connect(newBodyA, &QAbstractPhysicsBody::destroyed, this, &QPhysicsJoint::onBodyDestroyed);

    m_bodyA = newBodyA;
    m_needsRebuild = true;
    emit bodyAChanged();
}

QAbstractPhysicsBody *QPhysicsJoint::bodyB() const
{
    return m_bodyB;
}

void QPhysicsJoint::setBodyB(QAbstractPhysicsBody *newBodyB)
{
    if (m_bodyB == newBodyB)
        return;

    if (m_bodyB)
        m_bodyB->disconnect(this);
    if (newBodyB)
        connect(newBodyB, &QAbstractPhysicsBody::destroyed, this, &QPhysicsJoint::onBodyDestroyed);

    m_bodyB = newBodyB;
    m_needsRebuild = true;
    emit bodyBChanged();
}

QVector3D QPhysicsJoint::positionA() const
{
    return m_positionA;
}

void QPhysicsJoint::setPositionA(const QVector3D &newPositionA)
{
    if (m_positionA == newPositionA)
        return;
    m_positionA = newPositionA;
    m_needsRebuild = true;
    emit positionAChanged();
}

QVector3D QPhysicsJoint::positionB() const
{
    return m_positionB;
}

void QPhysicsJoint::setPositionB(const QVector3D &newPositionB)
{
    if (m_positionB == newPositionB)
        return;
    m_positionB = newPositionB;
    m_needsRebuild = true;
    emit positionBChanged();
}

QQuaternion QPhysicsJoint::orientationA() const
{
    return m_orientationA;
}

void QPhysicsJoint::setOrientationA(const QQuaternion &newOrientationA)
{
    if (m_orientationA == newOrientationA)
        return;
    m_orientationA = newOrientationA;
    m_needsRebuild = true;
    emit orientationAChanged();
}

QQuaternion QPhysicsJoint::orientationB() const
{
    return m_orientationB;
}

void QPhysicsJoint::setOrientationB(const QQuaternion &newOrientationB)
{
    if (m_orientationB == newOrientationB)
        return;
    m_orientationB = newOrientationB;
    m_needsRebuild = true;
    emit orientationBChanged();
}

physx::PxJoint *QPhysicsJoint::getPhysXBackend() const
{
    return m_joint;
}

void QPhysicsJoint::onBodyDestroyed(QObject *body)
{
    if (!body)
        return;
    body->disconnect(this);
    if (m_bodyA == body)
        setBodyA(nullptr);
    if (m_bodyB == body)
        setBodyB(nullptr);
}

void QPhysicsJoint::updatePhysXBackend()
{
    if (!m_dirtyProperties && !m_needsRebuild)
        return;

    if (m_joint && m_needsRebuild) {
        m_joint->release();
        m_joint = nullptr;
    }

    if (!m_bodyA && !m_bodyB)
        return;

    QPhysXActorBody *actorBodyA = m_bodyA && m_bodyA->m_backendObject
            ? qobject_cast<QPhysXActorBody *>(m_bodyA->m_backendObject)
            : nullptr;
    QPhysXActorBody *actorBodyB = m_bodyB && m_bodyB->m_backendObject
            ? qobject_cast<QPhysXActorBody *>(m_bodyB->m_backendObject)
            : nullptr;
    physx::PxRigidActor *actorA = actorBodyA ? actorBodyA->actor : nullptr;
    physx::PxRigidActor *actorB = actorBodyB ? actorBodyB->actor : nullptr;

    if (!actorA && !actorB)
        return;

    Q_ASSERT(StaticPhysXObjects::getReference().physicsCreated);
    Q_ASSERT(StaticPhysXObjects::getReference().physics);

    // At least one body needs to be dynamic
    const bool compatibleTypes =
            (actorA && actorA->getType() == physx::PxActorType::Enum::eRIGID_DYNAMIC)
            || (actorB && actorB->getType() == physx::PxActorType::Enum::eRIGID_DYNAMIC);

    if (!compatibleTypes) {
        qWarning() << "QPhysicsJoint: Incompatible body types used for joint.";
    }

    if (m_needsRebuild && compatibleTypes) {
        auto trfA = physx::PxTransform(QPhysicsUtils::toPhysXType(m_positionA),
                                       QPhysicsUtils::toPhysXType(m_orientationA));
        auto trfB = physx::PxTransform(QPhysicsUtils::toPhysXType(m_positionB),
                                       QPhysicsUtils::toPhysXType(m_orientationB));
        if (!trfA.isSane()) {
            qWarning() << "PhysicsJoint: positionA/orientationA is not finite, using identity "
                          "instead.";
            trfA = physx::PxTransform(physx::PxIdentity);
        }
        if (!trfB.isSane()) {
            qWarning() << "PhysicsJoint: positionB/orientationB is not finite, using identity "
                          "instead.";
            trfB = physx::PxTransform(physx::PxIdentity);
        }
        m_joint = createPhysxJoint(actorA, actorB, trfA, trfB);
    }

    if (m_joint && (m_dirtyProperties || m_needsRebuild)) {
        setJointProperties();
    }

    m_dirtyProperties = false;
    m_needsRebuild = false;
}

QT_END_NAMESPACE
