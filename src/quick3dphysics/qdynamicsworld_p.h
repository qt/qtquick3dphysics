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

#ifndef DYNAMICSWORLD_H
#define DYNAMICSWORLD_H

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

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QTimerEvent>
#include <QtCore/QElapsedTimer>
#include <QtGui/QVector3D>
#include <QtQml/qqml.h>
#include <QBasicTimer>

#include <QtQuick3D/private/qquick3dviewport_p.h>

namespace physx {
class PxMaterial;
class PxPhysics;
class PxShape;
class PxRigidDynamic;
class PxRigidActor;
class PxRigidStatic;
class PxCooking;
class PxControllerManager;
}

QT_BEGIN_NAMESPACE

Q_DECLARE_LOGGING_CATEGORY(lcQuick3dPhysics);

class QAbstractCollisionNode;
class QAbstractCollisionShape;
class QAbstractRigidBody;
class QPhysXBody;
class QQuick3DModel;
class QQuick3DDefaultMaterial;
struct PhysXWorld;

class Q_QUICK3DPHYSICS_EXPORT QDynamicsWorld : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVector3D gravity READ gravity WRITE setGravity NOTIFY gravityChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(bool forceDebugView READ forceDebugView WRITE setForceDebugView NOTIFY
                       forceDebugViewChanged)
    Q_PROPERTY(bool enableCCD READ enableCCD WRITE setEnableCCD NOTIFY enableCCDChanged)
    Q_PROPERTY(float typicalLength READ typicalLength WRITE setTypicalLength NOTIFY
                       typicalLengthChanged)
    Q_PROPERTY(
            float typicalSpeed READ typicalSpeed WRITE setTypicalSpeed NOTIFY typicalSpeedChanged)
    Q_PROPERTY(float defaultDensity READ defaultDensity WRITE setDefaultDensity NOTIFY
                       defaultDensityChanged)
    Q_PROPERTY(
            QQuick3DViewport *sceneView READ sceneView WRITE setSceneView NOTIFY sceneViewChanged)

    QML_NAMED_ELEMENT(DynamicsWorld)

public:
    explicit QDynamicsWorld(QObject *parent = nullptr);
    ~QDynamicsWorld();

    QVector3D gravity() const;

    bool running() const;
    bool forceDebugView() const;
    bool enableCCD() const;
    float typicalLength() const;
    float typicalSpeed() const;
    float defaultDensity() const;

    void registerOverlap(physx::PxRigidActor *triggerActor, physx::PxRigidActor *otherActor);
    void deregisterOverlap(physx::PxRigidActor *triggerActor, physx::PxRigidActor *otherActor);

    bool hasSendContactReports(QAbstractCollisionNode *object) const;
    bool hasReceiveContactReports(QAbstractCollisionNode *object) const;

    static QDynamicsWorld *getWorld()
    {
        return self; // TODO: proper mechanism for finding "my" world.
    }

    void registerNode(QAbstractCollisionNode *collisionNode);
    void deregisterNode(QAbstractCollisionNode *collisionNode);

    QQuick3DViewport *sceneView() const;

    void setHasIndividualDebugView();

public slots:
    void setGravity(QVector3D gravity);
    void setRunning(bool running);
    void setForceDebugView(bool forceDebugView);
    void setEnableCCD(bool enableCCD);
    void setTypicalLength(float typicalLength);
    void setTypicalSpeed(float typicalSpeed);
    void setDefaultDensity(float defaultDensity);
    void setSceneView(QQuick3DViewport *sceneView);

signals:
    void gravityChanged(QVector3D gravity);
    void runningChanged(bool running);
    void enableCCDChanged(bool enableCCD);
    void forceDebugViewChanged(bool forceDebugView);
    void typicalLengthChanged(float typicalLength);
    void typicalSpeedChanged(float typicalSpeed);
    void defaultDensityChanged(float defaultDensity);
    void sceneViewChanged(QQuick3DViewport *sceneView);

protected:
    void timerEvent(QTimerEvent *event) override;

private:
    void updatePhysics();
    void initPhysics();
    void maintainTimer();
    void cleanupRemovedNodes();
    void updateDebugDraw();
    void disableDebugDraw();

    struct DebugModelHolder
    {
        QQuick3DModel *model = nullptr;
        QVector3D data;

        const QVector3D &halfExtents() const { return data; }
        void setHalfExtents(const QVector3D &halfExtents) { data = halfExtents; }

        float radius() const { return data.x(); }
        void setRadius(float radius) { data.setX(radius); }

        float heightScale() const { return data.x(); }
        void setHeightScale(float heightScale) { data.setX(heightScale); }

        float halfHeight() const { return data.y(); }
        void setHalfHeight(float halfHeight) { data.setY(halfHeight); }

        float rowScale() const { return data.y(); }
        void setRowScale(float rowScale) { data.setY(rowScale); }

        float columnScale() const { return data.z(); }
        void setColumnScale(float columnScale) { data.setZ(columnScale); }
    };

    QList<QPhysXBody *> m_physXBodies;
    QList<QAbstractCollisionShape *> m_collisionShapes;
    QMap<QAbstractCollisionShape *, DebugModelHolder> m_collisionShapeDebugModels;
    QSet<QAbstractCollisionNode *> m_removedCollisionNodes;

    QVector3D m_gravity = QVector3D(0.f, -981.f, 0.f);
    float m_typicalLength = 100.f; // 100 cm
    float m_typicalSpeed = 1000.f; // 1000 cm/s
    float m_defaultDensity = 0.001f; // 1 g/cm^3

    bool m_running = true;
    bool m_forceDebugView = false;
    // For performance, used to keep track if we have indiviually enabled debug drawing for any
    // collision shape
    bool m_hasIndividualDebugView = false;
    bool m_physicsInitialized = false;
    bool m_enableCCD = false;

    QBasicTimer m_updateTimer;
    QElapsedTimer m_deltaTime;
    PhysXWorld *m_physx = nullptr;
    QQuick3DViewport *m_sceneView = nullptr;
    QQuick3DDefaultMaterial *m_debugMaterial = nullptr;

    friend class QQuick3DPhysicsMesh; // TODO: better internal API
    friend class QTriangleMeshShape; //####
    friend class QHeightFieldShape;
    friend class QQuick3DPhysicsHeightField;
    static QDynamicsWorld *self;
    static physx::PxPhysics *getPhysics();
    static physx::PxCooking *getCooking();
    physx::PxCooking *cooking();
    physx::PxControllerManager *controllerManager();
    void initPhysXBody(QPhysXBody *);
    void markDirtyShapes(QPhysXBody *physXBody);
    void rebuildDirtyShapes(QPhysXBody *physXBody);
    void findSceneView();
};

QT_END_NAMESPACE

#endif // DYNAMICSWORLD_H
