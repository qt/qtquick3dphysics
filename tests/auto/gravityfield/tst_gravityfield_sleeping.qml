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

// Moving a Point shaped field changes its gravity and wakes the bodies inside;
// spinning it does not. Each body sits on the centre, where there is no
// force, so only waking can move it.
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
        property int frames: 0
        onFrameDone: frames++
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
            target: spinShapedField
            position: Qt.vector3d(-900, 300, 900)
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

        component Cube: DynamicRigidBody {
            physicsMaterial: PhysicsMaterial {
                restitution: 0.0
            }
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.4, 0.4, 0.4)
                materials: PrincipledMaterial {
                    baseColor: "#4a86e8"
                    roughness: 0.5
                    metalness: 0.1
                }
            }
        }

        // Spinning in place: the body inside must be left to sleep.
        GravityField {
            id: spinShapedField
            mode: GravityField.Point
            position: Qt.vector3d(0, 0, 0)
            gravity: 200
            eulerRotation: Qt.vector3d(0, spinShapedField.spin, 0)
            collisionShapes: SphereShape {
                diameter: 600
            }

            property real spin: 0
            NumberAnimation on spin {
                from: 0; to: 360
                duration: 1000
                loops: Animation.Infinite
                running: true
            }
        }

        // Wakes are counted rather than sleep sampled, since a body woken for
        // nothing falls straight back asleep.
        QtObject {
            id: spinSleep
            property bool everSlept: false
            property int wakeUps: 0
            function observe(sleeping) {
                if (sleeping)
                    everSlept = true;
                else if (everSlept)
                    ++wakeUps;
            }
        }

        Cube {
            id: spinCube
            position: Qt.vector3d(0, 0, 0)
            onIsSleepingChanged: (sleeping) => spinSleep.observe(sleeping)
        }

        GravityField {
            id: movedShapedField
            mode: GravityField.Point
            position: Qt.vector3d(0, 0, -3000)
            gravity: 200
            collisionShapes: SphereShape {
                diameter: 1200
            }
        }

        Cube {
            id: movedCube
            position: Qt.vector3d(0, 0, -3000)
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !moved.sleptFirst) {
                    moved.sleptFirst = true;
                    movedShapedField.position = Qt.vector3d(0, 0, -2600);
                }
            }
        }

        QtObject {
            id: moved
            property bool sleptFirst: false
        }

        PhysicsTestCase {
            name: "GravityField with shapes in Point mode lets a body sleep while it spins"
            goalReached: world.frames >= 200 && spinSleep.everSlept && spinSleep.wakeUps === 0
        }

        PhysicsTestCase {
            name: "GravityField with shapes in Point mode wakes a sleeping body when it moves"
            goalReached: moved.sleptFirst && movedCube.position.z > -2900
        }
    }
}
