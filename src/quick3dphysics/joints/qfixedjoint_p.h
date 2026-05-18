// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef FIXEDJOINT_H
#define FIXEDJOINT_H

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

class Q_QUICK3DPHYSICS_EXPORT QFixedJoint : public QPhysicsJoint
{
    Q_OBJECT
    QML_NAMED_ELEMENT(FixedJoint)
protected:
    physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA, physx::PxRigidActor *actorB,
                                     const physx::PxTransform &trfA,
                                     const physx::PxTransform &trfB) final;
    void setJointProperties() final;
};

QT_END_NAMESPACE

#endif // FIXEDJOINT_H
