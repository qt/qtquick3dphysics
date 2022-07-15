// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 1280
    height: 720
    visible: true
    title: qsTr("QtQuick3DPhysics Custom Shapes")

    DynamicsWorld {
        id: physicsWorld
        running: false
        forceDebugView: false
        typicalLength: 2
        enableCCD: true
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: physicsWorld.running = true
    }

    Texture {
        id: proceduralSky
        textureData: ProceduralSkyTextureData {
            sunLongitude: -115
        }
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "white"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
            lightProbe: proceduralSky
        }

        Node {
            id: scene1
            scale: "2, 2, 2"
            PerspectiveCamera {
                id: camera1
                position: Qt.vector3d(-45, 20, 60)
                eulerRotation: Qt.vector3d(-6, -13, 0)
                clipFar: 1000
                clipNear: 0.1
            }

            DirectionalLight {
                eulerRotation.x: -45
                eulerRotation.y: 25
                castsShadow: true
                brightness: 1
                shadowMapQuality: Light.ShadowMapQualityVeryHigh
            }

            StaticRigidBody {
                position: Qt.vector3d(0, -100, 0)
                eulerRotation: Qt.vector3d(-90, 0, 0)
                collisionShapes: PlaneShape {
                }
            }

            Texture {
                id: weaveNormal
                source: "maps/weave.png"
                scaleU: 200
                scaleV: 200
                generateMipmaps: true
                mipFilter: Texture.Linear
            }

            StaticRigidBody {
                position: Qt.vector3d(-15, -8, 0)
                id: tablecloth

                Model {
                    geometry: HeightFieldGeometry {
                        id: tableclothGeometry
                        extents: Qt.vector3d(150, 20, 150)
                        heightMap: "maps/cloth-heightmap.png"
                        smoothShading: false
                    }
                    materials: PrincipledMaterial {
                        baseColor: "#447722"
                        roughness: 0.8
                        normalMap: weaveNormal
                        normalStrength: 0.7
                    }
                }

                collisionShapes: HeightFieldShape {
                    id: hfShape
                    extents: tableclothGeometry.extents
                    heightMap: "maps/cloth-heightmap.png"
                }
            }

            DynamicRigidBody {
                id: diceCup
                isKinematic: true
                mass: 0
                property vector3d restPos: Qt.vector3d(11, 6, 0)
                position: restPos
                pivot: Qt.vector3d(0, 6, 0)
                collisionShapes: TriangleMeshShape {
                    id: cupShape
                    meshSource: "meshes/simpleCup.mesh"
                }
                Model {
                    source: "meshes/cup.mesh"
                    materials: PrincipledMaterial {
                        baseColor: "#cc9988"
                        roughness: 0.3
                        metalness: 1
                    }
                }
                Behavior on eulerRotation.z {
                    NumberAnimation { duration: 1500 }
                }
                Behavior on position {
                    PropertyAnimation { duration: 1500 }
                }
            }

            StaticRigidBody {
                id: diceTower
                x: -4
                Model {
                    id: testModel
                    source: "meshes/tower.mesh"
                    materials: [
                        PrincipledMaterial {
                            baseColor: "#ccccce"
                            roughness: 0.3
                        },
                        PrincipledMaterial {
                            id: glassMaterial
                            baseColor: "#aaaacc"
                            transmissionFactor: 0.95
                            thicknessFactor: 1
                            roughness: 0.05
                        }
                    ]
                }
                collisionShapes: TriangleMeshShape {
                    id: triShape
                    meshSource: "meshes/tower.mesh"
                }
            }

            Texture {
                id: numberNormal
                source: "maps/numbers-normal.png"

            }
            Texture {
                id: numberFill
                source: "maps/numbers.png"
                generateMipmaps: true
                mipFilter: Texture.Linear
            }
            Component {
                id: diceComponent

                DynamicRigidBody {
                    id: thisBody
                    function randomInRange(min, max) {
                        return Math.random() * (max - min) + min;
                    }

                    function restore() {
                        reset(initialPosition, eulerRotation)
                    }

                    scale: Qt.vector3d(sf, sf, sf)
                    eulerRotation: Qt.vector3d(randomInRange(0, 360),
                                               randomInRange(0, 360),
                                               randomInRange(0, 360))

                    property vector3d initialPosition:  Qt.vector3d( 11 + 1.5*Math.cos(index/(Math.PI/4)), 5 + index * 1.5, 0)
                    position: initialPosition

                    property real sf: randomInRange(0.8, 1.4)
                    property color baseCol: Qt.hsla(randomInRange(0, 1), randomInRange(0.6, 1.0), randomInRange(0.4, 0.7), 1.0)

                    collisionShapes: ConvexMeshShape {
                        id: diceShape
                        meshSource: Math.random() < 0.25 ? "meshes/icosahedron.mesh"
                                  : Math.random() < 0.5 ? "meshes/dodecahedron.mesh"
                                  : Math.random() < 0.75 ? "meshes/octahedron.mesh"
                                                         : "meshes/tetrahedron.mesh"
                    }

                    Model {
                        id: thisModel
                        source: diceShape.meshSource
                        materials: PrincipledMaterial {
                            metalness: 1.0
                            roughness: randomInRange(0.2, 0.6)
                            baseColor: baseCol
                            emissiveMap: numberFill
                            emissiveFactor: "1,1,1"
                            normalMap: numberNormal
                            normalStrength: 0.75
                        }
                    }
                }
            }

            Repeater3D {
                id: dicePool
                model: 25
                delegate: diceComponent
                function restore() {
                    for (let i = 0; i < count; i++) {
                        objectAt(i).restore()
                    }
                }
            }

            SequentialAnimation {
                running: physicsWorld.running
                PauseAnimation { duration: 1500 }
                ScriptAction { script: diceCup.position = Qt.vector3d(4, 45, 0) }
                PauseAnimation { duration: 1500 }
                ScriptAction { script: { diceCup.eulerRotation.z = 130; diceCup.position = Qt.vector3d(0, 45, 0) } }
                PauseAnimation { duration: 3000 }
                ScriptAction { script: { diceCup.eulerRotation.z = 0; diceCup.position = Qt.vector3d(4, 45, 0) } }
                PauseAnimation { duration: 1500 }
                ScriptAction { script: diceCup.position = diceCup.restPos }
                PauseAnimation { duration: 2000 }
                ScriptAction { script: dicePool.restore() }
                loops: Animation.Infinite
            }

        } // scene1
    } // View3D

    WasdController {
        keysEnabled: true
        controlledObject: camera1
        speed: 0.2
    }

}
