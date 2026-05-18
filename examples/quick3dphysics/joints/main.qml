// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

//! [full]
Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Qt Quick 3D Physics - Joints")

    PhysicsWorld {
        scene: viewport.scene
        running: true
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#d6dbdf"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 600, 700)
            eulerRotation: Qt.vector3d(-30, 0, 0)
            clipFar: 5000
            clipNear: 1
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
            castsShadow: true
            brightness: 1
            shadowFactor: 50
            shadowMapQuality: Light.ShadowMapQualityHigh
        }

        //! [joints]
        Rope {
            eulerRotation: Qt.vector3d(0, 0, -90)
            position: Qt.vector3d(0, 500, 0)
        }

        Prismatic {
            id: prismatic
            position: Qt.vector3d(-250, 100, 0)
        }

        Revolute {
            id: revolute
            position: Qt.vector3d(200, 200, 100)
        }
        //! [joints]

        StaticRigidBody {
            position: Qt.vector3d(0, -100, 0)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                scale: Qt.vector3d(20, 20, 1)
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }

        //! [animation]
        FrameAnimation {
            id: animator
            running: true
            onTriggered: {
                prismatic.jointRotation.z += 1
                revolute.jointRotation.x += 0.95
            }
        }
        //! [animation]
    }
}
//! [full]
