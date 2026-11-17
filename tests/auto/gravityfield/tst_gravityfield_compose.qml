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

// Shaped fields adding up with each other and with world gravity, and shaped fields
// leaving a filtered DynamicRigidBody alone. With no damping and a fixed
// step, velocities are in proportion to the accelerations.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -100, 0)
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
            if (frames === 30) {
                compose.both = bothCube.linearVelocity;
                compose.one = oneCube.linearVelocity;
                compose.ignoring = ignoringCube.linearVelocity;
                compose.ignored = ignoredCube.linearVelocity;
                compose.unfiltered = unfilteredCube.linearVelocity;
                compose.done = true;
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
            position: Qt.vector3d(500, 200, 1500)
            clipFar: 6000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
        }

        component Cube: DynamicRigidBody {
            collisionShapes: BoxShape {
                extents: Qt.vector3d(22, 22, 22)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.22, 0.22, 0.22)
                materials: PrincipledMaterial {
                    baseColor: "#4a86e8"
                }
            }
        }

        component PushShapedField: GravityField {
            direction: Qt.vector3d(1, 0, 0)
            gravity: 100
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 400, 400)
            }
        }

        // Two shaped fields around one body, one shaped field around the other.
        PushShapedField { position: Qt.vector3d(0, 0, 0) }
        PushShapedField { position: Qt.vector3d(0, 0, 0) }
        Cube { id: bothCube; position: Qt.vector3d(0, 0, 0) }

        PushShapedField { position: Qt.vector3d(0, 0, -600) }
        Cube { id: oneCube; position: Qt.vector3d(0, 0, -600) }

        // Filtered out from either side, and a body beside them that is not.
        PushShapedField {
            position: Qt.vector3d(1000, 0, 0)
            filterGroup: 6
            filterIgnoreGroups: 1 << 5
        }

        Cube {
            id: ignoredCube
            position: Qt.vector3d(940, 0, 0)
            filterGroup: 5
        }

        Cube {
            id: ignoringCube
            position: Qt.vector3d(1000, 0, 0)
            filterIgnoreGroups: 1 << 6
        }

        Cube {
            id: unfilteredCube
            position: Qt.vector3d(1060, 0, 0)
        }

        QtObject {
            id: compose
            property bool done: false
            property vector3d both
            property vector3d one
            property vector3d ignored
            property vector3d ignoring
            property vector3d unfiltered
        }

        PhysicsTestCase {
            name: "GravityFields add up"
            goalReached: compose.done && compose.one.x > 0
                         && Math.abs(compose.both.x / compose.one.x - 2) < 0.05
        }

        // Shaped fields push along X; the world pulls along Y, the same for both.
        PhysicsTestCase {
            name: "GravityField with shapes adds to the world's gravity"
            goalReached: compose.done && compose.one.y < -40
                         && Math.abs(compose.both.y - compose.one.y) < 0.01
        }

        PhysicsTestCase {
            name: "GravityField with shapes leaves a filtered DynamicRigidBody alone"
            goalReached: compose.done && compose.unfiltered.x > 20
                         && compose.ignored.x === 0 && compose.ignoring.x === 0
        }
    }
}
