// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef DISTANCEJOINT_H
#define DISTANCEJOINT_H

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

#include "joints/qflexiblejoint_p.h"

#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>
#include <qobjectdefs.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <QtQml/QQmlEngine>

#include <QString>

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QDistanceJoint : public QFlexibleJoint
{
    Q_OBJECT
    Q_PROPERTY(float minDistance READ minDistance WRITE setMinDistance NOTIFY minDistanceChanged
                       FINAL REVISION(6, 12))
    Q_PROPERTY(float maxDistance READ maxDistance WRITE setMaxDistance NOTIFY maxDistanceChanged
                       FINAL REVISION(6, 12))
    QML_NAMED_ELEMENT(DistanceJoint)

public:
    Q_REVISION(6, 12) float minDistance() const;
    Q_REVISION(6, 12) void setMinDistance(float newMinDistance);
    Q_REVISION(6, 12) float maxDistance() const;
    Q_REVISION(6, 12) void setMaxDistance(float newMaxDistance);

signals:
    Q_REVISION(6, 12) void minDistanceChanged();
    Q_REVISION(6, 12) void maxDistanceChanged();

protected:
    physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA, physx::PxRigidActor *actorB,
                                     const physx::PxTransform &trfA,
                                     const physx::PxTransform &trfB) final;
    void setJointProperties() final;

private:
    float m_minDistance = 0.f;
    float m_maxDistance = 0.f;
};

QT_END_NAMESPACE

#endif // DISTANCEJOINT_H
