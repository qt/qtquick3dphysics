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

// What a shaped field does to a CharacterController, which takes its gravity in
// getDisplacement() rather than as a force. Characters walking on something are
// in tst_gravityfield_walking.qml.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        // No world gravity: only the shaped fields pull.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
        onFrameDone: {
            world.frames++;
            // Counted in steps, since one contribution is added per step.
            if (teleporting.frames >= 120)
                teleporting.active = false;
            if (teleporting.active) {
                teleporter.teleport(Qt.vector3d(700, 0, 0));
                teleporting.frames++;
            } else if (teleporting.frames > 0) {
                teleporting.freeFrames++;
            }
            // Sent back on first contact with the wall, which it can only follow once
            // the coast has ended.
            if (!drift.hitWall && drifter.collisions !== CharacterController.None) {
                drift.hitWall = true;
                drift.markX = drifter.position.x;
                drifter.movement = Qt.vector3d(-100, 0, 0);
            }
            if (drift.hitWall)
                drift.frames++;
        }
        property int frames: 0
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
            position: Qt.vector3d(1480, -300, 0)
        }

        LookAtNode {
            target: focus
            position: Qt.vector3d(1480, 150, -2500)
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

        // No gravity of its own: once out of the shaped field, it keeps the speed it
        // built up there rather than stopping dead.
        GravityField {
            position: Qt.vector3d(0, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        CharacterController {
            id: coaster
            position: Qt.vector3d(0, 150, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        // Teleported every frame while inside a shaped field. The gravity contributed on
        // those frames must be dropped, not saved up for the first frame after.
        GravityField {
            position: Qt.vector3d(700, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        CharacterController {
            id: teleporter
            position: Qt.vector3d(700, 0, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        QtObject {
            id: teleporting
            property bool active: true
            property int frames: 0
            property int freeFrames: 0
        }

        // Coasting down past a wall it is held against: the side contact must not
        // end the coast.
        GravityField {
            position: Qt.vector3d(1500, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(1530, -500, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 1600, 200)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.2, 16, 2)
                materials: PrincipledMaterial {
                    baseColor: "#7a4f5a"
                    roughness: 0.9
                }
            }
        }

        CharacterController {
            id: brusher
            position: Qt.vector3d(1500, 150, 0)
            movement: Qt.vector3d(30, 0, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        // Sideways gravity, so the coast after leaving the shaped field is purely
        // sideways and a wall is the only thing that can end it.
        GravityField {
            position: Qt.vector3d(2200, 0, 0)
            direction: Qt.vector3d(1, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(2560, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 400, 400)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.2, 4, 4)
                materials: PrincipledMaterial {
                    baseColor: "#7a4f5a"
                    roughness: 0.9
                }
            }
        }

        CharacterController {
            id: drifter
            position: Qt.vector3d(2050, 0, 0)
            midAirControl: false
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        QtObject {
            id: drift
            property bool hitWall: false
            property real markX: 0
            property int frames: 0
        }

        // Filtered out of the shaped field from either side; the third character is not,
        // and falls.
        GravityField {
            position: Qt.vector3d(2900, 0, 0)
            gravity: 200
            filterGroup: 6
            filterIgnoreGroups: 1 << 5
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        CharacterController {
            id: ignoredByShapedField
            position: Qt.vector3d(2840, 0, 0)
            filterGroup: 5
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        CharacterController {
            id: ignoringShapedField
            position: Qt.vector3d(2900, 0, 0)
            filterIgnoreGroups: 1 << 6
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        CharacterController {
            id: unfiltered
            position: Qt.vector3d(2960, 0, 0)
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Body { }
        }

        PhysicsTestCase {
            name: "CharacterController keeps its speed after leaving a GravityField"
            goalReached: coaster.position.y < -800
        }

        PhysicsTestCase {
            name: "GravityField gravity does not pile up on a teleported CharacterController"
            // Under the shaped field's gravity alone it falls about 2 in this time;
            // with the whole stay's worth at once, past 20.
            goalReached: teleporting.freeFrames >= 15 && teleporter.position.y > -10
        }

        PhysicsTestCase {
            name: "CharacterController coasting straight down past a wall keeps falling"
            goalReached: brusher.position.y < -800
        }

        PhysicsTestCase {
            name: "CharacterController coasting sideways is stopped by a wall"
            goalReached: drift.frames >= 20 && drifter.position.x < drift.markX - 20
        }

        PhysicsTestCase {
            name: "GravityField with shapes leaves a filtered CharacterController alone"
            goalReached: unfiltered.position.y < -100
                         && Math.abs(ignoredByShapedField.position.y) < 1
                         && Math.abs(ignoringShapedField.position.y) < 1
        }
    }
}
