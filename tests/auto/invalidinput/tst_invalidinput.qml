// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Regression tests for invalid/edge-case input that previously crashed or was
// silently mishandled instead of being rejected or failing gracefully.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils
import PhysicsTest.InvalidInput

Item {
    width: 64
    height: 64

    // Shared smoke-test scene: bodies below previously crashed the simulation on
    // malformed input. Each PhysicsTestCase asserts the world keeps running instead.
    // No rendering is needed for any of this, so scene is a plain Node rather than
    // a View3D.
    Node {
        id: invalidShapeScene

        // A Geometry with no position attribute used to hit a reachable
        // Q_UNREACHABLE() in QQuick3DPhysicsMesh's attributeBySemantic() helper.
        StaticRigidBody {
            position: Qt.vector3d(0, 100, 0)
            collisionShapes: ConvexMeshShape { geometry: NoPositionGeometry {} }
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -100, 0)
            collisionShapes: TriangleMeshShape { geometry: NoPositionGeometry {} }
        }
    }

    PhysicsWorld {
        id: invalidShapeWorld
        scene: invalidShapeScene
        running: true
        minimumTimestep: 15
        maximumTimestep: 15

        property int frameCount: 0
        onFrameDone: invalidShapeWorld.frameCount++
    }

    PhysicsTestCase {
        name: "invalidinput_noPositionGeometry"
        goalReached: invalidShapeWorld.frameCount > 5
    }
}
