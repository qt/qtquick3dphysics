// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Tests that a leave and an enter reported in the same trigger callback are each
// processed with their own status.
//
// Teleporting the sphere from one volume into the other in a single step puts an
// eNOTIFY_TOUCH_LOST and an eNOTIFY_TOUCH_FOUND pair in the same batch. Either
// can come first, so each direction is a case of its own. Each volume lights up
// while it holds the sphere.

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    id: root

    width: 640
    height: 480
    visible: true

    PhysicsWorld {
        id: world
        // No gravity, so the sphere only moves when the test teleports it.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 1
        typicalSpeed: 10
        minimumTimestep: 16
        maximumTimestep: 16
        scene: viewport.scene
    }

    readonly property vector3d leftSeat: Qt.vector3d(-5, 0, 0)
    readonly property vector3d rightSeat: Qt.vector3d(5, 0, 0)

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 3, 18)
            eulerRotation.x: -8
            clipFar: 100
            clipNear: 0.01
        }

        DirectionalLight {
            eulerRotation.x: -40
            eulerRotation.y: 30
        }

        component Volume: TriggerBody {
            id: volume
            property color tint: "#4488ff"
            readonly property bool occupied: volume.collisionCount > 0

            collisionShapes: BoxShape {
                extents: Qt.vector3d(3, 3, 3)
            }

            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.03, 0.03, 0.03)
                materials: PrincipledMaterial {
                    baseColor: volume.tint
                    opacity: volume.occupied ? 0.55 : 0.15
                    lighting: PrincipledMaterial.NoLighting
                }
            }
        }

        Volume {
            id: boxLeft
            position: root.leftSeat
            tint: "#4488ff"

            // The sphere starts in here, so the first enter is on its own in the
            // batch and only kicks the cycle off.
            property int enters: 0

            onBodyEntered: (body) => {
                enters++;
                if (enters === 1)
                    body.reset(root.rightSeat, Qt.vector3d(0, 0, 0));
                else
                    settleLeft.restart();
            }
        }

        Volume {
            id: boxRight
            position: root.rightSeat
            tint: "#ff9a2e"

            onBodyEntered: (body) => { settleRight.restart(); }
        }

        DynamicRigidBody {
            id: sphere
            position: root.leftSeat
            sendTriggerReports: true

            collisionShapes: SphereShape {
                diameter: 1
            }

            Model {
                source: "#Sphere"
                scale: Qt.vector3d(0.01, 0.01, 0.01)
                materials: PrincipledMaterial {
                    baseColor: "#e8e8e8"
                    roughness: 0.4
                }
            }
        }

        QtObject {
            id: crossed
            property bool toRight: false
            property bool toLeft: false
        }

        // Judged after the arrival so the whole batch has been handled, which
        // keeps the result independent of the order the pairs arrive in.
        Timer {
            id: settleRight
            interval: 100
            onTriggered: {
                if (boxLeft.collisionCount === 0 && boxRight.collisionCount === 1)
                    crossed.toRight = true;
                sphere.reset(root.leftSeat, Qt.vector3d(0, 0, 0));
            }
        }

        Timer {
            id: settleLeft
            interval: 100
            onTriggered: {
                if (boxRight.collisionCount === 0 && boxLeft.collisionCount === 1)
                    crossed.toLeft = true;
                sphere.reset(root.rightSeat, Qt.vector3d(0, 0, 0));
            }
        }

        PhysicsTestCase {
            name: "leave and enter in one batch, going right"
            goalReached: crossed.toRight
        }

        PhysicsTestCase {
            name: "leave and enter in one batch, going left"
            goalReached: crossed.toLeft
        }
    }
}
