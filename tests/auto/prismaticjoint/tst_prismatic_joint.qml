// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick

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
            position: Qt.vector3d(-400, 500, 1000)
            eulerRotation: Qt.vector3d(-20, -20, 0)
            clipFar: 5000
            clipNear: 1
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
        }

        PrismaticJoint {
            id: joint
            bodyA: boxA
            bodyB: boxB
            lowerLimit: -200
            upperLimit: 0
            positionA: Qt.vector3d(100, 0, 0)
            positionB: Qt.vector3d(-100, 0, 0)
        }

        DynamicRigidBody {
            id: boxA
            position: Qt.vector3d(-100, 200, 0)
            kinematicPosition: Qt.vector3d(-100, 200, 0)
            scale: Qt.vector3d(2, 0.5, 0.5)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "yellow"
                }
            }
            isKinematic: true
        }

        DynamicRigidBody {
            id: boxB
            position: Qt.vector3d(100, 200, 0)
            scale: Qt.vector3d(2, 0.5, 0.5)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "blue"
                }
            }
            sendTriggerReports: true
        }

        TriggerBody {
            id: trigger
            property bool hit: false
            position: Qt.vector3d(0, -100, 0)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "pink"
                }
            }

            onBodyEntered: {
                hit = true;
            }
        }
    }

    FrameAnimation {
        id: animator
        running: true
        onTriggered: {
            boxA.kinematicEulerRotation.z = boxA.kinematicEulerRotation.z + 1
        }
    }

    TestCase {
        name: "rotate"
        when: trigger.hit
        function triggered() {}
    }
}
