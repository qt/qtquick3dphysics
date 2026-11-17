// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick3D.Physics.Helpers
import QtQuick3D.Physics.TestUtils

// Characters walking on something, and the speed they keep when the gravity
// that built it stops. All have midAirControl off, so the movement they walked
// off with is part of what carries them.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        // No world gravity: the characters have their own, or a shaped field's.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
        property int frames: 0
        onFrameDone: {
            world.frames++;
            if (!walking.weightless && world.frames >= 80) {
                walking.markX = walker.position.x;
                walker.gravity = Qt.vector3d(0, 0, 0);
                walking.weightless = true;
            }
            if (walking.weightless)
                walking.frames++;
            // Grabbed well into the fall, then climbing.
            if (!grab.held && grabber.position.y < -300) {
                grab.held = true;
                grab.markY = grabber.position.y;
                grabber.gravity = Qt.vector3d(0, 0, 0);
                grabber.movement = Qt.vector3d(0, 100, 0);
            }
            if (grab.held)
                grab.frames++;
            // Measured from where it leaves the shaped field.
            if (!ledge.free && edgeWalker.position.y < -250) {
                ledge.free = true;
                ledge.markX = edgeWalker.position.x;
            }
            if (ledge.free)
                ledge.frames++;
        }
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        Node {
            id: focus
            position: Qt.vector3d(350, -350, 0)
        }

        LookAtNode {
            target: focus
            position: Qt.vector3d(350, 250, -2300)
            PerspectiveCamera {
                clipFar: 8000
            }
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
            brightness: 1.5
            ambientColor: "#3a3a44"
            castsShadow: false
            shadowFactor: 100
        }

        component Body: Model {
            source: "#Cylinder"
            scale: Qt.vector3d(0.2, 0.6, 0.2)
            materials: PrincipledMaterial {
                baseColor: "#e8a24a"
                roughness: 0.6
            }
        }

        component Floor: Model {
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "#4f5a7a"
                roughness: 0.9
            }
        }

        // Gravity set to zero while walking: it keeps walking at the movement's
        // speed, neither doubled nor stopped.
        StaticRigidBody {
            position: Qt.vector3d(-700, -100, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1200, 40, 400)
            }
            Floor {
                scale: Qt.vector3d(12, 0.4, 4)
            }
        }

        CharacterController {
            id: walker
            position: Qt.vector3d(-900, -20, 0)
            gravity: Qt.vector3d(0, -981, 0)
            midAirControl: false
            movement: Qt.vector3d(100, 0, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        QtObject {
            id: walking
            property bool weightless: false
            property real markX: 0
            property int frames: 0
        }

        // Gravity set to zero in mid-air, as when grabbing a ladder: it stops dead
        // and climbs, rather than coasting on.
        CharacterController {
            id: grabber
            position: Qt.vector3d(-1600, 0, 0)
            gravity: Qt.vector3d(0, -981, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        QtObject {
            id: grab
            property bool held: false
            property real markY: 0
            property int frames: 0
        }

        // Walking off a ledge inside a shaped field and out of its bottom: the movement is
        // already in the coast velocity and must not be applied twice.
        GravityField {
            position: Qt.vector3d(700, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(600, -100, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 40, 200)
            }
            Floor {
                scale: Qt.vector3d(2, 0.4, 2)
            }
        }

        CharacterController {
            id: edgeWalker
            position: Qt.vector3d(550, -20, 0)
            midAirControl: false
            movement: Qt.vector3d(100, 0, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        QtObject {
            id: ledge
            property bool free: false
            property real markX: 0
            property int frames: 0
        }

        // The same, with a wall across the drift below the ledge: it stops the
        // sideways part of the coast but must not strand the character.
        GravityField {
            position: Qt.vector3d(1700, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(1600, -100, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 40, 200)
            }
            Floor {
                scale: Qt.vector3d(2, 0.4, 2)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(1950, -700, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 1000, 400)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.2, 10, 4)
                materials: PrincipledMaterial {
                    baseColor: "#7a4f5a"
                    roughness: 0.9
                }
            }
        }

        CharacterController {
            id: brushWalker
            position: Qt.vector3d(1550, -20, 0)
            midAirControl: false
            movement: Qt.vector3d(100, 0, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        // 20 steps of 15 ms at 100 per second is 30. Coasting on the fall would put
        // it hundreds below.
        PhysicsTestCase {
            name: "CharacterController stops dead when its gravity is set to zero in mid-air"
            goalReached: grab.frames >= 20
                         && grabber.position.y - grab.markY > 20
                         && grabber.position.y - grab.markY < 40
        }

        // 30 expected; the movement applied twice would pass 50, dropped would be 0.
        PhysicsTestCase {
            name: "CharacterController keeps walking when its gravity is set to zero"
            goalReached: walking.frames >= 20
                         && walker.position.x - walking.markX > 20
                         && walker.position.x - walking.markX < 40
        }

        // 30 expected; the movement counted twice would be 60.
        PhysicsTestCase {
            name: "CharacterController leaving a shaped field in mid-air keeps one movement"
            goalReached: ledge.frames >= 20
                         && edgeWalker.position.x - ledge.markX > 15
                         && edgeWalker.position.x - ledge.markX < 45
        }

        PhysicsTestCase {
            name: "CharacterController coasting sideways is not grounded by a wall"
            goalReached: brushWalker.position.y < -700
        }
    }
}
