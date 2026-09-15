// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Takes the scene away from the world from a handler on the velocity a sync
// writes. Like the position in tst_scene_changed_mid_sync.qml, the velocities
// are written while the walk over the bodies is on the stack, so moving the
// world from there deregisters every body, the one being synced included, and
// that body has nothing left to finish its sync with.
//
// Reaching the end of both of the frame's walks is the assertion, asked for as
// two more finished frames after the move.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    id: root
    width: 64
    height: 64

    // The frame the world was moved on, set by whichever body the walk reached
    // first.
    property int frameAtMove: -1

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -981, 0)
        running: true
        // On, so the frame that loses its scene mid-walk goes on to the second
        // walk it makes over the same backends, the one debug drawing does.
        forceDebugDraw: true
        typicalLength: 100
        typicalSpeed: 1000
        minimumTimestep: 15
        maximumTimestep: 15
        scene: fallingScene

        property int frameCount: 0
        onFrameDone: world.frameCount++
    }

    Node {
        id: fallingScene

        // Falling freely, so every sync has a new velocity to write.
        Repeater3D {
            model: 3
            DynamicRigidBody {
                required property int index
                position: Qt.vector3d(index * 120 - 120, 200, 0)
                collisionShapes: BoxShape {}
                onLinearVelocityChanged: {
                    if (world.frameCount > 5 && world.scene === fallingScene) {
                        root.frameAtMove = world.frameCount;
                        world.scene = elsewhere;
                    }
                }
            }
        }
    }

    // What the world is moved to. It holds no bodies, so the move leaves every
    // body without a world rather than handing it to a new one.
    Node {
        id: elsewhere
    }

    PhysicsTestCase {
        name: "moving the world while it updates a body's velocity"
        goalReached: root.frameAtMove >= 0 && world.frameCount > root.frameAtMove + 1
    }
}
