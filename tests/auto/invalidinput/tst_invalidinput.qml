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

    TriggerBody {
        id: filterGroupNode
        collisionShapes: BoxShape {}
    }

    TestCase {
        name: "invalidinput_filterGroup"

        // PhysicsNode.filterGroup is only meaningful in [0, 31] (see
        // physxnode/qphysxworld.cpp's isFilteredOut()/isBitSet()). Values outside
        // that range used to be accepted silently and made the collision filter
        // fail open (the pair would collide normally instead of being filtered).
        function test_filterGroupRejectsOutOfRange() {
            filterGroupNode.filterGroup = 5
            compare(filterGroupNode.filterGroup, 5)

            filterGroupNode.filterGroup = 31
            compare(filterGroupNode.filterGroup, 31, "boundary value 31 should be accepted")

            filterGroupNode.filterGroup = 32
            compare(filterGroupNode.filterGroup, 31,
                    "out-of-range value 32 should be rejected, keeping the previous value")

            filterGroupNode.filterGroup = -1
            compare(filterGroupNode.filterGroup, 31,
                    "negative value should be rejected, keeping the previous value")
        }
    }

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

        // Shapes with zero/negative dimensions used to crash
        // QPhysXActorBody::rebuildShapes() via an unchecked null return from
        // PxPhysics::createShape(). None of these are expected to do anything
        // physically meaningful -- the goal here is just that the world keeps
        // simulating instead of crashing.
        StaticRigidBody {
            position: Qt.vector3d(-100, 0, 0)
            collisionShapes: SphereShape { diameter: 0 }
        }

        StaticRigidBody {
            position: Qt.vector3d(100, 0, 0)
            collisionShapes: BoxShape { extents: Qt.vector3d(-1, 5, 5) }
        }

        StaticRigidBody {
            position: Qt.vector3d(200, 0, 0)
            collisionShapes: CapsuleShape { diameter: 0; height: 0 }
        }

        // A running body with massMode: CustomDensity and density: 0 shouldn't hang or
        // crash the simulation.
        DynamicRigidBody {
            id: zeroDensityBody
            position: Qt.vector3d(0, 200, 0)
            massMode: DynamicRigidBody.CustomDensity
            density: 0
            collisionShapes: SphereShape { diameter: 10 }
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

    PhysicsTestCase {
        name: "invalidinput_shapeDimensions"
        goalReached: invalidShapeWorld.frameCount > 5
    }

    TestCase {
        name: "invalidinput_density"

        // DynamicRigidBody.density's setter now clamps to (0, inf], matching its
        // documented range, instead of silently storing an invalid value that only
        // failed later in the deferred command execution.
        function test_zeroDensityIsClamped() {
            verify(zeroDensityBody.density > 0,
                   "density: 0 should be clamped to a small positive value, not stored as-is")
        }
    }
}
