// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Physics

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: qsTr("Qt Quick 3D Physics - Planet")

    // No world gravity: the GravityField below pulls everything towards the planet.
    PhysicsWorld {
        id: physicsWorld
        scene: sceneRoot
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 1
        typicalSpeed: 10
        forceDebugDraw: false
    }

    View3D {
        id: view3D
        anchors.fill: parent

        // Set by the planet size slider in the panel.
        property real planetSize: 600
        // Where the character starts: on the surface, 30 degrees round from the
        // mountain on the x axis, on the side where the sun is high.
        readonly property vector3d spawnPosition:
            Qt.vector3d(0.866, 0, -0.5).times(planetSize * 0.5 + 2)
        // Resizing moves the ground under the character, so put it back.
        onSpawnPositionChanged: playerController.teleport(spawnPosition)

        DirectionalLight {
            eulerRotation: Qt.vector3d(-0, -210, 0)
            castsShadow: true
            lockShadowmapTexels: true
            shadowMapQuality: Light.ShadowMapQualityHigh
            shadowMapFar: 60
            shadowBias: 1
            pcfFactor: 0.3
            shadowFactor: 75
            // A little fill, so that faces turned away from the sun aren't black
            ambientColor: Qt.rgba(0.08, 0.08, 0.12, 1)
        }

        environment: SceneEnvironment {
            clearColor: "#242444"
            backgroundMode: SceneEnvironment.SkyMaterial
            tonemapMode: SceneEnvironment.TonemapModeAces
            skyMaterial: SkyMaterial {
                enableIBL: true
                fragmentShaderCode: "
                        float hash(vec3 p) {
                            p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
                            p *= 17.0;
                            return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
                        }

                        void MAIN()
                        {
                            vec3 dir = normalize(qt_eyeDir);

                            vec3 col = vec3(0.005, 0.005, 0.015) * (1.0 - abs(dir.y) * 0.3);

                            for (float i = 1.0; i < 4.0; i++) {
                                vec3 p = dir * (i * 250.0 + 100.0);
                                vec3 ip = floor(p);
                                vec3 fp = fract(p) - 0.5;

                                float h = hash(ip);

                                if (h > 0.95) {
                                    float starBrightness = pow((h - 0.95) / 0.05, 4.0);
                                    float dist = length(fp);
                                    float star = smoothstep(0.15, 0.0, dist);

                                    vec3 starColor = mix(vec3(0.8, 0.9, 1.0), vec3(1.0, 0.8, 0.6), hash(ip + 1.0));
                                    col += starColor * star * starBrightness * (2.0 / i);
                                }
                            }

                            vec3 sunDir = normalize(vec3(0.6, 0.3, -0.7));
                            float sunDot = max(dot(dir, sunDir), 0.0);
                            float sunCore = pow(sunDot, 12000.0);
                            float sunGlow = pow(sunDot, 120.0) * 0.4;
                            float sunAtmosphere = pow(sunDot, 12.0) * 0.05;
                            vec3 sunColor = vec3(1.0, 0.9, 0.75);
                            col += sunColor * (sunCore * 5.0 + sunGlow + sunAtmosphere);

                            FRAGCOLOR = vec4(col, 1.0);
                        }
"
            }
        }

        Node {
            id: sceneRoot

            StaticRigidBody {
                id: planet

                physicsMaterial: PhysicsMaterial {
                    staticFriction: 0.6
                    dynamicFriction: 0.5
                    restitution: 0.0
                }

                collisionShapes: SphereShape {
                    diameter: view3D.planetSize
                }

                Model {
                    geometry: SphereGeometry {
                        radius: view3D.planetSize * 0.5
                        rings: 64
                        segments: 128
                    }

                    castsShadows: false
                    materials: PrincipledMaterial {
                        baseColor: "Green"
                        roughness: 1
                        metalness: 0.3
                    }
                }
            }

            StaticRigidBody {
                id: mountain
                position: Qt.vector3d(view3D.planetSize * 0.5, 0, 0)

                physicsMaterial: PhysicsMaterial {
                    staticFriction: 0.6
                    dynamicFriction: 0.5
                    restitution: 0.0
                }

                collisionShapes: ConvexMeshShape {
                    geometry: mountainModel.geometry
                    eulerRotation.z: -90
                }

                Model {
                    id: mountainModel
                    geometry: ConeGeometry {
                        rings: 64
                        segments: 128
                        topRadius: 10
                        length: view3D.planetSize * 0.1
                        bottomRadius: view3D.planetSize * 0.15
                    }

                    eulerRotation.z: -90

                    castsShadows: false
                    materials: PrincipledMaterial {
                        baseColor: "Green"
                        roughness: 0.9
                        metalness: 0.9
                    }
                }
            }

            //! [dynamic-gravity]
            GravityField {
                id: gravityField
                mode: GravityField.Point
                gravity: gravitySlider.value
                unitDistance: view3D.planetSize * 0.5
            }
            //! [dynamic-gravity]

            Component {
                id: similarCube

                DynamicRigidBody {
                    property real globalScale: 1 + Math.random() * 2
                    scale: Qt.vector3d(globalScale, globalScale, globalScale)
                    ccd: DynamicRigidBody.SweepBasedCCD
                    collisionShapes: BoxShape {
                        extents: Qt.vector3d(1, 1, 1)
                    }

                    Model {
                        geometry: CuboidGeometry {
                            xExtent: 1
                            yExtent: 1
                            zExtent: 1
                        }

                        materials: PrincipledMaterial {
                            baseColor: "Blue"
                            metalness: 0.1
                        }
                    }
                }
            }

            // Container for dynamically spawned cubes so they can be easily cleared
            Node {
                id: cubesContainer
            }

            Timer {
                id: cubeSpawner
                interval: 1
                running: true
                repeat: true

                property int maxCubes: Math.round(cubesSlider.value)
                property int dynamicCount: 0

                function resetCubes() {
                    running = false
                    for (let i = cubesContainer.children.length - 1; i >= 0; i--) {
                        cubesContainer.children[i].destroy()
                    }
                    dynamicCount = 0
                    running = true
                }

                onTriggered: {
                    if (dynamicCount < maxCubes) {
                        // Spread over the area around the start, 20 to 60 above the
                        // surface, rather than in one stream that shades everything
                        // below it.
                        const dir = view3D.spawnPosition.normalized().plus(
                                Qt.vector3d(Math.random() - 0.5, Math.random() - 0.5,
                                            Math.random() - 0.5).times(0.4)).normalized()
                        similarCube.createObject(cubesContainer, {
                            position: dir.times(view3D.planetSize * 0.5 + 20 + Math.random() * 40)
                        })
                        dynamicCount++
                    } else {
                        running = false
                    }
                }
            }

            CharacterController {
                id: playerController
                position: view3D.spawnPosition
                midAirControl: midAirSwitch.checked

                maximumStepHeight: stepHeightSlider.value
                slopeLimit: slopeLimitSlider.value
                sendTriggerReports: true
                slideOnSteepSlopes: slideSwitch.checked

                collisionShapes: CapsuleShape {
                    id: playerCapsule
                    diameter: 1.0
                    height: 1.8
                    eulerRotation.z: 90
                }

                PerspectiveCamera {
                    id: camera
                    clipNear: 0.1
                    clipFar: 10000
                    position: Qt.vector3d(0, 0.8, -0.6)
                    eulerRotation.x: wasd.rotationX
                    frustumCullingEnabled: true
                }

                movement: wasd.moveVector.times(Qt.vector3d(speedSlider.value, 3, speedSlider.value))
                //! [character-orientation]
                rotation: playerController.gravityOrientation.times(Quaternion.fromEulerAngles(0, wasd.rotationY, 0))
                //! [character-orientation]
            }
        }
    }

    Wasd {
        id: wasd
    }

    // Left Control Panel
    Control {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width: 290
        padding: 16

        background: Rectangle {
            id: controlPanel
            radius: 10

            color: "#CC181828"
            border.color: "#44FFFFFF"
            border.width: 1
        }

        contentItem: ScrollView {
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                id: panelLayout
                width: parent.width
                spacing: 12

                Text {
                    text: qsTr("Scene settings")
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                }

                // 1. Gravity Strength
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Gravity:")
                            color: "#DDDDDD"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: gravitySlider.value.toFixed(1)
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Slider {
                        id: gravitySlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 30.0
                        value: 9.8
                        stepSize: 0.2
                    }
                }

                // 2. Cubes Count
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Cubes:")
                            color: "#DDDDDD"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(cubesSlider.value)
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Slider {
                        id: cubesSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 1000
                        value: 500
                        stepSize: 10
                        onMoved: if (!pressed) cubeSpawner.resetCubes()
                        onPressedChanged: if (!pressed) cubeSpawner.resetCubes()
                    }
                }

                // 3. Planet Size
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Planet size:")
                            color: "#DDDDDD"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(planetSlider.value)
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Slider {
                        id: planetSlider
                        Layout.fillWidth: true
                        from: 200
                        to: 1200
                        value: view3D.planetSize
                        stepSize: 20
                        // Resizing rebuilds the planet, so only do it once the
                        // slider is released, and spawn the cubes again.
                        function apply() {
                            view3D.planetSize = value
                            cubeSpawner.resetCubes()
                        }
                        onMoved: if (!pressed) apply()
                        onPressedChanged: if (!pressed) apply()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#33FFFFFF"
                }

                Text {
                    text: qsTr("Character controller")
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                }

                // 4. Movement Speed
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Movement speed:")
                            color: "#DDDDDD"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: speedSlider.value.toFixed(1)
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Slider {
                        id: speedSlider
                        Layout.fillWidth: true
                        from: 1.0
                        to: 50.0
                        value: 14.0
                        stepSize: 0.5
                    }
                }

                // 5. Slope Limit (degrees)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Slope limit:")
                            color: "#DDDDDD"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: slopeLimitSlider.value.toFixed(0) + "°"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Slider {
                        id: slopeLimitSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 89
                        value: 20
                        stepSize: 1
                    }
                }

                // 6. Maximum Step Height
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Max step height:")
                            color: "#DDDDDD"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: stepHeightSlider.value.toFixed(2)
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Slider {
                        id: stepHeightSlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 2.0
                        value: 0.35
                        stepSize: 0.01
                    }
                }

                // 7. Slide On Steep Slopes Toggle
                Switch {
                    id: slideSwitch
                    Layout.fillWidth: true
                    checked: true
                    text: qsTr("Slide down steep slopes")

                    contentItem: Text {
                        text: slideSwitch.text
                        color: "#DDDDDD"
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: slideSwitch.indicator.width + slideSwitch.spacing
                    }
                }

                // 8. Mid-Air Control Toggle
                Switch {
                    id: midAirSwitch
                    Layout.fillWidth: true
                    checked: false
                    text: qsTr("Mid-air control")

                    contentItem: Text {
                        text: midAirSwitch.text
                        color: "#DDDDDD"
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: midAirSwitch.indicator.width + midAirSwitch.spacing
                    }
                }

                // Reset Player Position Button (useful if planet size changes)
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Reset character")
                    onClicked: {
                        playerController.teleport(view3D.spawnPosition)
                    }
                }
            }
        }
    }
}
