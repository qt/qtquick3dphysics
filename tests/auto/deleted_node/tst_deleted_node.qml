// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Walks the world's bodies while one of them has been deleted. A deleted node
// leaves its backend behind until a frame takes it out, so the world is stopped
// first, since nothing else clears it, and then each of the three things that
// walk every body is asked for: a new default density, debug drawing off, and a
// move to another scene. Each of them crashed.
//
// Reaching the end is the assertion. The walks are named across the top and lit
// as they are survived, so the scene can be judged by eye too.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    width: 640
    height: 480
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -981, 0)
        running: true
        forceDebugDraw: true
        typicalLength: 100
        typicalSpeed: 1000
        minimumTimestep: 15
        maximumTimestep: 15
        scene: viewport.scene
    }

    QtObject {
        id: walked
        property bool density: false
        property bool debugDraw: false
        property bool scene: false
    }

    // A step apart, so the delete the first one asks for, which is deferred,
    // has happened by the time the next one walks the bodies.
    Timer {
        interval: 300
        repeat: true
        running: true
        property int step: 0
        onTriggered: {
            switch (++step) {
            case 1:
                // Stopped, so no frame takes the removed backend out from
                // under the walks below.
                world.running = false;
                boxes.model = 2;
                break;
            case 2:
                world.defaultDensity = 0.002;
                walked.density = true;
                break;
            case 3:
                world.forceDebugDraw = false;
                walked.debugDraw = true;
                break;
            case 4:
                world.scene = elsewhere;
                walked.scene = true;
                break;
            }
        }
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 100, 600)
            clipFar: 4000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 25, 0)
            brightness: 1.5
            ambientColor: "#3a3a44"
        }

        // What the world is moved to, so that moving it means every body
        // leaves the scene it is in.
        Node {
            id: elsewhere
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -150, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(800, 40, 400)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(8, 0.4, 4)
                materials: PrincipledMaterial {
                    baseColor: "#3f8f4f"
                    roughness: 0.85
                }
            }
        }

        // The last of these is the one that gets deleted.
        Repeater3D {
            id: boxes
            model: 3
            DynamicRigidBody {
                required property int index
                position: Qt.vector3d(index * 120 - 120, 200, 0)
                collisionShapes: BoxShape {
                    extents: Qt.vector3d(60, 60, 60)
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.6, 0.6, 0.6)
                    materials: PrincipledMaterial {
                        baseColor: index === 2 ? "#c0504d" : "#4a86e8"
                        roughness: 0.5
                    }
                }
            }
        }
    }

    Row {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 12
        spacing: 24

        component Marker: Text {
            required property bool done
            color: done ? "#7ee08a" : "#9aa0b4"
            font.pixelSize: 16
        }

        Marker { text: "density"; done: walked.density }
        Marker { text: "debug draw"; done: walked.debugDraw }
        Marker { text: "scene"; done: walked.scene }
    }

    PhysicsTestCase {
        name: "giving every body a new default density"
        goalReached: walked.density
    }

    PhysicsTestCase {
        name: "taking every body's debug drawing away"
        goalReached: walked.debugDraw
    }

    PhysicsTestCase {
        name: "moving every body to another scene"
        goalReached: walked.scene
    }
}
