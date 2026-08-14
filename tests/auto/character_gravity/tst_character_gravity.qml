// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    width: 640
    height: 480
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -9.82, 0)
        running: true
        forceDebugDraw: true
        typicalLength: 1
        typicalSpeed: 10
        scene: viewport.scene
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
        }

        LookAtNode {
            target: playerController
            PerspectiveCamera {
                id: camera
                clipNear: 0.1
                clipFar: 200
            }

            position: Qt.vector3d(0, 0, 100)
        }

        StaticRigidBody {
            id: planet
            position: Qt.vector3d(0, 0, 0)

            collisionShapes: SphereShape {
                diameter: 100
            }
        }

        CharacterController {
            id: playerController
            // Starts below the planet, on its surface
            position: Qt.vector3d(0 , -50 , 0)
            midAirControl: false
            sendTriggerReports: true

            collisionShapes: CapsuleShape {
                id: playerCapsule
                diameter: 1.0
                height: 1.8
            }

            movement: Qt.vector3d(0, 0, -20)

            property vector3d upVector: playerController.scenePosition.minus(planet.scenePosition).normalized()

            // Base rotation aligning local Y with the surface normal
            rotation: playerController.gravityOrientation
                        .times(Quaternion.fromEulerAngles(0, 90, 0))

            gravity: upVector.times(-9.8)
        }

        TriggerBody {
            id: triggerBoxLeft
            position: Qt.vector3d(50, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 1, 1)
            }
            receiveTriggerReports: true
            property bool entered: false
            onBodyEntered: function(body) {
                entered = true
            }
        }

        TriggerBody {
            id: triggerBoxBottom
            position: Qt.vector3d(0, 50, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 1, 1)
            }
            receiveTriggerReports: true
            property bool entered: false
            onBodyEntered: function(body) {
                entered = true
            }
        }

        TriggerBody {
            id: triggerBoxRight
            position: Qt.vector3d(-50, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 1, 1)
            }
            receiveTriggerReports: true
            property bool entered: false
            onBodyEntered: function(body) {
                entered = true
            }
        }

        PhysicsTestCase {
            name: "character left side"
            goalReached: triggerBoxLeft.entered
        }

        PhysicsTestCase {
            name: "character bottom side"
            goalReached: triggerBoxBottom.entered
        }

        PhysicsTestCase {
            name: "character right down"
            goalReached: triggerBoxRight.entered
        }
    }
}
