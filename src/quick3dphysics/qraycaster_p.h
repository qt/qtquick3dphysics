// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef QRAYCASTER_P_H
#define QRAYCASTER_P_H

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

#include <QtCore/QPointer>
#include <QtCore/QVarLengthArray>
#include <QtGui/qvectornd.h>
#include <qqmlintegration.h>
#include <QtQml/QQmlListProperty>
#include <QtQuick3D/private/qquick3dnode_p.h>

#include <QtQuick3DPhysics/private/qquick3dphysicslocationhit_p.h>

QT_BEGIN_NAMESPACE

class QAbstractPhysicsNode;
class QPhysicsWorld;

class Q_QUICK3DPHYSICS_EXPORT QRaycaster : public QQuick3DNode
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(QVector3D direction READ direction WRITE setDirection NOTIFY directionChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float maxDistance READ maxDistance WRITE setMaxDistance NOTIFY maxDistanceChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(bool excludeParentBody READ excludeParentBody WRITE setExcludeParentBody NOTIFY
                       excludeParentBodyChanged FINAL REVISION(6, 13))
    Q_PROPERTY(QQmlListProperty<QAbstractPhysicsNode> excludedBodies READ excludedBodies CONSTANT
                       FINAL REVISION(6, 13))
    Q_PROPERTY(bool includeStatic READ includeStatic WRITE setIncludeStatic NOTIFY
                       includeStaticChanged FINAL REVISION(6, 13))
    Q_PROPERTY(bool includeDynamic READ includeDynamic WRITE setIncludeDynamic NOTIFY
                       includeDynamicChanged FINAL REVISION(6, 13))
    Q_PROPERTY(bool isColliding READ isColliding NOTIFY isCollidingChanged FINAL REVISION(6, 13))
    Q_PROPERTY(QQuick3DPhysicsLocationHit hit READ hit NOTIFY hitChanged FINAL REVISION(6, 13))
    QML_NAMED_ELEMENT(Raycaster)
    QML_ADDED_IN_VERSION(6, 13)

public:
    explicit QRaycaster(QQuick3DNode *parent = nullptr);
    ~QRaycaster() override;

    bool enabled() const;
    void setEnabled(bool enabled);

    QVector3D direction() const;
    void setDirection(const QVector3D &direction);

    float maxDistance() const;
    void setMaxDistance(float maxDistance);

    bool excludeParentBody() const;
    void setExcludeParentBody(bool excludeParentBody);

    QQmlListProperty<QAbstractPhysicsNode> excludedBodies();

    bool includeStatic() const;
    void setIncludeStatic(bool includeStatic);

    bool includeDynamic() const;
    void setIncludeDynamic(bool includeDynamic);

    bool isColliding() const;
    QQuick3DPhysicsLocationHit hit() const;

Q_SIGNALS:
    void enabledChanged();
    void directionChanged();
    void maxDistanceChanged();
    void excludeParentBodyChanged();
    void includeStaticChanged();
    void includeDynamicChanged();
    void isCollidingChanged();
    void hitChanged();
    void bodyEntered(QAbstractPhysicsNode *body);
    void bodyExited(QAbstractPhysicsNode *body);

private:
    void updateRaycast(QPhysicsWorld *world);
    void updateHit(const QQuick3DPhysicsLocationHit &hit);
    void clearHit();
    void gatherExcludedBodies(QVarLengthArray<const QAbstractPhysicsNode *, 4> &excluded) const;

    static void qmlAppendExcludedBody(QQmlListProperty<QAbstractPhysicsNode> *list,
                                      QAbstractPhysicsNode *body);
    static QAbstractPhysicsNode *qmlExcludedBodyAt(QQmlListProperty<QAbstractPhysicsNode> *list,
                                                   qsizetype index);
    static qsizetype qmlExcludedBodyCount(QQmlListProperty<QAbstractPhysicsNode> *list);
    static void qmlClearExcludedBodies(QQmlListProperty<QAbstractPhysicsNode> *list);

    bool m_enabled = true;
    QVector3D m_direction = QVector3D(0.0f, 0.0f, -1.0f);
    float m_maxDistance = 100.0f;
    bool m_excludeParentBody = true;
    bool m_includeStatic = true;
    bool m_includeDynamic = true;
    // Weak, so a body deleted after it was listed cannot go on matching a later body that
    // happens to land on the same address.
    QList<QPointer<QAbstractPhysicsNode>> m_excludedBodies;

    bool m_isColliding = false;
    QQuick3DPhysicsLocationHit m_hit;

    friend class QPhysicsWorld;
};

QT_END_NAMESPACE

#endif // QRAYCASTER_P_H
