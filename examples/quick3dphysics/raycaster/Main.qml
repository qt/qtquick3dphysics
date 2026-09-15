// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Physics

Window {
    id: window
    width: 800
    height: 600
    visible: true
    title: qsTr("Qt Quick 3D Physics - Raycaster")

    PhysicsWorld {
        scene: view3D.scene
        gravity: Qt.vector3d(0, 0, 0)
    }

    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            backgroundMode: SceneEnvironment.Color
            clearColor: "#f0f0f0"
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 300, 750)
            eulerRotation.x: -20
            clipFar: 2000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 35, 0)
            castsShadow: true
            brightness: 1.2
            shadowFactor: 50
            shadowMapQuality: Light.ShadowMapQualityVeryHigh
        }

        StaticRigidBody {
            eulerRotation.x: -90
            collisionShapes: PlaneShape {}

            Model {
                source: "#Rectangle"
                scale: Qt.vector3d(12, 8, 1)
                materials: PrincipledMaterial {
                    baseColor: "green"
                    roughness: 0.8
                }
                castsShadows: false
                receivesShadows: true
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(-130, 60, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(90, 120, 90)
            }

            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.9, 1.2, 0.9)
                materials: PrincipledMaterial {
                    baseColor: "#d94141"
                }
            }
        }

        DynamicRigidBody {
            id: sphereBody
            position: Qt.vector3d(130, 75, 0)
            isKinematic: true
            kinematicPosition: position
            collisionShapes: SphereShape {
                diameter: 100
            }

            Model {
                source: "#Sphere"
                materials: PrincipledMaterial {
                    baseColor: "#3d70b2"
                    roughness: 0.4
                }
            }
        }

        DynamicRigidBody {
            position: Qt.vector3d(0, 310, 0)
            isKinematic: true
            kinematicPosition: position
            collisionShapes: SphereShape {
                diameter: 100
            }

            Model {
                source: "#Sphere"
                castsShadows: false
                materials: PrincipledMaterial {
                    baseColor: "#7193b5"
                    opacity: 0.3
                    alphaMode: PrincipledMaterial.Blend
                    roughness: 0.35
                }
            }

            Node {
                id: rayOrigin
                y: 70
                // The slider holds the angle, whether the sweep or the user moves it.
                eulerRotation.z: angleSlider.value

                SequentialAnimation {
                    running: ray.enabled && sweepCheckBox.checked
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: angleSlider
                        property: "value"
                        from: -25
                        to: 25
                        duration: 3000
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: angleSlider
                        property: "value"
                        from: 25
                        to: -25
                        duration: 3000
                        easing.type: Easing.InOutSine
                    }
                }

                //! [raycast]
                Raycaster {
                    id: ray
                    enabled: enabledCheckBox.checked
                    direction: Qt.vector3d(0, -1, 0)
                    maxDistance: distanceSlider.value
                    includeStatic: staticCheckBox.checked
                    includeDynamic: dynamicCheckBox.checked
                    excludeParentBody: excludeParentCheckBox.checked
                    excludedBodies: excludeSphereCheckBox.checked ? [sphereBody] : []

                    Model {
                        readonly property real rayLength: ray.isColliding ? ray.hit.distance : ray.maxDistance

                        visible: ray.enabled
                        source: "#Cube"
                        y: -rayLength / 2
                        scale: Qt.vector3d(0.025, rayLength / 100, 0.025)
                        materials: PrincipledMaterial {
                            baseColor: ray.isColliding ? "#24a148" : "#da1e28"
                            lighting: PrincipledMaterial.NoLighting
                        }
                    }
                }
                //! [raycast]
            }
        }

        Model {
            visible: ray.enabled && ray.isColliding
            source: "#Sphere"
            position: ray.hit.position
            scale: Qt.vector3d(0.16, 0.16, 0.16)
            materials: PrincipledMaterial {
                baseColor: "#f1c21b"
                lighting: PrincipledMaterial.NoLighting
            }
        }
    }

    //! [controls]
    Frame {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10

        background: Rectangle {
            color: "#c0c0c0"
            border.color: "#202020"
        }

        ColumnLayout {
            Label {
                text: qsTr("Raycaster")
                font.bold: true
            }
            Label {
                color: !ray.enabled ? "#525252" : ray.isColliding ? "#106b2d" : "#a2191f"
                text: !ray.enabled ? qsTr("Disabled") : ray.isColliding ? qsTr("Hit detected") : qsTr("No hit")
            }
            CheckBox {
                id: enabledCheckBox
                text: qsTr("Enabled")
                checked: true
            }
            CheckBox {
                id: staticCheckBox
                text: qsTr("Include static bodies")
                checked: true
            }
            CheckBox {
                id: dynamicCheckBox
                text: qsTr("Include dynamic bodies")
                checked: true
            }
            CheckBox {
                id: excludeParentCheckBox
                text: qsTr("Exclude parent body")
                checked: true
            }
            CheckBox {
                id: excludeSphereCheckBox
                text: qsTr("Exclude the blue sphere")
            }
            CheckBox {
                id: sweepCheckBox
                text: qsTr("Sweep ray")
                checked: true
            }
            Label {
                text: qsTr("Ray angle: %1°").arg(rayOrigin.eulerRotation.z.toFixed(0))
            }
            Slider {
                id: angleSlider
                Layout.preferredWidth: 220
                enabled: !sweepCheckBox.checked
                from: -25
                to: 25
                stepSize: 1
            }
            Label {
                text: qsTr("Maximum distance: %1").arg(distanceSlider.value.toFixed(0))
            }
            Slider {
                id: distanceSlider
                Layout.preferredWidth: 220
                from: 0
                to: 600
                value: 350
                stepSize: 10
            }
            Label {
                visible: ray.isColliding
                text: qsTr("Hit distance: %1").arg(ray.hit.distance.toFixed(1))
            }
        }
    }
    //! [controls]
}
