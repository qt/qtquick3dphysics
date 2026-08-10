// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Tests that every valid combination of PhysicsWorld.staticQueryStructure
// (StaticTree/DynamicTree) and PhysicsWorld.dynamicQueryStructure
// (NoStructure/StaticTree/DynamicTree) doesn't break CharacterController's ground
// detection, which PhysX implements internally via a scene overlap query (against
// both static and dynamic geometry) and a scene raycast (against dynamic geometry only)
// -- the actual code paths these properties affect -- while static actors are being
// added and removed elsewhere in the scene at runtime (simulating chunk streaming) and
// dynamic actors are present for the ground-raycast to consider.
//
// PhysicsWorld.NoStructure is not a valid value for staticQueryStructure, so the full
// matrix has 2 x 3 = 6 combinations; all six are exercised below.

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    property real sceneWidth: 300
    property real sceneHeight: 300
    width: sceneWidth * 3
    height: sceneHeight * 2
    visible: true

    CharacterGroundScene {
        id: sceneStaticNone
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth * 0
        y: parent.sceneHeight * 0
        staticQueryStructure: PhysicsWorld.StaticTree
        dynamicQueryStructure: PhysicsWorld.NoStructure
    }

    PhysicsTestCase {
        name: "static=StaticTree, dynamic=NoStructure: CharacterController ground detection still works"
        goalReached: sceneStaticNone.collisions === CharacterController.Down
    }

    CharacterGroundScene {
        id: sceneStaticStatic
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth * 1
        y: parent.sceneHeight * 0
        staticQueryStructure: PhysicsWorld.StaticTree
        dynamicQueryStructure: PhysicsWorld.StaticTree
    }

    PhysicsTestCase {
        name: "static=StaticTree, dynamic=StaticTree: CharacterController ground detection still works"
        goalReached: sceneStaticStatic.collisions === CharacterController.Down
    }

    CharacterGroundScene {
        id: sceneStaticDynamic
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth * 2
        y: parent.sceneHeight * 0
        staticQueryStructure: PhysicsWorld.StaticTree
        dynamicQueryStructure: PhysicsWorld.DynamicTree
    }

    PhysicsTestCase {
        name: "static=StaticTree, dynamic=DynamicTree: CharacterController ground detection still works"
        goalReached: sceneStaticDynamic.collisions === CharacterController.Down
    }

    CharacterGroundScene {
        id: sceneNone
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth * 0
        y: parent.sceneHeight * 1
        staticQueryStructure: PhysicsWorld.DynamicTree
        dynamicQueryStructure: PhysicsWorld.NoStructure
    }

    PhysicsTestCase {
        name: "static=DynamicTree, dynamic=NoStructure: CharacterController ground detection still works"
        goalReached: sceneNone.collisions === CharacterController.Down
    }

    CharacterGroundScene {
        id: sceneDynamicStatic
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth * 1
        y: parent.sceneHeight * 1
        staticQueryStructure: PhysicsWorld.DynamicTree
        dynamicQueryStructure: PhysicsWorld.StaticTree
    }

    PhysicsTestCase {
        name: "static=DynamicTree, dynamic=StaticTree: CharacterController ground detection still works"
        goalReached: sceneDynamicStatic.collisions === CharacterController.Down
    }

    CharacterGroundScene {
        id: sceneDynamic
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth * 2
        y: parent.sceneHeight * 1
        staticQueryStructure: PhysicsWorld.DynamicTree
        dynamicQueryStructure: PhysicsWorld.DynamicTree
    }

    PhysicsTestCase {
        name: "static=DynamicTree, dynamic=DynamicTree: CharacterController ground detection still works"
        goalReached: sceneDynamic.collisions === CharacterController.Down
    }
}
