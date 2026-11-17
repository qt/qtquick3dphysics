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

// A GravityField coming and going while the world runs: created and destroyed,
// and moved into the scene. Each acts on one group only. Like any other
// physics node, a field stays in the world once it has joined it, so moving
// one out of the scene again is not covered.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene

        property int frames: 0
        property var createdField: null

        onFrameDone: {
            frames++;

            if (frames === 40) {
                createdField = Qt.createQmlObject(`
                    import QtQuick3D.Physics
                    GravityField {
                        direction: Qt.vector3d(1, 0, 0)
                        gravity: 200
                        filterIgnoreGroups: ~(1 << 1)
                    }`, viewport.scene);
            } else if (frames === 80) {
                created.pushed = createdCube.linearVelocity.x;
                createdField.destroy();
            } else if (frames === 90) {
                created.after = createdCube.linearVelocity.x;
            } else if (frames === 130) {
                created.later = createdCube.linearVelocity.x;
            }

            // Moved in once the body is asleep, so the field has to wake it.
            if (moved.inAt === 0 && movedCube.isSleeping) {
                moved.inAt = frames;
                moved.restingVelocity = movedCube.linearVelocity.length();
                movedField.parent = viewport.scene;
            } else if (moved.inAt > 0 && frames - moved.inAt === 40) {
                moved.pushed = movedCube.linearVelocity.x;
            }
        }
    }

    // Outside the scene, so a field in it is in no world.
    Node {
        id: offstage

        GravityField {
            id: movedField
            direction: Qt.vector3d(1, 0, 0)
            gravity: 200
            filterIgnoreGroups: ~(1 << 2)
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
            position: Qt.vector3d(0, 100, 800)
            clipFar: 4000
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

        Cube {
            id: createdCube
            position: Qt.vector3d(0, 0, 0)
            filterGroup: 1
        }

        Cube {
            id: movedCube
            position: Qt.vector3d(0, 100, 0)
            filterGroup: 2
        }

        // Velocities when the field went away, shortly after, and well after.
        QtObject {
            id: created
            property real pushed: 0
            property real after: 0
            property real later: 0
        }

        QtObject {
            id: moved
            property int inAt: 0
            // Velocity just before the field arrives.
            property real restingVelocity: -1
            property real pushed: 0
        }

        PhysicsTestCase {
            name: "GravityField created at runtime acts, and stops when destroyed"
            goalReached: world.frames > 130 && created.pushed > 50
                         && Math.abs(created.later - created.after) < 0.01
        }

        PhysicsTestCase {
            name: "GravityField outside the scene does not act"
            goalReached: moved.inAt > 0 && moved.restingVelocity === 0
        }

        PhysicsTestCase {
            name: "GravityField moved into the scene acts"
            goalReached: moved.inAt > 0 && moved.pushed > 50
        }
    }
}
