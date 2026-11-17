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

// GravityField acts on every body, overlapping nothing. Each field here is
// filtered to a single group, so they don't affect each other's bodies.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        // No world gravity: only the fields pull.
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
            frames++;
            // Read early, while each body is still about where it started.
            if (frames === 6) {
                falloff.near = nearCube.linearVelocity.length();
                falloff.mid = midCube.linearVelocity.length();
                falloff.far = farFalloffCube.linearVelocity.length();
            }
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

        LookAtNode {
            target: farCube
            position: Qt.vector3d(-700, 150, 200)
            PerspectiveCamera {
                clipFar: 4000
            }
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
            brightness: 1.5
            ambientColor: "#3a3a44"
            castsShadow: false
            shadowFactor: 100
        }

        component Cube: DynamicRigidBody {
            physicsMaterial: PhysicsMaterial {
                restitution: 0.0
            }
            collisionShapes: BoxShape {
                extents: Qt.vector3d(22, 22, 22)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.22, 0.22, 0.22)
                materials: PrincipledMaterial {
                    baseColor: "#4a86e8"
                    roughness: 0.5
                    metalness: 0.1
                }
            }
        }

        // Pushes along +Z, and reaches only group 1.
        GravityField {
            id: pushField
            direction: Qt.vector3d(0, 0, 1)
            gravity: 200
            filterIgnoreGroups: ~(1 << 1) // every group but 1
        }

        Cube {
            id: farCube
            position: Qt.vector3d(0, 0, 0)
            filterGroup: 1
        }

        // The same, but in a group the field ignores.
        Cube {
            id: exemptCube
            position: Qt.vector3d(-200, 0, 0)
            filterGroup: 2
        }

        // Turning on a field under a sleeping body has to wake it.
        GravityField {
            id: sleeperField
            direction: Qt.vector3d(0, 0, 1)
            gravity: 0
            filterIgnoreGroups: ~(1 << 3) // every group but 3
        }

        Cube {
            id: sleeperCube
            position: Qt.vector3d(-400, 0, 0)
            filterGroup: 3
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !sleeper.sleptFirst) {
                    sleeper.sleptFirst = true;
                    sleeperField.gravity = 200;
                }
            }
        }

        QtObject {
            id: sleeper
            property bool sleptFirst: false
        }

        // Moving a Point field off the body it sits on has to wake it. On the
        // centre there is no direction to pull in, so the body sleeps first.
        GravityField {
            id: movedField
            mode: GravityField.Point
            gravity: 200
            position: Qt.vector3d(-600, 0, 0)
            filterIgnoreGroups: ~(1 << 4) // every group but 4
        }

        Cube {
            id: movedCube
            position: Qt.vector3d(-600, 0, 0)
            filterGroup: 4
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !movedSleeper.sleptFirst) {
                    movedSleeper.sleptFirst = true;
                    movedField.position = Qt.vector3d(-600, 0, 400);
                }
            }
        }

        QtObject {
            id: movedSleeper
            property bool sleptFirst: false
        }

        // Changing a value the current mode does not read must not wake anything,
        // or an animated one keeps the whole scene awake. Both fields sit on their
        // body, so there is no force either way. Wakes are counted rather than
        // sleep sampled, since a body woken for nothing falls straight back asleep.
        component SleepCounter: QtObject {
            property bool everSlept: false
            property int wakeUps: 0
            function observe(sleeping) {
                if (sleeping)
                    everSlept = true;
                else if (everSlept)
                    ++wakeUps;
            }
        }

        // Point gravity does not read the direction.
        GravityField {
            id: turningDirectionField
            mode: GravityField.Point
            position: Qt.vector3d(-800, 0, 0)
            gravity: 200
            direction: Qt.vector3d(Math.cos(turningDirectionField.phase),
                                   Math.sin(turningDirectionField.phase), 0)
            filterIgnoreGroups: ~(1 << 5) // every group but 5

            property real phase: 0
            NumberAnimation on phase {
                from: 0; to: 2 * Math.PI
                duration: 1000
                loops: Animation.Infinite
                running: true
            }
        }

        SleepCounter { id: directionSleep }

        Cube {
            id: directionCube
            position: Qt.vector3d(-800, 0, 0)
            filterGroup: 5
            onIsSleepingChanged: (sleeping) => directionSleep.observe(sleeping)
        }

        // Directional gravity does not read the falloff.
        GravityField {
            id: changingFalloffField
            direction: Qt.vector3d(0, 0, 1)
            gravity: 0
            position: Qt.vector3d(-1000, 0, 0)
            filterIgnoreGroups: ~(1 << 6) // every group but 6

            NumberAnimation on unitDistance {
                from: 1; to: 500
                duration: 1000
                loops: Animation.Infinite
                running: true
            }
        }

        SleepCounter { id: falloffSleep }

        Cube {
            id: falloffCube
            position: Qt.vector3d(-1000, 0, 0)
            filterGroup: 6
            onIsSleepingChanged: (sleeping) => falloffSleep.observe(sleeping)
        }

        // Changing a value the current mode does read has to wake what is asleep
        // under it.

        // Directional gravity reads the direction.
        GravityField {
            id: reaimedField
            direction: Qt.vector3d(0, 0, -1)
            gravity: 200
            filterIgnoreGroups: ~(1 << 7) // every group but 7
        }

        // Something to rest against, so the body can sleep while pushed.
        StaticRigidBody {
            position: Qt.vector3d(-1200, 0, -60)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 200, 20)
            }
        }

        Cube {
            id: reaimedCube
            position: Qt.vector3d(-1200, 0, 0)
            filterGroup: 7
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !reaimed.sleptFirst) {
                    reaimed.sleptFirst = true;
                    reaimedField.direction = Qt.vector3d(0, 0, 1);
                }
            }
        }

        QtObject {
            id: reaimed
            property bool sleptFirst: false
        }

        // Point gravity reads the falloff. Two equal opposing fields cancel, so the
        // body sleeps between them until one changes.
        GravityField {
            id: nearFalloffField
            mode: GravityField.Point
            position: Qt.vector3d(-1400, 0, -300)
            gravity: 200
            unitDistance: 100
            filterIgnoreGroups: ~(1 << 8) // every group but 8
        }

        GravityField {
            id: farFalloffField
            mode: GravityField.Point
            position: Qt.vector3d(-1400, 0, 300)
            gravity: 200
            unitDistance: 100
            filterIgnoreGroups: ~(1 << 8) // every group but 8
        }

        Cube {
            id: balancedCube
            position: Qt.vector3d(-1400, 0, 0)
            filterGroup: 8
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !balanced.sleptFirst) {
                    balanced.sleptFirst = true;
                    nearFalloffField.unitDistance = 200;
                }
            }
        }

        QtObject {
            id: balanced
            property bool sleptFirst: false
        }

        // Half at half unitDistance inside it, a quarter at twice the distance
        // beyond it. With no damping and a fixed step, velocities are in
        // proportion to the accelerations, and the gravity is weak enough that
        // the bodies are still about where they started when they are read.
        GravityField {
            mode: GravityField.Point
            position: Qt.vector3d(-1700, 0, 600)
            gravity: 200
            unitDistance: 100
            filterIgnoreGroups: ~(1 << 9) // every group but 9
        }

        Cube {
            id: nearCube
            position: Qt.vector3d(-1700, 0, 650)
            filterGroup: 9
        }

        Cube {
            id: midCube
            position: Qt.vector3d(-1700, 200, 600)
            filterGroup: 9
        }

        Cube {
            id: farFalloffCube
            position: Qt.vector3d(-1300, 0, 600)
            filterGroup: 9
        }

        QtObject {
            id: falloff
            property real near: 0
            property real mid: 0
            property real far: 0
        }

        GravityField {
            direction: Qt.vector3d(0, -1, 0)
            gravity: 200
            filterIgnoreGroups: ~(1 << 10) // every group but 10
        }

        CharacterController {
            id: fieldCharacter
            position: Qt.vector3d(-1900, 0, 0)
            filterGroup: 10
            collisionShapes: CapsuleShape {
                height: 40
                diameter: 20
            }
        }

        PhysicsTestCase {
            name: "GravityField acts on a body it does not overlap"
            goalReached: farCube.position.z > 100
        }

        PhysicsTestCase {
            name: "GravityField leaves a body filtered out of it alone"
            goalReached: world.frames >= 130 && Math.abs(exemptCube.position.z) < 1
        }

        PhysicsTestCase {
            name: "GravityField wakes a sleeping body when its field changes"
            goalReached: sleeper.sleptFirst && sleeperCube.position.z > 100
        }

        PhysicsTestCase {
            name: "GravityField wakes a sleeping body when it moves in Point mode"
            goalReached: movedSleeper.sleptFirst && movedCube.position.z > 100
        }

        PhysicsTestCase {
            name: "GravityField in Point mode lets a body sleep through an animated direction"
            goalReached: world.frames >= 200 && directionSleep.everSlept
                         && directionSleep.wakeUps === 0
        }

        PhysicsTestCase {
            name: "GravityField in Directional mode lets a body sleep through an animated unitDistance"
            goalReached: world.frames >= 200 && falloffSleep.everSlept
                         && falloffSleep.wakeUps === 0
        }

        PhysicsTestCase {
            name: "GravityField in Directional mode wakes a sleeping body when its direction changes"
            goalReached: reaimed.sleptFirst && reaimedCube.position.z > 100
        }

        PhysicsTestCase {
            name: "GravityField in Point mode falls off linearly toward the centre inside unitDistance"
            goalReached: falloff.mid > 0 && Math.abs(falloff.near / falloff.mid - 2) < 0.1
        }

        PhysicsTestCase {
            name: "GravityField in Point mode falls off with the square of the distance"
            goalReached: falloff.far > 0 && Math.abs(falloff.mid / falloff.far - 4) < 0.2
        }

        PhysicsTestCase {
            name: "GravityField pulls a CharacterController"
            goalReached: fieldCharacter.position.y < -100
        }

        PhysicsTestCase {
            name: "GravityField in Point mode wakes a sleeping body when its unitDistance changes"
            goalReached: balanced.sleptFirst && balancedCube.position.z < -50
        }
    }
}
