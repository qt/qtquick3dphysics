// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Tests the character controller with a trigger box and a static body

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

        PerspectiveCamera {
            id: camera1
            position: Qt.vector3d(0, 5, 10)
            eulerRotation: Qt.vector3d(-20, 0, 0)
            clipFar: 50
            clipNear: 0.01
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
        }

        StaticRigidBody {
            collisionShapes: BoxShape {
                extents: Qt.vector3d(8, 2, 4)
            }
        }

        // wall
        DynamicRigidBody {
            position.x: -2
            position.y: 20

            collisionShapes: BoxShape {
                extents: Qt.vector3d(2, 2, 2)
            }
        }

        TriggerBody {
            id: triggerBox
            position: Qt.vector3d(2, 4, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(2, 1, 2)
            }
            receiveTriggerReports: true
            property bool entered: false
            onBodyEntered: function(body) {
                entered = true
            }
        }

        CharacterController {
            id: characterGravityUp
            property bool collided: false
            position: Qt.vector3d(2, 8, 0)

            gravity: world.gravity
            onCollisionsChanged: {
               collided = true;
            }

            sendTriggerReports: true

            collisionShapes:  CapsuleShape {
                height: 1
                diameter: 1
            }

            Model {
                eulerRotation.z: 90
                scale: Qt.vector3d(0.01, 0.01, 0.01)
                geometry: CapsuleGeometry {}
                materials: PrincipledMaterial {
                    baseColor: "blue"
                }
            }
        }

        CharacterController {
            id: characterGravityDown
            property bool collided: false
            position: Qt.vector3d(-2, -20, 0)
            gravity: Qt.vector3d(-world.gravity.x, -world.gravity.y, -world.gravity.z)

            onCollisionsChanged: {
               collided = true
            }

            sendTriggerReports: true

            collisionShapes:  CapsuleShape {
                height: 1
                diameter: 1
            }

            Model {
                eulerRotation.z: 90
                scale: Qt.vector3d(0.01, 0.01, 0.01)
                geometry: CapsuleGeometry {}
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
            }
        }

        CharacterController {
            id: characterUpDown
            property bool collided: false
            position: Qt.vector3d(-2, 3, 0)
            gravity: Qt.vector3d(0, 1, 0)

            onCollisionsChanged: {
               collided = true
            }

            sendTriggerReports: true

            collisionShapes: CapsuleShape {
                height: 1
                diameter: 1
            }

            Model {
                eulerRotation.z: 90
                scale: Qt.vector3d(0.01, 0.01, 0.01)
                geometry: CapsuleGeometry {}
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
            }
        }

        PhysicsTestCase {
            name: "character gravity up collision up/down"
            goalReached: characterUpDown.collisions === (CharacterController.Down | CharacterController.Up) // Squeezed between the wall above and the ground below
        }

        PhysicsTestCase {
            name: "character gravity up"
            goalReached: characterGravityUp.collisions === CharacterController.Down // should be down because up direction is -gravity
        }

        PhysicsTestCase {
            name: "character gravity down"
            goalReached: characterGravityDown.collisions === CharacterController.Down
        }

        PhysicsTestCase {
            name: "trigger box"
            goalReached: triggerBox.entered
        }

        // Drops 5 onto a floor of its own
        StaticRigidBody {
            position: Qt.vector3d(0, 0, -20)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(4, 2, 4)
            }
        }

        CharacterController {
            id: characterLanding
            property int landings: 0
            property real landingSpeed: 0
            position: Qt.vector3d(0, 7, -20)
            gravity: world.gravity

            onLanded: (speed) => {
                ++landings
                landingSpeed = speed
            }

            collisionShapes: CapsuleShape {
                height: 1
                diameter: 1
            }
        }

        PhysicsTestCase {
            name: "character landed"
            // A fall of 5 at 9.82 lands at sqrt(2 * 9.82 * 5), about 9.9
            goalReached: characterLanding.landings === 1 && characterLanding.landingSpeed > 9
                         && characterLanding.landingSpeed < 11
        }
    }
}
