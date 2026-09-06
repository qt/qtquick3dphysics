// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef QQUICK3DPHYSICSQUERYLOCATIONHIT_H
#define QQUICK3DPHYSICSQUERYLOCATIONHIT_H

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

#include "qquick3dphysicsqueryhit_p.h"

namespace physx {
struct PxLocationHit;
}

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QQuick3DPhysicsLocationHit : public QQuick3DPhysicsQueryHit
{
    Q_GADGET
    QML_VALUE_TYPE(locationHit)
    QML_ADDED_IN_VERSION(6, 13)

    Q_PROPERTY(QVector3D position READ position CONSTANT FINAL REVISION(6, 13))
    Q_PROPERTY(QVector3D normal READ normal CONSTANT FINAL REVISION(6, 13))
    Q_PROPERTY(float distance READ distance CONSTANT FINAL REVISION(6, 13))

public:
    QQuick3DPhysicsLocationHit();
    explicit QQuick3DPhysicsLocationHit(const physx::PxLocationHit &hit,
                                        const physx::PxActorShape &actorShape);

    Q_REVISION(6, 13) QVector3D position() const;
    Q_REVISION(6, 13) QVector3D normal() const;
    Q_REVISION(6, 13) float distance() const;

private:
    QVector3D m_position;
    QVector3D m_normal;
    float m_distance = 0;
};

QT_END_NAMESPACE
#endif // QQUICK3DPHYSICSQUERYLOCATIONHIT_H
