// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        scene: viewport.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    View3D {
        id: viewport
        width: parent.width
        height: parent.height
        focus: true

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            backgroundMode: SceneEnvironment.Color
            clearColor: "#f0f0f0"
        }

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 1500, 2500)
            eulerRotation: Qt.vector3d(-30, 0, 0)
            clipFar: 5000
            clipNear: 10
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
        }

        Cart {
            position: Qt.vector3d(300, 400, 500)
            eulerRotation: Qt.vector3d(0, 90, 0)
            limitAngular: true
        }

        Cart {
            position: Qt.vector3d(300, 400, -500)
            eulerRotation: Qt.vector3d(0, 90, 0)
        }

        StaticRigidBody {
            eulerRotation: Qt.vector3d(-79, -90, 0)
            scale: Qt.vector3d(20, 30, 100)
            physicsMaterial: physicsMaterial
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }

        TriggerBody {
            id: triggerFar
            property bool hit: false
            scale: Qt.vector3d(5, 5, 5)
            position: Qt.vector3d(-1000, 0, -500)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "pink"
                    opacity: 0.5
                }
            }

            onBodyExited: {
                hit = true;
            }
        }

        TriggerBody {
            id: triggerClose
            property bool hit: false
            scale: Qt.vector3d(5, 5, 5)
            position: Qt.vector3d(-1000, 0, 500)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "pink"
                    opacity: 0.5
                }
            }

            onBodyEntered: {
                hit = true;
            }
        }
    }

    FrameAnimation {
        id: animator
        property int frame: 0
        running: true
        onTriggered: {
            frame = frame + 1
        }
    }

    PhysicsTestCase {
        name: "done"
        goalReached: triggerFar.hit && !triggerClose.hit
    }
}
