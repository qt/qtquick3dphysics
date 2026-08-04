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
        gravity: Qt.vector3d(0, -490, 0)
        scene: sceneA.scene
    }

    PhysicsWorld {
        gravity: Qt.vector3d(0, -10, 0)
        scene: sceneB.scene
    }

    PhysicsWorld {
        gravity: Qt.vector3d(0, -900, 0)
        scene: sceneC.scene
    }

    PhysicsWorld {
        gravity: Qt.vector3d(0, -1900, 0)
        scene: sceneD.scene
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
        goalReached: sceneA.numBounces > 0
    }

    PhysicsTestCase {
        name: "sceneB"
        goalReached: sceneB.numBounces > 0
    }

    PhysicsTestCase {
        name: "sceneC"
        goalReached: sceneC.numBounces > 0
    }

    PhysicsTestCase {
        name: "sceneD"
        goalReached: sceneD.numBounces > 0
    }
}
