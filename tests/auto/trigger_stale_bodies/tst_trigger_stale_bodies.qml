// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Two ways a body ends up on a trigger's list and never comes off it again,
// which leaves collisionCount counting a body that is not inside any more.
//
// A body deleted while inside is the first. Nothing took it off the list, so
// the count kept it and the list kept a pointer to an object that no longer
// exists. Nothing is reported for such a body either, so bodyExited has to
// stay silent while the count still drops.
//
// A body that turns sendTriggerReports off while inside is the second. The
// flag was read again as the body left, so one that had stopped asking was
// never taken off the list it was put on when it did ask.
//
// No rendering is needed for either, so scene is a plain Node rather than a
// View3D.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    id: root
    width: 64
    height: 64

    PhysicsWorld {
        id: world
        // Off, so a body stays where it is put and only the test moves it.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 100
        typicalSpeed: 1000
        minimumTimestep: 15
        maximumTimestep: 15
        scene: bodies

        property int frames: 0
        onFrameDone: world.frames++
    }

    component AfterFrames: Timer {
        id: gate
        property int frames: 30
        property int startedAt: 0
        signal reached()

        interval: 16
        repeat: true
        onRunningChanged: if (running) gate.startedAt = world.frames
        onTriggered: {
            if (world.frames - gate.startedAt < gate.frames)
                return;
            gate.running = false;
            gate.reached();
        }
    }

    component Region: TriggerBody {
        collisionShapes: BoxShape {
            extents: Qt.vector3d(400, 400, 400)
        }
    }

    component Occupant: DynamicRigidBody {
        sendTriggerReports: true
        collisionShapes: BoxShape {
            extents: Qt.vector3d(40, 40, 40)
        }
    }

    Node {
        id: bodies

        // ---- a body deleted while inside ----

        Region {
            id: outlived
            position: Qt.vector3d(0, 0, 0)

            property int exits: 0
            onBodyExited: (body) => outlived.exits++
        }

        Occupant {
            id: doomed
            position: Qt.vector3d(0, 0, 0)
        }

        QtObject {
            id: deletion
            property int countInside: -1
            property int countAfter: -1
            property int exitsAfter: -1
        }

        AfterFrames {
            running: true
            onReached: {
                deletion.countInside = outlived.collisionCount;
                doomed.destroy();
                deletedGate.running = true;
            }
        }

        AfterFrames {
            id: deletedGate
            onReached: {
                deletion.countAfter = outlived.collisionCount;
                deletion.exitsAfter = outlived.exits;
            }
        }

        // ---- a body that stops asking while it is inside ----

        Region {
            id: forsaken
            position: Qt.vector3d(2000, 0, 0)
        }

        Occupant {
            id: quitter
            position: Qt.vector3d(2000, 0, 0)
        }

        QtObject {
            id: quit
            property int countInside: -1
            property int countAfter: -1
        }

        AfterFrames {
            running: true
            onReached: {
                quit.countInside = forsaken.collisionCount;
                quitter.sendTriggerReports = false;
                // Out of the region it is no longer asking to be told about.
                quitter.reset(Qt.vector3d(4000, 0, 0), Qt.vector3d(0, 0, 0));
                quitGate.running = true;
            }
        }

        AfterFrames {
            id: quitGate
            onReached: quit.countAfter = forsaken.collisionCount
        }
    }

    PhysicsTestCase {
        name: "a body deleted while inside stops being counted"
        timeoutSecs: 10
        goalReached: deletion.countInside === 1 && deletion.countAfter === 0
    }

    PhysicsTestCase {
        name: "a body deleted while inside is not reported as having left"
        timeoutSecs: 10
        goalReached: deletion.countAfter === 0 && deletion.exitsAfter === 0
    }

    PhysicsTestCase {
        name: "a body that stopped asking is still taken off the list"
        timeoutSecs: 10
        goalReached: quit.countInside === 1 && quit.countAfter === 0
    }
}
