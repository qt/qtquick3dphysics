// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef REVOLUTEJOINT_H
#define REVOLUTEJOINT_H

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

class Q_QUICK3DPHYSICS_EXPORT QRevoluteJoint : public QPhysicsJoint
{
    Q_OBJECT
    Q_PROPERTY(float angularLimitLower READ angularLimitLower WRITE setAngularLimitLower NOTIFY
                       angularLimitLowerChanged FINAL REVISION(6, 12))
    Q_PROPERTY(float angularLimitUpper READ angularLimitUpper WRITE setAngularLimitUpper NOTIFY
                       angularLimitUpperChanged FINAL REVISION(6, 12))
    Q_PROPERTY(bool enableAngularLimit READ enableAngularLimit WRITE setEnableAngularLimit NOTIFY
                       enableAngularLimitChanged FINAL REVISION(6, 12))
    QML_NAMED_ELEMENT(RevoluteJoint)

public:
    Q_REVISION(6, 12) float angularLimitLower() const;
    Q_REVISION(6, 12) void setAngularLimitLower(float newAngularLimitLower);
    Q_REVISION(6, 12) float angularLimitUpper() const;
    Q_REVISION(6, 12) void setAngularLimitUpper(float newAngularLimitUpper);
    Q_REVISION(6, 12) bool enableAngularLimit() const;
    Q_REVISION(6, 12) void setEnableAngularLimit(bool newEnableAngularLimit);

signals:
    Q_REVISION(6, 12) void angularLimitLowerChanged();
    Q_REVISION(6, 12) void angularLimitUpperChanged();
    Q_REVISION(6, 12) void enableAngularLimitChanged();

protected:
    physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA, physx::PxRigidActor *actorB,
                                     const physx::PxTransform &trfA,
                                     const physx::PxTransform &trfB) final;
    void setJointProperties() final;

private:
    float m_angularLimitLower = -M_PI_2;
    float m_angularLimitUpper = M_PI_2;
    bool m_enableAngularLimit = false;
};

QT_END_NAMESPACE

#endif // REVOLUTEJOINT_H
