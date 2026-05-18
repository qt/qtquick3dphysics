// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef PHYSICSJOINT_H
#define PHYSICSJOINT_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>
#include <QtQuick3DPhysics/private/qabstractphysicsbody_p.h>
#include <qobjectdefs.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <QtQml/QQmlEngine>

#include <QString>

namespace physx {
class PxTransform;
class PxPhysics;
class PxJoint;
class PxRigidActor;
}

QT_BEGIN_NAMESPACE

class QPhysXActorBody;

class Q_QUICK3DPHYSICS_EXPORT QPhysicsJoint : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QAbstractPhysicsBody *bodyA READ bodyA WRITE setBodyA NOTIFY bodyAChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(QAbstractPhysicsBody *bodyB READ bodyB WRITE setBodyB NOTIFY bodyBChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(QVector3D positionA READ positionA WRITE setPositionA NOTIFY positionAChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(QVector3D positionB READ positionB WRITE setPositionB NOTIFY positionBChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(QQuaternion orientationA READ orientationA WRITE setOrientationA NOTIFY
                       orientationAChanged FINAL REVISION(6, 12))
    Q_PROPERTY(QQuaternion orientationB READ orientationB WRITE setOrientationB NOTIFY
                       orientationBChanged FINAL REVISION(6, 12))
    QML_NAMED_ELEMENT(PhysicsJoint)
    QML_UNCREATABLE("abstract interface")

public:
    QPhysicsJoint();
    ~QPhysicsJoint();

    Q_REVISION(6, 12) QAbstractPhysicsBody *bodyA() const;
    Q_REVISION(6, 12) void setBodyA(QAbstractPhysicsBody *newBodyA);
    Q_REVISION(6, 12) QAbstractPhysicsBody *bodyB() const;
    Q_REVISION(6, 12) void setBodyB(QAbstractPhysicsBody *newBodyB);
    Q_REVISION(6, 12) QVector3D positionA() const;
    Q_REVISION(6, 12) void setPositionA(const QVector3D &newPositionA);
    Q_REVISION(6, 12) QVector3D positionB() const;
    Q_REVISION(6, 12) void setPositionB(const QVector3D &newPositionB);
    Q_REVISION(6, 12) QQuaternion orientationA() const;
    Q_REVISION(6, 12) void setOrientationA(const QQuaternion &newOrientationA);
    Q_REVISION(6, 12) QQuaternion orientationB() const;
    Q_REVISION(6, 12) void setOrientationB(const QQuaternion &newOrientationB);

    void updatePhysXBackend();
    physx::PxJoint *getPhysXBackend() const;

signals:
    Q_REVISION(6, 12) void bodyAChanged();
    Q_REVISION(6, 12) void bodyBChanged();
    Q_REVISION(6, 12) void positionAChanged();
    Q_REVISION(6, 12) void positionBChanged();
    Q_REVISION(6, 12) void orientationAChanged();
    Q_REVISION(6, 12) void orientationBChanged();

protected:
    virtual physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA,
                                             physx::PxRigidActor *actorB,
                                             const physx::PxTransform &trfA,
                                             const physx::PxTransform &trfB) = 0;
    virtual void setJointProperties() = 0;
    void onBodyDestroyed(QObject *body);

    QAbstractPhysicsBody *m_bodyA = nullptr;
    QAbstractPhysicsBody *m_bodyB = nullptr;
    QVector3D m_positionA;
    QVector3D m_positionB;
    QQuaternion m_orientationA;
    QQuaternion m_orientationB;
    physx::PxJoint *m_joint = nullptr;
    bool m_needsRebuild = false; // Set to true when body or orientation is changed
    bool m_dirtyProperties = false; // Set to true when subclasses properties are updated
};

QT_END_NAMESPACE

#endif // PHYSICSJOINT_H
