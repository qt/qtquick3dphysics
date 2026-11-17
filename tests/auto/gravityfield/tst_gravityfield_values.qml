// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick3D.Physics.Helpers
import QtQuick3D.Physics.TestUtils

// The gravity itself: a negative one, and edge values the properties
// accept.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        // No world gravity: only the shaped fields pull.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
        property int frames: 0
        onFrameDone: world.frames++
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        LookAtNode {
            target: repulsor
            position: Qt.vector3d(0, 600, -2600)
            PerspectiveCamera {
                clipFar: 8000
            }
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
            brightness: 1.5
            ambientColor: "#3a3a44"
            castsShadow: false
            shadowFactor: 100
        }

        component FieldCube: DynamicRigidBody {
            physicsMaterial: PhysicsMaterial {
                restitution: 0.0
            }
            collisionShapes: BoxShape {
                extents: Qt.vector3d(100, 100, 100)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(1, 1, 1)
                materials: PrincipledMaterial {
                    baseColor: "#4a86e8"
                    roughness: 0.5
                    metalness: 0.1
                }
            }
        }

        // A negative Point gravity pushes away from the centre. unitDistance is set
        // to check that the falloff keeps the sign.
        GravityField {
            id: repulsor
            position: Qt.vector3d(0, 0, 0)
            mode: GravityField.Point
            gravity: -200
            unitDistance: 100
            collisionShapes: SphereShape {
                diameter: 1600
            }
        }

        FieldCube {
            id: repelledCube
            position: Qt.vector3d(100, 0, 0)
        }

        // A unitDistance whose square overflows a float must not give a NaN.
        // Inside it the gravity falls off linearly toward the centre, so this
        // far inside it is next to nothing.
        GravityField {
            position: Qt.vector3d(1400, 0, 0)
            mode: GravityField.Point
            gravity: 200
            unitDistance: 1e20
            collisionShapes: BoxShape {
                extents: Qt.vector3d(800, 800, 800)
            }
        }

        FieldCube {
            id: hugeUnitDistance
            position: Qt.vector3d(1700, 0, 0)
        }

        // A direction too short to normalize is refused, keeping the default.
        GravityField {
            position: Qt.vector3d(-1400, 0, 0)
            direction: Qt.vector3d(0, -1e-7, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(800, 800, 800)
            }
        }

        FieldCube {
            id: shortDirection
            position: Qt.vector3d(-1400, 0, 0)
        }

        // gravityEnabled: false also opts out of shaped fields. PhysX would apply the
        // force regardless, so the shaped field has to skip the body.
        FieldCube {
            id: oppositeOfGravity
            position: Qt.vector3d(-1400, 300, 0)
            gravityEnabled: false
        }

        PhysicsTestCase {
            name: "GravityField with shapes and a negative gravity pushes bodies away"
            goalReached: repelledCube.position.x > 400
        }

        PhysicsTestCase {
            name: "GravityField with a unitDistance too large to square leaves a body in place"
            goalReached: world.frames >= 120 && Math.abs(hugeUnitDistance.position.x - 1700) < 1
        }

        PhysicsTestCase {
            name: "GravityField with shapes keeps its direction when given one too short to use"
            goalReached: shortDirection.position.y < -100
        }

        // 120 steps of the shaped field's gravity would have carried it far down.
        PhysicsTestCase {
            name: "GravityField with shapes leaves a body with gravityEnabled false alone"
            goalReached: world.frames >= 120 && oppositeOfGravity.position.y > 290
        }
    }
}
