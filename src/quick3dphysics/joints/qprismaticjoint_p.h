// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef PRISMATICJOINT_H
#define PRISMATICJOINT_H

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

class Q_QUICK3DPHYSICS_EXPORT QPrismaticJoint : public QPhysicsJoint
{
    Q_OBJECT
    Q_PROPERTY(float lowerLimit READ lowerLimit WRITE setLowerLimit NOTIFY lowerLimitChanged FINAL
                       REVISION(6, 12))
    Q_PROPERTY(float upperLimit READ upperLimit WRITE setUpperLimit NOTIFY upperLimitChanged FINAL
                       REVISION(6, 12))
    QML_NAMED_ELEMENT(PrismaticJoint)

public:
    Q_REVISION(6, 12) float lowerLimit() const;
    Q_REVISION(6, 12) void setLowerLimit(float newLowerLimit);
    Q_REVISION(6, 12) float upperLimit() const;
    Q_REVISION(6, 12) void setUpperLimit(float newupperLimit);

signals:
    Q_REVISION(6, 12) void lowerLimitChanged();
    Q_REVISION(6, 12) void upperLimitChanged();

protected:
    physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA, physx::PxRigidActor *actorB,
                                     const physx::PxTransform &trfA,
                                     const physx::PxTransform &trfB) final;
    void setJointProperties() final;

private:
    float m_lowerLimit = 0.f;
    float m_upperLimit = 0.f;
};

QT_END_NAMESPACE

#endif // PRISMATICJOINT_H
