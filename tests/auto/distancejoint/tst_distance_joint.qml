// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    width: 400
    height: 300
    visible: true

    PhysicsWorld {
        id: world
        scene: viewport.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    property real poleLength: 100

    Connections {
        target: world
        function onFrameDone(timeStep) {
            poleLength += timeStep * 0.2
            if (poleLength > 300) {
                poleLength = 100
            }
        }
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
            position: Qt.vector3d(0, 200, 700)
            clipFar: 5000
            clipNear: 1
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
        }

        StaticRigidBody {
            id: anchor
            position: Qt.vector3d(0, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(60, 20, 60)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.6, 0.2, 0.6)
                materials: PrincipledMaterial {
                    baseColor: "gray"
                }
            }
        }

        DynamicRigidBody {
            id: ballBody
            position: Qt.vector3d(0, 100, 0)
            collisionShapes: SphereShape {
                diameter: 40
            }
            sendTriggerReports: true
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(0.4, 0.4, 0.4)
                materials: PrincipledMaterial {
                    baseColor: "blue"
                }
            }
        }

        DistanceJoint {
            bodyA: anchor
            bodyB: ballBody
            minDistance: poleLength
            maxDistance: poleLength
        }

        // Hit when the pole is fully retracted (ballBody at its lowest,
        // close to anchor).
        TriggerBody {
            id: triggerLow
            property bool hit: false
            position: Qt.vector3d(0, 100, 0)
            collisionShapes: BoxShape {}
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "cyan"
                    opacity: 0.5
                }
            }

            onBodyEntered: {
                hit = true;
            }
        }

        // Hit when the pole is fully extended (ballBody at its highest,
        // pushed up against gravity).
        TriggerBody {
            id: triggerHigh
            property bool hit: false
            position: Qt.vector3d(0, 300, 0)
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

    PhysicsTestCase {
        name: "maxDistance pulls ballBody down to the low trigger"
        goalReached: triggerLow.hit
    }

    PhysicsTestCase {
        name: "minDistance pushes ballBody up to the high trigger"
        goalReached: triggerHigh.hit
    }
}
