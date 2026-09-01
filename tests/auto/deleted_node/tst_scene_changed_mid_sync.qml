// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Takes the scene away from the world while it is walking its bodies to sync
// them. A handler on the position a sync writes moves the world to another
// scene, which deregisters every body at once, so each body the walk has not
// reached yet is left with nothing to sync. Every body carries the handler, so
// whichever the walk reaches first does the moving and the ones behind it are
// the ones left behind. Syncing them crashed.
//
// Nothing is deleted here, and that is the point: a scene change leaves a
// backend without a frontend just as a delete does, and it lands while the walk
// is still on the stack, rather than whenever the object a delete was asked for
// is deferred to.
//
// Reaching the end of both of the frame's walks is the assertion, asked for as
// two more finished frames after the move.
//
// No rendering is needed for any of this, so scene is a plain Node rather than
// a View3D: debug drawing below builds its models against that node and nothing
// asks to see them.

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

        // Falling freely, so every sync has a new position to write and no body
        // ever falls asleep and stops being written to.
        Repeater3D {
            model: 3
            DynamicRigidBody {
                required property int index
                position: Qt.vector3d(index * 120 - 120, 200, 0)
                collisionShapes: BoxShape {}
                // Held off until the world has frames behind it, since setting
                // the position above emits this too, and moving the world from
                // there would move it before it ever walked anything.
                onPositionChanged: {
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
        name: "moving the world while it syncs its bodies"
        goalReached: root.frameAtMove >= 0 && world.frameCount > root.frameAtMove + 1
    }
}
