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

// Directional mode, and a body deleted while inside a shaped field.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        // No world gravity: only the shaped field pushes.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
        property int frames: 0
        onFrameDone: {
            frames++;
            if (frames === 100)
                doomedCube.destroy();
        }
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
            target: pushShapedField
            position: Qt.vector3d(100, 250, -1100)
            PerspectiveCamera {
                clipFar: 4000
            }
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
            brightness: 1.5
            ambientColor: "#3a3a44"
            castsShadow: false
            shadowFactor: 100
        }

        GravityField {
            id: pushShapedField
            position: Qt.vector3d(0, 0, 0)
            direction: Qt.vector3d(1, 0, 0)
            gravity: 200
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1200, 400, 400)
            }
        }

        component FallingCube: DynamicRigidBody {
            physicsMaterial: PhysicsMaterial {
                restitution: 0.0
            }
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.4, 0.4, 0.4)
                materials: PrincipledMaterial {
                    baseColor: "#4a86e8"
                    roughness: 0.5
                    metalness: 0.1
                }
            }
        }

        // Beyond the shaped field's position, so Point mode would pull it back in.
        FallingCube {
            id: driftCube
            position: Qt.vector3d(400, 0, 0)
        }

        // Deleted while inside, which the shaped field must not dereference afterwards.
        FallingCube {
            id: doomedCube
            position: Qt.vector3d(100, 150, 0)
        }

        PhysicsTestCase {
            name: "GravityField with shapes in Directional mode pushes along its direction"
            goalReached: driftCube.position.x > 600
        }

        // Passes unless the deleted body crashed the shaped field.
        PhysicsTestCase {
            name: "GravityField with shapes survives a body being deleted inside it"
            goalReached: world.frames >= 200
        }
    }
}
