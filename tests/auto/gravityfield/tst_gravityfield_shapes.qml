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

// Point mode: bodies fall towards a planet from any direction.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        // No world gravity: only the shaped field pulls.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
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
            target: planet
            position: Qt.vector3d(250, 300, -600)
            PerspectiveCamera {
                id: camera
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

        StaticRigidBody {
            id: planet
            position: Qt.vector3d(0, 0, 0)
            collisionShapes: SphereShape {
                diameter: 280
            }
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(2.8, 2.8, 2.8)
                materials: PrincipledMaterial {
                    baseColor: "#3f8f4f"
                    roughness: 0.85
                }
            }
        }

        GravityField {
            id: gravityShapedField
            position: planet.position
            mode: GravityField.Point
            gravity: 200
            collisionShapes: SphereShape {
                diameter: 1600
            }
        }

        // Just outside the planet's surface, to see that a body reached it.
        TriggerBody {
            id: planetSurface
            position: planet.position
            collisionShapes: SphereShape {
                diameter: 340
            }
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(3.4, 3.4, 3.4)
                materials: PrincipledMaterial {
                    baseColor: Qt.rgba(0.6, 0.8, 1.0, 0.12)
                    alphaMode: PrincipledMaterial.Blend
                    cullMode: Material.NoCulling
                    lighting: PrincipledMaterial.NoLighting
                }
            }
            property bool cube1Hit: false
            property bool cube2Hit: false
            property bool cube3Hit: false
            onBodyEntered: (body) => {
                if (body === cube1)
                    cube1Hit = true;
                else if (body === cube2)
                    cube2Hit = true;
                else if (body === cube3)
                    cube3Hit = true;
            }
        }

        component FallingCube: DynamicRigidBody {
            // For the TriggerBody above; the shaped field acts regardless.
            sendTriggerReports: true

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

        // Started askew: axis-aligned on a radial line, a cube balances on its edge
        // instead of settling.
        FallingCube {
            id: cube1
            position: Qt.vector3d(330, 0, 0)
            eulerRotation: Qt.vector3d(20, 15, 30)
        }

        FallingCube {
            id: cube2
            position: Qt.vector3d(0, 330, 0)
            eulerRotation: Qt.vector3d(-25, 40, 10)
        }

        FallingCube {
            id: cube3
            position: Qt.vector3d(-233, 233, 0)
            eulerRotation: Qt.vector3d(35, -20, 25)
        }

        PhysicsTestCase {
            name: "GravityField with shapes attracts cube1 into the planet"
            goalReached: planetSurface.cube1Hit
        }

        PhysicsTestCase {
            name: "GravityField with shapes attracts cube2 into the planet"
            goalReached: planetSurface.cube2Hit
        }

        PhysicsTestCase {
            name: "GravityField with shapes attracts cube3 into the planet"
            goalReached: planetSurface.cube3Hit
        }
    }
}
