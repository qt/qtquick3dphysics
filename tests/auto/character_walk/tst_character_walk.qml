// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick
import QtQuick3D.Physics.TestUtils

Item {
    width: 640
    height: 480
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -9.81, 0)
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

        PerspectiveCamera {
            id: camera1
            position: Qt.vector3d(0, 20, 15)
            eulerRotation: Qt.vector3d(-60, 0, 0)
            clipFar: 1000
            clipNear: 0.01
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
        }

        // ===================================================================
        // CASE 1: simple plane to test moving
        // ===================================================================
        StaticRigidBody {
            position: Qt.vector3d(0, -2, 10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 1, 4)
            }
        }

        TriggerBody {
            position: Qt.vector3d(-8, 0, 10)
            collisionShapes: BoxShape {
                id: trigger1Shape
                extents: Qt.vector3d(2, 4, 4)
            }
            onBodyEntered: (body) => {
                if (body === ctk1) {
                    ctk1.reachedFinish = true;
                }
            }
            receiveTriggerReports: true
        }

        CharacterController {
            id: ctk1
            position: Qt.vector3d(8, 0, 10)
            movement: Qt.vector3d(-5, 0, 0) // Drivable move left
            gravity: world.gravity
            slideOnSteepSlopes: true
            sendTriggerReports: true

            collisionShapes: CapsuleShape {
                diameter: 1
                height: 2
            }

            property bool reachedFinish: false
        }

        PhysicsTestCase {
            name: "CharacterController Straight Plane"
            goalReached: ctk1.reachedFinish
        }

        // ===================================================================
        // CASE 2: Invalid 60 degree rise (Slide back)
        // ===================================================================
        StaticRigidBody {
            id: steepSlope
            position: Qt.vector3d(0, 0, 0)
            eulerRotation: Qt.vector3d(60, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 1, 5)
            }
        }

        // Trigger at the bottom of the slope (finish / sliding zone)
        TriggerBody {
            position: Qt.vector3d(0, -2, 3)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 1, 4)
            }
            onBodyEntered: (body) => {
                if (body === ctk2_1) {
                    ctk2_1.slidToBottom = true;
                }
            }
            receiveTriggerReports: true
        }

        TriggerBody {
            position: Qt.vector3d(-10, 2, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(2, 2, 2)
            }
            onBodyEntered: (body) => {
                if (body === ctk2) {
                    ctk2.noSlidToBottom = true;
                }
            }
            receiveTriggerReports: true
        }

        CharacterController {
            id: ctk2
            position: Qt.vector3d(-2.5, 3, 0)

            movement: Qt.vector3d(-5, 0, 0)

            slopeLimit: 78.5
            gravity: world.gravity
            slideOnSteepSlopes: true
            sendTriggerReports: true

            collisionShapes: CapsuleShape {
                diameter: 1
                height: 2
            }

            property bool noSlidToBottom: false
        }

        CharacterController {
            id: ctk2_1
            position: Qt.vector3d(8.5, 3, 0)

            movement: Qt.vector3d(-5, 0, 0)
            sendTriggerReports: true

            slopeLimit: 60
            gravity: world.gravity
            slideOnSteepSlopes: true

            collisionShapes: CapsuleShape {
                diameter: 1
                height: 2
            }

            property bool slidToBottom: false
        }

        PhysicsTestCase {
            name: "CharacterController Slide Down Slope 60deg"
            goalReached: ctk2.noSlidToBottom && ctk2_1.slidToBottom
        }

        // ===================================================================
        // CASE 3: Steps (3 rises) and 2 triggers (at the beginning and end)
        // ===================================================================
        StaticRigidBody {
            position: Qt.vector3d(7, -4, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(6, 1, 4)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(3.5, -3.7, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 1, 4)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(2.5, -3.4, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 1, 4)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(1.5, -3.1, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 1, 4)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(-3, -2.8, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(8, 1, 4)
            }
        }

        TriggerBody {
            position: Qt.vector3d(4, -2.5, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 3, 4)
            }
            onBodyEntered: (body) => {
                if (body === ctk3) {
                    ctk3.startTriggerHit = true;
                }
            }
            receiveTriggerReports: true
        }

        TriggerBody {
            position: Qt.vector3d(-5, -1.5, -10)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1, 3, 4)
            }
            onBodyEntered: (body) => {
                if (body === ctk3) {
                    ctk3.endTriggerHit = true;
                }
            }
            receiveTriggerReports: true
        }

        CharacterController {
            id: ctk3
            position: Qt.vector3d(8, -3, -10)
            movement: Qt.vector3d(-4, 0, 0)
            maximumStepHeight: 0.2
            gravity: world.gravity
            slideOnSteepSlopes: true
            sendTriggerReports: true

            collisionShapes: CapsuleShape {
                diameter: 0.1 // We make the capsule rounding minimal to test the step offset.
                height: 2
            }

            property bool startTriggerHit: false
            property bool endTriggerHit: false
        }

        PhysicsTestCase {
            name: "CharacterController Stairs Climbing"
            goalReached: ctk3.startTriggerHit && ctk3.endTriggerHit
        }
    }
}
