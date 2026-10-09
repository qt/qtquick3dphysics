// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

// filterGroup and filterIgnoreGroups on a CharacterController. A controller
// moves through scene queries of its own rather than through the simulation,
// so what it is stopped by is filtered separately from what the bodies and
// triggers paired with its actor see, and the two are tested separately here:
// walking through a wall from either side of the filter, a wall that stops an
// unfiltered character until the character's or the wall's filter is changed
// at runtime, a body falling
// through a character, a trigger that does not count a character, and a
// character walking through another character.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -981, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
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
            position: Qt.vector3d(1700, 300, -2800)
            eulerRotation: Qt.vector3d(-5, 180, 0)
            clipFar: 8000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
        }

        // A wall across the walkers' way. Group 2 unless told otherwise.
        component Wall: StaticRigidBody {
            filterGroup: 2
            collisionShapes: BoxShape {
                extents: Qt.vector3d(20, 200, 200)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.2, 2, 2)
                materials: PrincipledMaterial { baseColor: "#7a4f5a" }
            }
        }

        // No gravity of its own, so nothing has to hold it up and the scene
        // needs no floor: a filtered wall is the only thing in its way.
        component Character: CharacterController {
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.2, 0.6, 0.2)
                materials: PrincipledMaterial { baseColor: "#e8a24a" }
            }
        }

        // Ignoring the wall's group: walks through it.
        Character {
            id: ignoring
            position: Qt.vector3d(0, 0, 0)
            movement: Qt.vector3d(100, 0, 0)
            filterGroup: 1
            filterIgnoreGroups: 1 << 2
        }
        Wall { position: Qt.vector3d(150, 0, 0) }

        // In a group the wall ignores: walks through it.
        Character {
            id: ignored
            position: Qt.vector3d(400, 0, 0)
            movement: Qt.vector3d(100, 0, 0)
            filterGroup: 3
        }
        Wall {
            position: Qt.vector3d(550, 0, 0)
            filterIgnoreGroups: 1 << 3
        }

        // Neither: stopped by the wall, until it is told to ignore the wall's
        // group with the simulation running.
        Character {
            id: blocked
            position: Qt.vector3d(800, 0, 0)
            movement: Qt.vector3d(100, 0, 0)
            filterGroup: 1
        }
        Wall { position: Qt.vector3d(950, 0, 0) }

        // The same, until the wall is told to ignore the character's group.
        Character {
            id: pressing
            position: Qt.vector3d(3200, 0, 0)
            movement: Qt.vector3d(100, 0, 0)
            filterGroup: 1
        }
        Wall {
            id: yielding
            position: Qt.vector3d(3350, 0, 0)
        }

        // A body that ignores the character's group falls through it. This is
        // the simulation's own filtering, reading the character's groups off
        // its actor, rather than the character's.
        Character {
            id: post
            position: Qt.vector3d(1200, 0, 0)
            filterGroup: 4
        }
        DynamicRigidBody {
            id: falling
            position: Qt.vector3d(1200, 100, 0)
            filterIgnoreGroups: 1 << 4
            collisionShapes: SphereShape { diameter: 20 }
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(0.2, 0.2, 0.2)
                materials: PrincipledMaterial { baseColor: "#4a90e8" }
            }
        }

        // Two triggers around two characters that report to triggers. One
        // trigger ignores the character's group and counts nothing; the other
        // counts the character, which is what shows the first one is not
        // merely failing to count characters at all.
        Character {
            id: hidden
            position: Qt.vector3d(1600, 0, 0)
            filterGroup: 5
            sendTriggerReports: true
        }
        TriggerBody {
            id: blind
            position: Qt.vector3d(1600, 0, 0)
            filterIgnoreGroups: 1 << 5
            collisionShapes: BoxShape { extents: Qt.vector3d(100, 100, 100) }
        }

        Character {
            id: visible
            position: Qt.vector3d(2000, 0, 0)
            filterGroup: 5
            sendTriggerReports: true
        }
        TriggerBody {
            id: seeing
            position: Qt.vector3d(2000, 0, 0)
            collisionShapes: BoxShape { extents: Qt.vector3d(100, 100, 100) }
        }

        // Character against character, which PhysX decides separately from
        // character against shape: one that ignores the other's group walks
        // through it, and one that does not is stopped.
        Character {
            id: dodging
            position: Qt.vector3d(2400, 0, 0)
            movement: Qt.vector3d(100, 0, 0)
            filterGroup: 6
            filterIgnoreGroups: 1 << 7
        }
        Character {
            position: Qt.vector3d(2550, 0, 0)
            filterGroup: 7
        }

        Character {
            id: bumping
            position: Qt.vector3d(2800, 0, 0)
            movement: Qt.vector3d(100, 0, 0)
            filterGroup: 6
        }
        Character {
            position: Qt.vector3d(2950, 0, 0)
            filterGroup: 8
        }

        PhysicsTestCase {
            name: "CharacterController ignoring a wall's group walks through it"
            goalReached: ignoring.position.x > 250
        }

        PhysicsTestCase {
            name: "CharacterController in a group the wall ignores walks through it"
            goalReached: ignored.position.x > 650
        }

        PhysicsTestCase {
            name: "CharacterController is stopped by an unfiltered wall"
            goalReached: blocked.collisions !== CharacterController.None
            function test_1_still_before_the_wall() {
                verify(blocked.position.x < 950)
            }
            function test_2_start_ignoring_the_wall() {
                blocked.filterIgnoreGroups = 1 << 2
            }
        }

        // Goes after the one above, which changes the filter: a test case runs
        // once its goal is reached, and this goal cannot be before that.
        PhysicsTestCase {
            // Times out if a filter changed while running has no effect on a
            // character.
            name: "CharacterController filter changed while running takes effect"
            goalReached: blocked.position.x > 1050
        }

        PhysicsTestCase {
            name: "CharacterController is stopped by a wall that does not ignore it"
            goalReached: pressing.collisions !== CharacterController.None
            function test_1_still_before_the_wall() {
                verify(pressing.position.x < 3350)
            }
            function test_2_wall_starts_ignoring_the_character() {
                yielding.filterIgnoreGroups = 1 << 1
            }
        }

        // Goes after the one above, as the pair before it.
        PhysicsTestCase {
            // Times out if a character keeps being stopped by a static body
            // whose filter changed while it stood against it.
            name: "Static body filter changed while running takes effect on a CharacterController"
            goalReached: pressing.position.x > 3450
        }

        PhysicsTestCase {
            name: "DynamicRigidBody ignoring a CharacterController's group falls through it"
            goalReached: falling.position.y < -300
        }

        PhysicsTestCase {
            name: "TriggerBody ignoring a CharacterController's group does not count it"
            goalReached: seeing.collisionCount === 1 && blind.collisionCount === 0
        }

        PhysicsTestCase {
            name: "CharacterController ignoring another's group walks through it"
            goalReached: dodging.position.x > 2650
        }

        PhysicsTestCase {
            name: "CharacterController is stopped by an unfiltered CharacterController"
            goalReached: bumping.collisions !== CharacterController.None
        }
    }
}
