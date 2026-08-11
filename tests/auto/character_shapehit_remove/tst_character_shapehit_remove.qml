// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Stress-tests ControllerCallback::onShapeHit() against nodes being destroyed
// in the same simulation frame a hit is reported for. Both the character and
// the obstacle it lands on are repeatedly created and destroyed to exercise
// both halves of the isNodeRemoved() guard.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    width: 640
    height: 480
    visible: true

    function randomInRange(min, max) {
        return Math.random() * (max - min) + min
    }

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
            position: Qt.vector3d(0, 5, 10)
            eulerRotation: Qt.vector3d(-20, 0, 0)
            clipFar: 50
            clipNear: 0.01
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
        }

        Timer {
            id: characterSpawnTimer
            interval: 100
            running: true
            repeat: true
            onTriggered: {
                let pos = Qt.vector3d(randomInRange(-5, 5), randomInRange(3, 6), randomInRange(-1, 1))
                characterSpawner.createCharacter(pos)
            }
        }

        Timer {
            id: characterResetTimer
            interval: 1300
            running: true
            repeat: true
            property int repeats: 0
            onTriggered: {
                characterSpawner.reset()
                repeats += 1
            }
        }

        Node {
            id: characterSpawner
            property var instances: []
            property var component: Qt.createComponent("Character.qml")

            function createCharacter(position) {
                let character = component.createObject(characterSpawner, { "position": position })
                if (character === null) {
                    console.log("Error creating character")
                    return
                }
                instances.push(character)
            }

            function reset() {
                instances.forEach(character => { character.destroy() })
                instances = []
            }
        }

        Timer {
            id: obstacleSpawnTimer
            interval: 250
            running: true
            repeat: true
            onTriggered: obstacleSpawner.createObstacle()
        }

        Timer {
            id: obstacleResetTimer
            interval: 900
            running: true
            repeat: true
            property int repeats: 0
            onTriggered: {
                obstacleSpawner.reset()
                repeats += 1
            }
        }

        Node {
            id: obstacleSpawner
            property var instances: []
            property var component: Qt.createComponent("Obstacle.qml")

            function createObstacle() {
                let obstacle = component.createObject(obstacleSpawner, { "position": Qt.vector3d(0, 0, 0) })
                if (obstacle === null) {
                    console.log("Error creating obstacle")
                    return
                }
                instances.push(obstacle)
            }

            function reset() {
                instances.forEach(obstacle => { obstacle.destroy() })
                instances = []
            }
        }

        PhysicsTestCase {
            name: "character shapeHit + node removal race"
            timeoutSecs: 60
            goalReached: characterResetTimer.repeats > 8 && obstacleResetTimer.repeats > 8
        }
    }
}
