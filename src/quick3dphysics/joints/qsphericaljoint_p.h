// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef SPHERICALJOINT_H
#define SPHERICALJOINT_H

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

#include "joints/qjoint_p.h"

#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>
#include <qobjectdefs.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <QtQml/QQmlEngine>

#include <QString>

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QSphericalJoint : public QPhysicsJoint
{
    Q_OBJECT
    Q_PROPERTY(float coneLimitY READ coneLimitY WRITE setConeLimitY NOTIFY coneLimitYChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(float coneLimitZ READ coneLimitZ WRITE setConeLimitZ NOTIFY coneLimitZChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(bool enableConeLimit READ enableConeLimit WRITE setEnableConeLimit NOTIFY
                       enableConeLimitChanged FINAL REVISION(6, 12))
    QML_NAMED_ELEMENT(SphericalJoint)

public:
    Q_REVISION(6, 12) float coneLimitY() const;
    Q_REVISION(6, 12) void setConeLimitY(float newConeLimitY);
    Q_REVISION(6, 12) float coneLimitZ() const;
    Q_REVISION(6, 12) void setConeLimitZ(float newConeLimitZ);
    Q_REVISION(6, 12) bool enableConeLimit() const;
    Q_REVISION(6, 12) void setEnableConeLimit(bool newEnableConeLimit);

signals:
    Q_REVISION(6, 12) void coneLimitYChanged();
    Q_REVISION(6, 12) void coneLimitZChanged();
    Q_REVISION(6, 12) void enableConeLimitChanged();

protected:
    physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA, physx::PxRigidActor *actorB,
                                     const physx::PxTransform &trfA,
                                     const physx::PxTransform &trfB) final;
    void setJointProperties() final;

private:
    float m_coneLimitY = 0.0f;
    float m_coneLimitZ = 0.0f;
    bool m_enableConeLimit = false;
};

QT_END_NAMESPACE

#endif // SPHERICALJOINT_H
