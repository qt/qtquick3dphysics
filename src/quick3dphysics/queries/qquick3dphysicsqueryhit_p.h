// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef QQUICK3DPHYSICSQUERYHIT_H
#define QQUICK3DPHYSICSQUERYHIT_H

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

#include <QtCore/QObject>
#include <QtGui/QVector3D>
#include <QtQml/qqmlregistration.h>
#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>

namespace physx {
struct PxActorShape;
struct PxQueryHit;
}

QT_BEGIN_NAMESPACE

class QAbstractPhysicsNode;
class QAbstractCollisionShape;

class Q_QUICK3DPHYSICS_EXPORT QQuick3DPhysicsQueryHit
{
    Q_GADGET
    QML_VALUE_TYPE(queryHit)
    QML_ADDED_IN_VERSION(6, 13)

    Q_PROPERTY(QAbstractPhysicsNode *body READ body CONSTANT FINAL REVISION(6, 13))
    Q_PROPERTY(QAbstractCollisionShape *shape READ shape CONSTANT FINAL REVISION(6, 13))

public:
    QQuick3DPhysicsQueryHit();

    // The hit carries faceIndex, which nothing exposes yet. Taken by reference so that
    // adding it later does not change this signature.
    explicit QQuick3DPhysicsQueryHit(const physx::PxQueryHit &hit,
                                     const physx::PxActorShape &actorShape);

    Q_REVISION(6, 13) QAbstractPhysicsNode *body() const;
    Q_REVISION(6, 13) QAbstractCollisionShape *shape() const;

private:
    QAbstractPhysicsNode *m_body = nullptr;
    QAbstractCollisionShape *m_shape = nullptr;
};

QT_END_NAMESPACE
#endif // QQUICK3DPHYSICSQUERYHIT_H
