// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Takes the scene away from the world from inside a trigger report, while the
// batch of reports that carries it is still on the stack. Moving the world
// deregisters every body at once, which is what deleting one does to the
// trigger callback's end of things, and it lands while the callback is still
// running rather than whenever the object a delete was asked for is deferred
// to. Deregistering from there took the lock the callback held, on the thread
// that already held it, so the application hung. Reaching the next frame is
// the assertion.
//
// Three bodies cross the boundary together, so the report the world is moved
// from is one of a batch and the pairs behind it are about bodies the move has
// taken out. Only the first is reported: the rest are asked about one at a
// time and skipped.
//
// No rendering is needed for any of this, so scene is a plain Node rather than
// a View3D.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    id: root
    width: 64
    height: 64

    // The frame the world was moved on, set by the first report to arrive.
    property int frameAtMove: -1
    property int reports: 0

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -981, 0)
        running: true
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

        TriggerBody {
            id: gate
            collisionShapes: BoxShape {
                extents: Qt.vector3d(400, 100, 100)
            }

            onBodyEntered: (body) => {
                root.reports++;
                if (root.frameAtMove < 0) {
                    root.frameAtMove = world.frameCount;
                    world.scene = elsewhere;
                }
            }
        }

        // Side by side and let go of from the same height, so they reach the
        // trigger on the same step and the pairs that say so arrive together.
        Repeater3D {
            model: 3
            DynamicRigidBody {
                required property int index
                position: Qt.vector3d(index * 120 - 120, 200, 0)
                sendTriggerReports: true
                collisionShapes: BoxShape {
                    extents: Qt.vector3d(50, 50, 50)
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
        name: "moving the world from a trigger report reaches the next frame"
        timeoutSecs: 10
        goalReached: root.frameAtMove >= 0 && world.frameCount > root.frameAtMove + 1
    }

    PhysicsTestCase {
        name: "a body the move took out is not reported"
        timeoutSecs: 10
        goalReached: root.frameAtMove >= 0 && world.frameCount > root.frameAtMove + 1
                     && root.reports === 1
    }
}
