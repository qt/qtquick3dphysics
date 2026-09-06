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
    title: qsTr("Qt Quick 3D Physics - Queries")

    property int currentMode: 0
    property real playerYaw: 0
    property real cameraPitch: -15

    property bool keyW: false
    property bool keyS: false
    property bool keyA: false
    property bool keyD: false
    property bool keySpace: false

    readonly property var modeDetails: [
        { name: "1. Single Probe", type: "PROBE", desc: "Closest body along a ray (singleRaycastQuery)" },
        { name: "2. Piercing Probe", type: "PROBE", desc: "Every body along a ray (multiRaycastQuery)" },
        { name: "3. Volume Probe", type: "PROBE", desc: "Closest body along a sweep (singleSweepQuery)" },
        { name: "4. Piercing Volume Probe", type: "PROBE", desc: "Every body along a sweep (multiSweepQuery)" },
        { name: "5. Radial Pulse", type: "PROBE", desc: "Every body in a volume (multiOverlapQuery)" },
        { name: "6. Line-of-Sight Scanner", type: "SCANNER", desc: "Is the ray blocked? (testRaycastQuery)" },
        { name: "7. Clearance Scanner", type: "SCANNER", desc: "Is the corridor clear? (testSweepQuery)" },
        { name: "8. Occupancy Scanner", type: "SCANNER", desc: "Is the volume occupied? (testOverlapQuery)" }
    ]

    Timer {
        id: autoFireTimer
        interval: 150
        repeat: true
        onTriggered: {
            if (window.keySpace) {
                window.runQuery();
            } else {
                autoFireTimer.stop();
            }
        }
    }

    function updateShootingState() {
        if (keySpace) {
            if (!autoFireTimer.running) {
                runQuery();
                autoFireTimer.start();
            }
        } else {
            autoFireTimer.stop();
        }
    }

    Item {
        id: inputController
        anchors.fill: parent
        focus: true

        Component.onCompleted: inputController.forceActiveFocus()

        Keys.onPressed: (event) => {
            let k = event.key;
            let t = event.text.toLowerCase();

            if (k === Qt.Key_W || t === "w") window.keyW = true;
            if (k === Qt.Key_S || t === "s") window.keyS = true;
            if (k === Qt.Key_A || t === "a") window.keyA = true;
            if (k === Qt.Key_D || t === "d") window.keyD = true;

            if (k === Qt.Key_Space && !event.isAutoRepeat) {
                window.keySpace = true;
                window.updateShootingState();
            }

            if (k >= Qt.Key_1 && k <= Qt.Key_8) {
                window.currentMode = k - Qt.Key_1;
            }
        }

        Keys.onReleased: (event) => {
            let k = event.key;
            let t = event.text.toLowerCase();

            if (k === Qt.Key_W || t === "w") window.keyW = false;
            if (k === Qt.Key_S || t === "s") window.keyS = false;
            if (k === Qt.Key_A || t === "a") window.keyA = false;
            if (k === Qt.Key_D || t === "d") window.keyD = false;

            if (k === Qt.Key_Space) {
                window.keySpace = false;
                window.updateShootingState();
            }
        }
    }

    View3D {
        id: view
        anchors.fill: parent

//! [physics-world-setup]
        PhysicsWorld {
            id: physicsWorld
            scene: view.scene
            running: true
            gravity: Qt.vector3d(0, -981, 0)
        }

        // Shapes used for Sweep and Overlap queries
        SphereShape { id: querySphereShape; diameter: 200 }
        BoxShape { id: queryBoxShape; extents: Qt.vector3d(200, 200, 200) }
//! [physics-world-setup]

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property point lastPos: Qt.point(0, 0)

            onPressed: (mouse) => {
                inputController.forceActiveFocus();
                lastPos = Qt.point(mouse.x, mouse.y);
            }

            onPositionChanged: (mouse) => {
                if (pressedButtons & Qt.RightButton || pressedButtons & Qt.LeftButton) {
                    let dx = mouse.x - lastPos.x;
                    let dy = mouse.y - lastPos.y;

                    window.playerYaw -= dx * 0.25;
                    window.cameraPitch = Math.max(-60, Math.min(30, window.cameraPitch - dy * 0.25));
                    lastPos = Qt.point(mouse.x, mouse.y);
                }
            }

            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    window.currentMode = (window.currentMode + 1) % window.modeDetails.length;
                } else {
                    window.currentMode = (window.currentMode - 1 + window.modeDetails.length)
                                       % window.modeDetails.length;
                }
            }
        }

        environment: SceneEnvironment {
            clearColor: "#0f111a"
            backgroundMode: SceneEnvironment.Color
        }

        CharacterController {
            id: player
            position: Qt.vector3d(0, 150, 1200)
            eulerRotation.y: window.playerYaw
            gravity: physicsWorld.gravity

            collisionShapes: CapsuleShape {
                diameter: 80
                height: 180
            }

            Model {
                source: "#Cylinder"
                scale: Qt.vector3d(0.8, 1.8, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#00d2d3" } ]
            }

            Node {
                id: cameraRig
                eulerRotation.x: window.cameraPitch

                PerspectiveCamera {
                    id: camera
                    position: Qt.vector3d(0, 200, 500)
                    eulerRotation.x: -10
                    clipNear: 1
                }
            }
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 30, 0)
            brightness: 1.5
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -50, 0)
            collisionShapes: BoxShape { extents: Qt.vector3d(6000, 100, 6000) }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(60, 1, 60)
                materials: [ PrincipledMaterial { baseColor: "#1e272e" } ]
            }
        }

        component ArenaWall : StaticRigidBody {
            property vector3d wallSize: Qt.vector3d(100, 100, 100)
            collisionShapes: BoxShape { extents: wallSize }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(wallSize.x * 0.01, wallSize.y * 0.01, wallSize.z * 0.01)
                materials: [ PrincipledMaterial { baseColor: "#34495e" } ]
            }
        }

        ArenaWall { position: Qt.vector3d(0, 300, -3000); wallSize: Qt.vector3d(6000, 600, 200) }
        ArenaWall { position: Qt.vector3d(0, 300, 3000); wallSize: Qt.vector3d(6000, 600, 200) }
        ArenaWall { position: Qt.vector3d(-3000, 300, 0); wallSize: Qt.vector3d(200, 600, 6000) }
        ArenaWall { position: Qt.vector3d(3000, 300, 0); wallSize: Qt.vector3d(200, 600, 6000) }

        component DynamicCube : DynamicRigidBody {
            id: cubeRoot
            property color cubeColor: "#e67e22"
            collisionShapes: BoxShape { extents: Qt.vector3d(100, 100, 100) }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(1, 1, 1)
                materials: [ PrincipledMaterial { baseColor: cubeRoot.cubeColor } ]
            }
        }

        component DynamicSphere : DynamicRigidBody {
            id: sphereRoot
            property color sphereColor: "#1abc9c"
            collisionShapes: SphereShape { diameter: 100 }
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(1, 1, 1)
                materials: [ PrincipledMaterial { baseColor: sphereRoot.sphereColor } ]
            }
        }

        // --- MASSIVE DYNAMIC OBJECTS GENERATOR (500+ BODIES) ---
        Component { id: dynamicCubeComp; DynamicCube {} }
        Component { id: dynamicSphereComp; DynamicSphere {} }

        Component.onCompleted: {
            let colors = ["#e74c3c", "#e67e22", "#f1c40f", "#2ecc71", "#3498db", "#9b59b6", "#1abc9c", "#e84393"];

            // Generate a huge wall of dynamic objects (18 x 7 x 4 grid = ~500 objects)
            for (let x = -1000; x <= 1000; x += 120) {
                for (let y = 50; y <= 850; y += 120) {
                    for (let z = -1000; z >= -1400; z -= 120) {
                        let isSphere = (Math.random() > 0.5);
                        let comp = isSphere ? dynamicSphereComp : dynamicCubeComp;
                        let randomColor = colors[Math.floor(Math.random() * colors.length)];

                        comp.createObject(view.scene, {
                            "position": Qt.vector3d(x + (Math.random() * 5), y, z + (Math.random() * 5)),
                            "cubeColor": randomColor,
                            "sphereColor": randomColor
                        });
                    }
                }
            }
        }

        Node {
            id: tracerBeam
            visible: false
            Model {
                id: tracerMesh
                source: "#Cylinder"
                scale: Qt.vector3d(1, 1, 1)
                materials: [
                    PrincipledMaterial {
                        id: tracerMat
                        baseColor: "#f1c40f"
                        opacity: 0.5
                        alphaMode: PrincipledMaterial.Blend
                        lighting: PrincipledMaterial.NoLighting
                    }
                ]
            }
        }
        Timer { id: tracerTimer; interval: 150; onTriggered: tracerBeam.visible = false }

        Model {
            id: volumeGhost
            visible: false
            materials: [
                PrincipledMaterial {
                    id: ghostMat
                    baseColor: "#3300ff00"
                    alphaMode: PrincipledMaterial.Blend
                    opacity: 0.4
                    lighting: PrincipledMaterial.NoLighting
                }
            ]
        }
    }

    FrameAnimation {
        running: true
        onTriggered: {
            let speed = 800;
            let moveX = 0;
            let moveZ = 0;

            if (window.keyW) moveZ -= 1;
            if (window.keyS) moveZ += 1;
            if (window.keyA) moveX -= 1;
            if (window.keyD) moveX += 1;

            let len = Math.sqrt(moveX * moveX + moveZ * moveZ);
            if (len > 0) {
                moveX /= len;
                moveZ /= len;
                player.movement = Qt.vector3d(moveX * speed, 0, moveZ * speed);
            } else {
                player.movement = Qt.vector3d(0, 0, 0);
            }

            let rad = player.eulerRotation.y * Math.PI / 180.0;
            let forwardWorld = Qt.vector3d(-Math.sin(rad), 0, -Math.cos(rad)).normalized();

            window.updateScannerState(forwardWorld);
        }
    }

//! [probe-origin]
    // The player's own collider is an ordinary hit candidate, so a query starting at
    // the character's center would hit its own capsule at distance 0. Start the query
    // slightly above and in front of the capsule instead.
    function probeOrigin(forwardDir) {
        return player.position.plus(Qt.vector3d(0, 50, 0)).plus(forwardDir.times(150));
    }
//! [probe-origin]

    // Only a DynamicRigidBody can take an impulse. The queries here also return the
    // static arena and the player's own character controller.
    function pushBody(body, impulse) {
        if (body instanceof DynamicRigidBody)
            body.applyCentralImpulse(impulse);
    }

    function runQuery() {
        if (currentMode >= 5) {
            statusText.text = "Scanner mode: modes 1-5 are triggered manually";
            return;
        }

        let rad = player.eulerRotation.y * Math.PI / 180.0;
        let pitchRad = cameraRig.eulerRotation.x * Math.PI / 180.0;

        let forwardDir = Qt.vector3d(
            -Math.sin(rad) * Math.cos(pitchRad),
            Math.sin(pitchRad),
            -Math.cos(rad) * Math.cos(pitchRad)
        ).normalized();

        let origin = window.probeOrigin(forwardDir);
        let maxDist = 3000;

        switch (currentMode) {

//! [mode-single-raycast]
        case 0: // singleRaycastQuery
            let hit1 = physicsWorld.singleRaycastQuery(origin, forwardDir, maxDist, true, true);

            // hit.body === null is the miss test; distance is 0 on a miss.
            let dist1 = hit1.body ? hit1.distance : maxDist;
            renderTracer(origin, forwardDir, dist1, "#f1c40f", 10, 10, false);

            if (hit1.body) {
                window.pushBody(hit1.body, forwardDir.times(250000));
                statusText.text = "singleRaycastQuery: hit at " + Math.round(hit1.distance) + " cm";
            } else {
                statusText.text = "singleRaycastQuery: missed";
            }
            break;
//! [mode-single-raycast]

//! [mode-multi-raycast]
        case 1: // multiRaycastQuery
            let hits2 = physicsWorld.multiRaycastQuery(origin, forwardDir, maxDist, true, true);
            renderTracer(origin, forwardDir, maxDist, "#3498db", 10, 10, false);

            for (let i = 0; i < hits2.length; ++i)
                window.pushBody(hits2[i].body, forwardDir.times(200000));

            statusText.text = "multiRaycastQuery: hit count " + hits2.length;
            break;
//! [mode-multi-raycast]

//! [mode-single-sweep]
        case 2: // singleSweepQuery
            querySphereShape.position = origin;
            let hit3 = physicsWorld.singleSweepQuery(querySphereShape, forwardDir, maxDist, true, true);

            // A sweep that starts already overlapping a body reports a negative
            // distance, so test body rather than distance to detect a miss.
            let dist3 = hit3.body ? Math.max(hit3.distance, 0) : maxDist;

            // Cylinder matching the swept SphereShape diameter
            renderTracer(origin, forwardDir, dist3, "#e74c3c", 200, 200, false);

            if (hit3.body) {
                window.pushBody(hit3.body, forwardDir.times(300000));
                statusText.text = "singleSweepQuery: hit at " + Math.round(hit3.distance) + " cm";
            } else {
                statusText.text = "singleSweepQuery: missed";
            }
            break;
//! [mode-single-sweep]

//! [mode-multi-sweep]
        case 3: // multiSweepQuery
            queryBoxShape.position = origin;
            let hits4 = physicsWorld.multiSweepQuery(queryBoxShape, forwardDir, maxDist, true, true);

            // Translucent box corridor along the sweep trajectory
            renderTracer(origin, forwardDir, maxDist, "#9b59b6", 200, 200, true);

            for (let j = 0; j < hits4.length; ++j)
                window.pushBody(hits4[j].body, forwardDir.times(250000));

            statusText.text = "multiSweepQuery: hit count " + hits4.length;
            break;
//! [mode-multi-sweep]

//! [mode-multi-overlap]
        case 4: // multiOverlapQuery
            let pulseCenter = origin.plus(forwardDir.times(600));
            querySphereShape.position = pulseCenter;

            let overlapHits = physicsWorld.multiOverlapQuery(querySphereShape, true, true);

            volumeGhost.source = "#Sphere";
            volumeGhost.position = pulseCenter;
            volumeGhost.scale = Qt.vector3d(2, 2, 2);
            ghostMat.baseColor = "#e74c3c";
            volumeGhost.visible = true;

            for (let k = 0; k < overlapHits.length; ++k) {
                let body5 = overlapHits[k].body;
                if (!body5)
                    continue;
                let pushDir = body5.position.minus(pulseCenter);
                pushDir = pushDir.length() > 0 ? pushDir.normalized() : Qt.vector3d(0, 1, 0);
                window.pushBody(body5, pushDir.times(350000).plus(Qt.vector3d(0, 100000, 0)));
            }
            statusText.text = "multiOverlapQuery: hit count " + overlapHits.length;
            break;
//! [mode-multi-overlap]
        }
    }

    function updateScannerState(forwardDir) {
        if (currentMode < 5) {
            if (currentMode !== 4) volumeGhost.visible = false;
            return;
        }

        let origin = window.probeOrigin(forwardDir);
        let scanDist = 1200;

        switch (currentMode) {

//! [mode-test-raycast]
        case 5: // testRaycastQuery
            let isBlocked5 = physicsWorld.testRaycastQuery(origin, forwardDir, scanDist, true, true);
            renderTracer(origin, forwardDir, scanDist, isBlocked5 ? "#ff2d55" : "#00ff66", 10, 10, false);

            statusText.text = isBlocked5 ? "testRaycastQuery: blocked" : "testRaycastQuery: path clear";
            statusText.color = isBlocked5 ? "#ff2d55" : "#00ff66";
            break;
//! [mode-test-raycast]

//! [mode-test-sweep]
        case 6: // testSweepQuery
            querySphereShape.position = origin;
            let isBlocked6 = physicsWorld.testSweepQuery(querySphereShape, forwardDir, scanDist, true, true);

            volumeGhost.source = "#Sphere";
            volumeGhost.position = origin.plus(forwardDir.times(scanDist));
            volumeGhost.scale = Qt.vector3d(2, 2, 2);
            ghostMat.baseColor = isBlocked6 ? "#ff2d55" : "#00ff66";
            volumeGhost.visible = true;

            statusText.text = isBlocked6 ? "testSweepQuery: corridor blocked" : "testSweepQuery: corridor clear";
            statusText.color = isBlocked6 ? "#ff2d55" : "#00ff66";
            break;
//! [mode-test-sweep]

//! [mode-test-overlap]
        case 7: // testOverlapQuery
            let checkZone = origin.plus(forwardDir.times(500));
            querySphereShape.position = checkZone;
            let isOccupied = physicsWorld.testOverlapQuery(querySphereShape, true, true);

            volumeGhost.source = "#Sphere";
            volumeGhost.position = checkZone;
            volumeGhost.scale = Qt.vector3d(2, 2, 2);
            ghostMat.baseColor = isOccupied ? "#ff2d55" : "#00ff66";
            volumeGhost.visible = true;

            statusText.text = isOccupied ? "testOverlapQuery: volume occupied" : "testOverlapQuery: volume empty";
            statusText.color = isOccupied ? "#ff2d55" : "#00ff66";
            break;
//! [mode-test-overlap]
        }
    }

    function renderTracer(origin, forwardDir, dist, colorHex, thicknessX, thicknessY, isBox) {
        thicknessX = thicknessX !== undefined ? thicknessX : 10;
        thicknessY = thicknessY !== undefined ? thicknessY : 10;
        isBox = isBox !== undefined ? isBox : false;

        tracerMesh.source = isBox ? "#Cube" : "#Cylinder";
        tracerBeam.position = origin.plus(forwardDir.times(dist / 2));
        tracerBeam.eulerRotation = Qt.vector3d(cameraRig.eulerRotation.x, player.eulerRotation.y, 0);

        tracerMesh.scale = Qt.vector3d(thicknessX * 0.01, thicknessY * 0.01, dist * 0.01);
        tracerMat.baseColor = colorHex;
        tracerMat.opacity = (thicknessX > 50) ? 0.35 : 0.8;

        tracerBeam.visible = true;
        tracerTimer.restart();
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 15
        spacing: 10

        Rectangle {
            implicitWidth: 420
            implicitHeight: 200
            color: "#d910141d"
            radius: 8
            border.color: "#34495e"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    text: "PHYSICS SCENE QUERIES"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                }

                ComboBox {
                    id: modeSelect
                    Layout.fillWidth: true
                    model: window.modeDetails.map(item => "[" + item.type + "] " + item.name)
                    currentIndex: window.currentMode
                    focusPolicy: Qt.NoFocus
                    onActivated: (index) => {
                        window.currentMode = index;
                        inputController.forceActiveFocus();
                    }
                }

                Text {
                    text: window.modeDetails[window.currentMode].desc
                    color: "#f1c40f"
                    font.pixelSize: 12
                    font.italic: true
                }

                Text {
                    text: "Controls:"
                          + "\n- WASD: Move character"
                          + "\n- Hold Mouse Drag: Rotate camera"
                          + "\n- Spacebar: Run the selected query"
                          + "\n- Keys 1-8: Switch query modes"
                    color: "#bdc3c7"
                    font.pixelSize: 11
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    color: "#000000"
                    radius: 4

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        color: "#00ff66"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }
    }
}
