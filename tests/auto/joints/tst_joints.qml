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

        DynamicRigidBody {
            position: Qt.vector3d(-300, 400, 50)
            collisionShapes: SphereShape {}
            Model {
                source: "#Sphere"
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
            }
        }

        FixedJoint {
            id: jointLeft
            bodyA: box4
            bodyB: box
            positionA: Qt.vector3d(100, 0, 0)
            positionB: Qt.vector3d(-100, 0, 0)
        }

        SphericalJoint {
            bodyA: box
            bodyB: box1
            coneLimitY: Math.PI / 2
            coneLimitZ: Math.PI / 2
            positionA: Qt.vector3d(100, 0, 0)
            positionB: Qt.vector3d(-100, 0, 0)
            NumberAnimation on coneLimitY {
                from: Math.PI / 2
                to: 0
                loops: -1
                duration: 4000
            }
            NumberAnimation on coneLimitZ {
                from: Math.PI / 2
                to: 0
                loops: -1
                duration: 4000
            }
            enableConeLimit: true
        }

        SphericalJoint {
            bodyA: box1
            bodyB: box2
            coneLimitY: Math.PI / 2
            coneLimitZ: Math.PI / 2

            NumberAnimation on coneLimitY {
                from: Math.PI / 2
                to: 0
                loops: -1
                duration: 4000
            }
            NumberAnimation on coneLimitZ {
                from: Math.PI / 2
                to: 0
                loops: -1
                duration: 4000
            }
            enableConeLimit: true

            positionA: Qt.vector3d(100, 0, 0)
            positionB: Qt.vector3d(-100, 0, 0)
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -400, 0)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                scale: Qt.vector3d(10, 10, 1)
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }

        DynamicRigidBody {
            id: box
            position: Qt.vector3d(-100, 200, 0)
            kinematicPosition: Qt.vector3d(-100, 200, 0)
            scale: Qt.vector3d(2, 0.5, 0.5)
            collisionShapes: BoxShape {
                id: boxShape
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "yellow"
                }
            }
            isKinematic: true
        }

        DynamicRigidBody {
            id: box1
            position: Qt.vector3d(100, 200, 0)
            scale: Qt.vector3d(2, 0.5, 0.5)
            collisionShapes: BoxShape {
                id: boxShape1
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "blue"
                }
            }
        }

        DynamicRigidBody {
            id: box2
            position: Qt.vector3d(300, 200, 0)
            scale: Qt.vector3d(2, 0.5, 0.5)
            collisionShapes: BoxShape {
                id: boxShape2
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "orange"
                }
            }
            sendTriggerReports: true
        }

        DynamicRigidBody {
            id: box4
            position: Qt.vector3d(-200, 200, 0)
            scale: Qt.vector3d(2, 0.5, 0.5)
            collisionShapes: BoxShape {
                id: boxShape4
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "pink"
                }
            }
        }

        TriggerBody {
            id: trigger0
            property int numHits: 0
            position: Qt.vector3d(400, 200, 0)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "cyan"
                    opacity: 0.5
                }
            }

            onBodyExited: {
                numHits += 1
            }
        }

        TriggerBody {
            id: trigger1
            property int numEntered: 0
            position: Qt.vector3d(-300, 100, 0)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "cyan"
                    opacity: 0.5
                }
            }
            onBodyEntered: {
                numEntered += 1
            }
        }
    }

    FrameAnimation {
        id: animator
        running: true
        property int frame: 0
        onTriggered: {
            frame += 1
        }
    }

    TestCase {
        name: "scene"
        when: trigger0.numHits == 2 && trigger1.numEntered == 0
        function triggered() {}
    }
}
