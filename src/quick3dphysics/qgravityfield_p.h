// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef GRAVITYFIELD_H
#define GRAVITYFIELD_H

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
#include "qabstracttriggerregion_p.h"
#include "qphysicsgravity_p.h"

#include <QtCore/QPointer>
#include <QtGui/qvector3d.h>
#include <QtQml/QQmlEngine>

QT_BEGIN_NAMESPACE

class QPhysXGravityField;

// A gravity of its own. With collision shapes it acts on the bodies inside
// them, which PhysX finds as it does for a TriggerBody; with none it acts on
// every body in the scene, which the world walks.
class Q_QUICK3DPHYSICS_EXPORT QGravityField : public QAbstractTriggerRegion
{
    Q_OBJECT
    Q_PROPERTY(Mode mode READ mode WRITE setMode NOTIFY modeChanged FINAL REVISION(6, 13))
    Q_PROPERTY(QVector3D direction READ direction WRITE setDirection NOTIFY directionChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float gravity READ gravity WRITE setGravity NOTIFY gravityChanged FINAL
                       REVISION(6, 13))
    Q_PROPERTY(float unitDistance READ unitDistance WRITE setUnitDistance NOTIFY
                       unitDistanceChanged FINAL REVISION(6, 13))
    QML_NAMED_ELEMENT(GravityField)
    QML_ADDED_IN_VERSION(6, 13)
public:
    enum class Mode {
        Directional,
        Point,
    };
    Q_ENUM(Mode)

    QGravityField();
    ~QGravityField() override;

    Q_REVISION(6, 13) Mode mode() const;
    Q_REVISION(6, 13) void setMode(Mode mode);

    Q_REVISION(6, 13) const QVector3D &direction() const;
    Q_REVISION(6, 13) void setDirection(const QVector3D &direction);

    Q_REVISION(6, 13) float gravity() const;
    Q_REVISION(6, 13) void setGravity(float gravity);

    Q_REVISION(6, 13) float unitDistance() const;
    Q_REVISION(6, 13) void setUnitDistance(float unitDistance);

    // The gravity as set. Its center is left for the backend to fill in from
    // the pose of the field's actor.
    const QPhysicsGravity &gravityState() const;

    // Whether the field has no shapes, and so acts on the whole scene.
    bool isSceneWide() const;

    bool countsBody(const QAbstractPhysicsNode *body) const override;
    QAbstractPhysXNode *createPhysXBackend() override;

Q_SIGNALS:
    Q_REVISION(6, 13) void modeChanged();
    Q_REVISION(6, 13) void directionChanged();
    Q_REVISION(6, 13) void gravityChanged();
    Q_REVISION(6, 13) void unitDistanceChanged();

protected:
    void bodyDidEnter(QAbstractPhysicsNode *body) override;
    void bodyDidExit(QAbstractPhysicsNode *body) override;

private:
    // Queues `body` to be woken by the backend, if it can sleep. Waking is not
    // allowed from the trigger callback that bodyDidEnter() and bodyDidExit()
    // run from.
    void queueWake(QAbstractPhysicsNode *body);
    // Every body inside the field's shapes that it acts on.
    QList<QPointer<QAbstractPhysicsNode>> trackedBodies() const;

    QPhysicsGravity m_gravity;
    QList<QPointer<QAbstractPhysicsNode>> m_pendingWakes;
    // Whether everything the field acts on is to be woken, because its gravity
    // changed. True to begin with, since a field appearing is as much a reason
    // to move as one changing.
    bool m_pendingWakeAll = true;

    friend class QPhysXGravityField;
};

QT_END_NAMESPACE

#endif // GRAVITYFIELD_H
