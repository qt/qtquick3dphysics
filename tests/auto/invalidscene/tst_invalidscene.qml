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
        id: worldA
        scene: scene
        viewport: viewA.scene
        forceDebugDraw: true
    }

    PhysicsWorld {
        id: worldB
        scene: scene
        viewport: viewB.scene
        forceDebugDraw: true
    }

    ImpellerScene {
        id: scene
    }

    EmptyView {
        width: parent.width/2
        height: parent.height
        x: parent.width/2
        id: viewA
    }

    EmptyView {
        width: parent.width/2
        height: parent.height
        id: viewB
    }

    PhysicsTestCase {
        name: "scene"
        goalReached: scene.numBounces > 1
    }
}
