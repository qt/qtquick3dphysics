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
    height: 480
    visible: true

    PhysicsWorld {
        id: world
        minimumTimestep: 15
        maximumTimestep: 15
        scene: sceneA.scene
    }

    ImpellerScene {
        width: parent.width/2
        height: parent.height/2
        id: sceneA
    }

    ImpellerScene {
        width: parent.width/2
        height: parent.height/2
        x: parent.width/2
        id: sceneB
    }

    ImpellerScene {
        width: parent.width/2
        height: parent.height/2
        y: parent.height/2
        id: sceneC
    }

    ImpellerScene {
        width: parent.width/2
        height: parent.height/2
        x: parent.width/2
        y: parent.height/2
        id: sceneD
    }

    PhysicsTestCase {
        name: "sceneA"
        goalReached: sceneA.numBounces == 1
        function test_next() { next() }
    }

    PhysicsTestCase {
        name: "sceneB"
        goalReached: sceneB.numBounces > 0
        function test_next() { next() }
    }

    PhysicsTestCase {
        name: "sceneA2"
        goalReached: sceneA.numBounces == 5
        function test_next() { next() }
    }

    PhysicsTestCase {
        name: "sceneB2"
        goalReached: sceneB.numBounces == 5
        function test_next() { next() }
    }

    PhysicsTestCase {
        name: "sceneC"
        goalReached: sceneC.numBounces == 1
        function test_next() { next() }
    }

    PhysicsTestCase {
        name: "sceneD"
        goalReached: sceneD.numBounces == 1
    }

    property int step: 0
    function next() {
        step += 1;
        if (step === 1) {
            world.scene = sceneB.scene
        } else if (step === 2) {
            world.scene = sceneA.scene
        } else if (step === 3) {
            world.scene = sceneB.scene
        } else if (step === 4) {
            world.scene = sceneC.scene
        } else if (step === 5) {
            world.scene = sceneD.scene
        }
    }
}
