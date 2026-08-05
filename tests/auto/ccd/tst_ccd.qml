// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Tests that DynamicRigidBody::ccd actually prevents tunneling for a fast
// body that would otherwise pass straight through a thin static wall
// undetected in a single simulation step.
//
// 00) no CCD: fast body tunnels through, no contact
// 01) SweepBasedCCD: fast body is caught, contact fires
// 02) SpeculativeCCD: fast body is caught, contact fires
// 03) PhysicsWorld::enableCCD (deprecated global fallback): fast body is caught, contact fires

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    property real sceneWidth: 300
    property real sceneHeight: 300
    width: sceneWidth*4
    height: sceneHeight
    visible: true

    //////////////////////////////////////////////////
    // 00 no CCD: fast body tunnels through, no contact

    TunnelScene {
        width: parent.sceneWidth
        height: parent.sceneHeight
        id: sceneNoCcd
        ccd: DynamicRigidBody.None
    }

    PhysicsTestCase {
        // Require the sphere to actually be found well past the wall (not
        // just "no contact happened"), so the test can't pass vacuously if
        // contact reporting itself were broken or the sphere never moved.
        name: "no CCD: fast body tunnels through thin wall (no contact)"
        goalReached: sceneNoCcd.bulletPosition.y < -2000 && !sceneNoCcd.contact
    }

    //////////////////////////////////////////////////
    // 01 SweepBasedCCD: fast body is caught, contact fires

    TunnelScene {
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth
        id: sceneCcd
        ccd: DynamicRigidBody.SweepBasedCCD
    }

    PhysicsTestCase {
        // Also confirm the sphere was actually stopped at the wall rather
        // than merely reporting a contact while still sailing through it.
        name: "SweepBasedCCD: fast body is caught by thin wall (contact)"
        goalReached: sceneCcd.contact && sceneCcd.bulletPosition.y > -150
    }

    //////////////////////////////////////////////////
    // 02 SpeculativeCCD: fast body is caught, contact fires

    TunnelScene {
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth*2
        id: sceneSpeculativeCcd
        ccd: DynamicRigidBody.SpeculativeCCD
    }

    PhysicsTestCase {
        name: "SpeculativeCCD: fast body is caught by thin wall (contact)"
        goalReached: sceneSpeculativeCcd.contact && sceneSpeculativeCcd.bulletPosition.y > -150
    }

    //////////////////////////////////////////////////
    // 03 PhysicsWorld::enableCCD (deprecated global fallback): fast body is
    // caught, contact fires

    TunnelScene {
        width: parent.sceneWidth
        height: parent.sceneHeight
        x: parent.sceneWidth*3
        id: sceneEnableCcd
        // ccd left at its default None: relies purely on the deprecated
        // PhysicsWorld.enableCCD global fallback (uses SweepBasedCCD for a
        // non-kinematic body).
        enableCCD: true
    }

    PhysicsTestCase {
        name: "PhysicsWorld.enableCCD: fast body is caught by thin wall (contact)"
        goalReached: sceneEnableCcd.contact && sceneEnableCcd.bulletPosition.y > -150
    }
}
