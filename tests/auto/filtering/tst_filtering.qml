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
}
