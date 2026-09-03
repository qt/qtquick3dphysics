// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    width: 640
    height: 640
    visible: true

    PhysicsWorld {
        scene: sceneA.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    PhysicsWorld {
        scene: sceneB.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    PhysicsWorld {
        scene: sceneC.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    PhysicsWorld {
        scene: sceneD.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    PhysicsWorld {
        scene: sceneE.scene
        minimumTimestep: 15
        maximumTimestep: 15
        enableCCD: true
    }

    PhysicsWorld {
        scene: sceneF.scene
        minimumTimestep: 15
        maximumTimestep: 15
    }

    BoxesScene {
        width: parent.width/2
        height: parent.height/3
        id: sceneA
    }

    BoxesScene {
        width: parent.width/2
        height: parent.height/3
        x: parent.width/2
        id: sceneB
        filterIgnoreGroups: [1]
    }

    BoxesScene {
        width: parent.width/2
        height: parent.height/3
        y: parent.height/3
        id: sceneC
        filterIgnoreGroups: [1,2]
    }

    BoxesScene {
        width: parent.width/2
        height: parent.height/3
        x: parent.width/2
        y: parent.height/3
        id: sceneD
        filterIgnoreGroups: [1,2,3]
    }

    BoxesScene {
        width: parent.width/2
        height: parent.height/3
        y: parent.height * 2/3
        id: sceneE
        filterIgnoreGroups: [1,2,3]
    }

    // Starts out colliding with every box, and is changed while the simulation is running
    BoxesScene {
        width: parent.width/2
        height: parent.height/3
        x: parent.width/2
        y: parent.height * 2/3
        id: sceneF
        filterIgnoreGroups: []
    }

    PhysicsTestCase {
        name: "sceneA"
        goalReached: sceneA.numBouncesTop >= 3
    }

    PhysicsTestCase {
        name: "sceneB"
        goalReached: sceneB.numBouncesMiddle >= 3
    }

    PhysicsTestCase {
        name: "sceneC"
        goalReached: sceneC.numBouncesBottom >= 3
    }

    PhysicsTestCase {
        name: "sceneD"
        goalReached: sceneD.numBouncesFloor >= 3
    }

    PhysicsTestCase {
        name: "sceneE (CCD enabled)"
        goalReached: sceneE.numBouncesFloor >= 3
    }

    PhysicsTestCase {
        name: "sceneF (filters changed while running)"
        goalReached: sceneF.numBouncesTop >= 1
        function test_1_collides_with_the_top_box() {
            compare(sceneF.numBouncesMiddle, 0)
        }
        function test_2_start_ignoring_the_top_box() {
            sceneF.filterIgnoreGroups = [1]
        }
    }

    PhysicsTestCase {
        // The sphere was bouncing on the top box, so reaching the middle one means the new
        // filter took effect. Times out if changing the filters at runtime has no effect.
        name: "sceneF (filters changed while running, part 2)"
        goalReached: sceneF.numBouncesMiddle >= 1
    }
}
