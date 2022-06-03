/****************************************************************************
**
** Copyright (C) 2021 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Quick 3D Physics Module.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef ABSTRACTCOLLISIONNODE_H
#define ABSTRACTCOLLISIONNODE_H

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
#include <QtQuick3D/private/qquick3dnode_p.h>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlListProperty>
#include <QtQuick3DPhysics/private/qabstractcollisionshape_p.h>

namespace physx {
class PxTransform;
class PxShape;
}

QT_BEGIN_NAMESPACE

class QPhysXBody;

class Q_QUICK3DPHYSICS_EXPORT QAbstractCollisionNode : public QQuick3DNode
{
    Q_OBJECT
    Q_PROPERTY(
            QQmlListProperty<QAbstractCollisionShape> collisionShapes READ collisionShapes CONSTANT)
    Q_PROPERTY(bool sendContactReports READ sendContactReports WRITE setSendContactReports NOTIFY
                       sendContactReportsChanged)
    Q_PROPERTY(bool receiveContactReports READ receiveContactReports WRITE setReceiveContactReports
                       NOTIFY receiveContactReportsChanged)
    Q_PROPERTY(bool enableTriggerReports READ enableTriggerReports WRITE setEnableTriggerReports
                       NOTIFY enableTriggerReportsChanged)

    QML_NAMED_ELEMENT(CollisionNode)
    QML_UNCREATABLE("abstract interface")
public:
    QAbstractCollisionNode();
    ~QAbstractCollisionNode() override;

    QQmlListProperty<QAbstractCollisionShape> collisionShapes();
    const QVector<QAbstractCollisionShape *> &getCollisionShapesList() const;

    physx::PxGeometry *getPhysXGeometry();

    void updateFromPhysicsTransform(const physx::PxTransform &transform);

    void registerContact(QAbstractCollisionNode *body, const QVector<QVector3D> &positions,
                         const QVector<QVector3D> &impulses, const QVector<QVector3D> &normals);

    bool sendContactReports() const;
    void setSendContactReports(bool sendContactReports);

    bool receiveContactReports() const;
    void setReceiveContactReports(bool receiveContactReports);

    bool enableTriggerReports() const;
    void setEnableTriggerReports(bool enableTriggerReports);

    bool hasStaticShapes() const { return m_hasStaticShapes; }

private Q_SLOTS:
    void onShapeDestroyed(QObject *object);
    void onShapeNeedsRebuild(QObject *object);

Q_SIGNALS:
    void bodyContact(QAbstractCollisionNode *body, const QVector<QVector3D> &positions,
                     const QVector<QVector3D> &impulses, const QVector<QVector3D> &normals);
    void sendContactReportsChanged(float sendContactReports);
    void receiveContactReportsChanged(float receiveContactReports);
    void enableTriggerReportsChanged(float enableTriggerReports);

private:
    static void qmlAppendShape(QQmlListProperty<QAbstractCollisionShape> *list,
                               QAbstractCollisionShape *shape);
    static QAbstractCollisionShape *qmlShapeAt(QQmlListProperty<QAbstractCollisionShape> *list,
                                               qsizetype index);
    static qsizetype qmlShapeCount(QQmlListProperty<QAbstractCollisionShape> *list);
    static void qmlClearShapes(QQmlListProperty<QAbstractCollisionShape> *list);

    QVector<QAbstractCollisionShape *> m_collisionShapes;
    bool m_shapesDirty = false;
    bool m_sendContactReports = false;
    bool m_receiveContactReports = false;
    bool m_enableTriggerReports = false;
    bool m_hasStaticShapes = false;

    friend class QPhysXBody;
    friend class QDynamicsWorld; // for register/deregister TODO: cleaner mechanism
    QPhysXBody *m_backendObject = nullptr;
};

QT_END_NAMESPACE

#endif // ABSTRACTCOLLISIONNODE_H
