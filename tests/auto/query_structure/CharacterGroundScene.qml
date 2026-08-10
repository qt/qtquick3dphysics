// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Physics

// A CharacterController falls onto a static floor while a batch of unrelated static
// obstacles is repeatedly added and removed elsewhere in the scene, simulating runtime
// chunk streaming. CharacterController's ground detection is implemented internally by
// PhysX as a scene overlap query against static geometry, so this is the actual code path
// PhysicsWorld.staticQueryStructure and PhysicsWorld.dynamicQueryStructure affects (it has no effect on rigid-body
// contact/collision detection during simulation).
View3D {
    id: viewport
    property alias staticQueryStructure: world.staticQueryStructure
    property alias dynamicQueryStructure: world.dynamicQueryStructure

    property alias collisions: character.collisions

    environment: SceneEnvironment {
        clearColor: "#d6dbdf"
        backgroundMode: SceneEnvironment.Color
    }

    PerspectiveCamera {
        position: Qt.vector3d(0, 5, 15)
        eulerRotation: Qt.vector3d(-20, 0, 0)
        clipFar: 100
        clipNear: 0.01
    }

    DirectionalLight {
        eulerRotation.x: -45
        eulerRotation.y: 45
        castsShadow: false
        brightness: 1
    }

    PhysicsWorld {
        id: world
        scene: viewport.scene
        gravity: Qt.vector3d(0, -9.81, 0)
        running: true
        typicalLength: 1
        typicalSpeed: 10
    }

    StaticRigidBody {
        position: Qt.vector3d(0, -1, 0)
        collisionShapes: BoxShape { extents: Qt.vector3d(20, 1, 20) }
        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.2, 0.01, 0.2)
            materials: PrincipledMaterial { baseColor: "green" }
        }
    }

    CharacterController {
        id: character
        position: Qt.vector3d(0, 5, 0)
        gravity: world.gravity
        collisionShapes: CapsuleShape {
            height: 1
            diameter: 1
        }
        Model {
            eulerRotation.z: 90
            scale: Qt.vector3d(0.01, 0.01, 0.01)
            geometry: CapsuleGeometry {}
            materials: PrincipledMaterial { baseColor: "blue" }
        }
    }

    Node { id: obstacleRoot }

    Component {
        id: staticObstacleComponent
        StaticRigidBody {
            collisionShapes: BoxShape { extents: Qt.vector3d(1, 1, 1) }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.01, 0.01, 0.01)
                materials: PrincipledMaterial { baseColor: "gray" }
            }
        }
    }

    Component {
        id: dynamicObstacleComponent
        DynamicRigidBody {
            collisionShapes: BoxShape { extents: Qt.vector3d(1, 1, 1) }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.01, 0.01, 0.01)
                materials: PrincipledMaterial { baseColor: "red" }
            }
        }
    }

    // Periodically spawns and destroys a batch of static obstacles so that static
    // actors keep getting added and removed at runtime while the ground-detection
    // check above is being exercised.
    Timer {
        interval: 100
        running: true
        repeat: true
        property var obstacles: []
        onTriggered: {

            obstacles.forEach(o => o.destroy())
            obstacles = []
            for (let i = 0; i < 20; ++i) {
                const obj = staticObstacleComponent.createObject(obstacleRoot, {
                    position: Qt.vector3d(Math.floor((Math.random() - 0.5) * 20) ,
                                           Math.floor((Math.random() ) * 10),
                                           Math.floor((Math.random() - 0.5) * 20))
                })
                obstacles.push(obj)
            }

            for (let j = 0; j < 20; ++j) {
                const obj = dynamicObstacleComponent.createObject(obstacleRoot, {
                    position: Qt.vector3d(Math.floor((Math.random() - 0.5) * 20),
                                           Math.floor((Math.random()) * 10),
                                           Math.floor((Math.random() - 0.5) * 20))
                })
                obstacles.push(obj)
            }
        }
    }
}
