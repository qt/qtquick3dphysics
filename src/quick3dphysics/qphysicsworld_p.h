// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef PHYSICSWORLD_H
#define PHYSICSWORLD_H

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

class QAbstractPhysicsNode;
class QAbstractCollisionShape;
class QAbstractRigidBody;
class QAbstractPhysXNode;
class QQuick3DModel;
class QQuick3DDefaultMaterial;
struct PhysXWorld;

class Q_QUICK3DPHYSICS_EXPORT QPhysicsWorld : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(QVector3D gravity READ gravity WRITE setGravity NOTIFY gravityChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(bool forceDebugDraw READ forceDebugDraw WRITE setForceDebugDraw NOTIFY
                       forceDebugDrawChanged)
    Q_PROPERTY(bool enableCCD READ enableCCD WRITE setEnableCCD NOTIFY enableCCDChanged)
    Q_PROPERTY(float typicalLength READ typicalLength WRITE setTypicalLength NOTIFY
                       typicalLengthChanged)
    Q_PROPERTY(
            float typicalSpeed READ typicalSpeed WRITE setTypicalSpeed NOTIFY typicalSpeedChanged)
    Q_PROPERTY(float defaultDensity READ defaultDensity WRITE setDefaultDensity NOTIFY
                       defaultDensityChanged)
    Q_PROPERTY(QQuick3DNode *viewport READ viewport WRITE setViewport NOTIFY viewportChanged
                       REVISION(6, 5))
    Q_PROPERTY(float minimumTimestep READ minimumTimestep WRITE setMinimumTimestep NOTIFY
                       minimumTimestepChanged REVISION(6, 5))
    Q_PROPERTY(float maximumTimestep READ maximumTimestep WRITE setMaximumTimestep NOTIFY
                       maximumTimestepChanged REVISION(6, 5))
    Q_PROPERTY(QQuick3DNode *scene READ scene WRITE setScene NOTIFY sceneChanged REVISION(6, 5))

    QML_NAMED_ELEMENT(PhysicsWorld)

public:
    explicit QPhysicsWorld(QObject *parent = nullptr);
    ~QPhysicsWorld();

    void classBegin() override;
    void componentComplete() override;

    QVector3D gravity() const;

    bool running() const;
    bool forceDebugDraw() const;
    bool enableCCD() const;
    float typicalLength() const;
    float typicalSpeed() const;
    float defaultDensity() const;
    Q_REVISION(6, 5) float minimumTimestep() const;
    Q_REVISION(6, 5) float maximumTimestep() const;

    void registerOverlap(physx::PxRigidActor *triggerActor, physx::PxRigidActor *otherActor);
    void deregisterOverlap(physx::PxRigidActor *triggerActor, physx::PxRigidActor *otherActor);

    bool hasSendContactReports(QAbstractPhysicsNode *object);
    bool hasReceiveContactReports(QAbstractPhysicsNode *object);

    static QPhysicsWorld *getWorld(QQuick3DNode *node);

    static void registerNode(QAbstractPhysicsNode *physicsNode);
    static void deregisterNode(QAbstractPhysicsNode *physicsNode);

    Q_REVISION(6, 5) QQuick3DNode *viewport() const;
    void setHasIndividualDebugDraw();
    physx::PxControllerManager *controllerManager();
    Q_REVISION(6, 5) QQuick3DNode *scene() const;

public slots:
    void setGravity(QVector3D gravity);
    void setRunning(bool running);
    void setForceDebugDraw(bool forceDebugDraw);
    void setEnableCCD(bool enableCCD);
    void setTypicalLength(float typicalLength);
    void setTypicalSpeed(float typicalSpeed);
    void setDefaultDensity(float defaultDensity);
    Q_REVISION(6, 5) void setViewport(QQuick3DNode *viewport);
    Q_REVISION(6, 5) void setMinimumTimestep(float minTimestep);
    Q_REVISION(6, 5) void setMaximumTimestep(float maxTimestep);
    Q_REVISION(6, 5) void setScene(QQuick3DNode *newScene);

signals:
    void gravityChanged(QVector3D gravity);
    void runningChanged(bool running);
    void enableCCDChanged(bool enableCCD);
    void forceDebugDrawChanged(bool forceDebugDraw);
    void typicalLengthChanged(float typicalLength);
    void typicalSpeedChanged(float typicalSpeed);
    void defaultDensityChanged(float defaultDensity);
    Q_REVISION(6, 5) void viewportChanged(QQuick3DNode *viewport);
    Q_REVISION(6, 5) void minimumTimestepChanged(float minimumTimestep);
    Q_REVISION(6, 5) void maximumTimestepChanged(float maxTimestep);
    void simulateFrame(float minTimestep, float maxTimestep);
    Q_REVISION(6, 5) void frameDone(float timestep);
    Q_REVISION(6, 5) void sceneChanged();

private:
    void frameFinished(float deltaTime);
    void initPhysics();
    void cleanupRemovedNodes();
    void updateDebugDraw();
    void disableDebugDraw();
    void matchOrphanNodes();

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

    QList<QAbstractPhysXNode *> m_physXBodies;
    QList<QAbstractPhysicsNode *> m_newPhysicsNodes;
    QMap<QAbstractCollisionShape *, DebugModelHolder> m_collisionShapeDebugModels;
    QSet<QAbstractPhysicsNode *> m_removedPhysicsNodes;
    QMutex m_removedPhysicsNodesMutex;

    QVector3D m_gravity = QVector3D(0.f, -981.f, 0.f);
    float m_typicalLength = 100.f; // 100 cm
    float m_typicalSpeed = 1000.f; // 1000 cm/s
    float m_defaultDensity = 0.001f; // 1 g/cm^3
    float m_minTimestep = 16.667f; // 60 fps
    float m_maxTimestep = 33.333f; // 30 fps

    bool m_running = true;
    bool m_forceDebugDraw = false;
    // For performance, used to keep track if we have indiviually enabled debug drawing for any
    // collision shape
    bool m_hasIndividualDebugDraw = false;
    bool m_physicsInitialized = false;
    bool m_enableCCD = false;

    PhysXWorld *m_physx = nullptr;
    QQuick3DNode *m_viewport = nullptr;
    QVector<QQuick3DDefaultMaterial *> m_debugMaterials;

    friend class QQuick3DPhysicsMesh; // TODO: better internal API
    friend class QTriangleMeshShape; //####
    friend class QHeightFieldShape;
    friend class QQuick3DPhysicsHeightField;
    static physx::PxPhysics *getPhysics();
    static physx::PxCooking *getCooking();
    QThread m_workerThread;
    QQuick3DNode *m_scene = nullptr;
};

QT_END_NAMESPACE

#endif // PHYSICSWORLD_H
