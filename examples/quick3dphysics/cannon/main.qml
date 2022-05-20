/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: appWindow
    width: 800
    height: 600
    visible: true
    title: qsTr("Qt Quick 3D Physics - Cannon")

    DynamicsWorld {}

    View3D {
        width: parent.width
        height: parent.height
        focus: true

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            backgroundMode: SceneEnvironment.Color
            clearColor: "#f0f0f0"
        }

        //! [camera]
        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(-4000, 5000, 10000)
            eulerRotation : Qt.vector3d(-20, -20, 0)
            clipFar: 500000
            clipNear: 100
        }
        //! [camera]

        //! [light]
        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
            castsShadow: true
            brightness: 1
            shadowMapQuality: Light.ShadowMapQualityVeryHigh
            shadowFactor: 100
        }
        //! [light]

        //! [floor]
        StaticRigidBody {
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                scale: Qt.vector3d(2000, 2000, 0)
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }
        //! [floor]

        //! [spawner]
        Node {
            id: shapeSpawner
            property var instancesBoxes: []
            property var instancesSpheres: []
            property int stackCount: 0

            function createStack(stackZ) {
                var size = 10;
                var extents = 400;

                for (var i = 0; i < size; i++) {
                    for (var j = 0; j < size-i; j++) {
                        var component = Qt.createComponent("box.qml");
                        let x = j*2 - size + i;
                        let y = i*2 + 1;
                        let z = -5*stackZ;
                        let center = Qt.vector3d(x, y, z).times(0.5*extents);
                        let box = component.createObject(shapeSpawner, {position: center, xyzExtents: extents});
                        instancesBoxes.push(box);

                        if (box === null) {
                            console.log("Error creating object");
                        }
                    }
                }
            }

            function createBall(position, forward) {
                var diameter = 600;
                var speed = 20000;
                var component = Qt.createComponent("sphere.qml");
                let sphere = component.createObject(shapeSpawner, {position: position, linearVelocity: forward.times(speed), sphereDiameter: diameter});
                instancesSpheres.push(sphere);

                if (sphere === null) {
                    console.log("Error creating object");
                }
            }

            function reset() {
                instancesSpheres.forEach(sphere => { sphere.destroy(); });
                instancesBoxes.forEach(boxes => { boxes.destroy(); });
                instancesSpheres = [];
                instancesBoxes = [];

                for (var stackI = 0; stackI < stackSlider.value; stackI++) {
                    shapeSpawner.createStack(stackI);
                }
            }
        }
        //! [spawner]
        Crosshair {
            id: crossHair
            anchors.centerIn: parent
        }
    }

    Component.onCompleted: {
        shapeSpawner.reset()
    }

    WasdController {
        speed: 100
        controlledObject: camera
        Keys.onPressed: (event)=> {
                            handleKeyPress(event);
                            if (event.key === Qt.Key_Space) {
                                shapeSpawner.createBall(camera.position, camera.forward);
                            }
                        }
        Keys.onReleased: (event)=> { handleKeyRelease(event) }
    }

    Frame {
        background: Rectangle {
            color: "#c0c0c0"
            border.color: "#202020"
        }
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        ColumnLayout {
            Label {
                text: "No. Stacks: " + stackSlider.value.toFixed(0)
            }
            Slider {
                id: stackSlider
                focusPolicy: Qt.NoFocus
                from: 1
                to: 9
                value: 4
                stepSize: 1
                snapMode: Slider.SnapOnRelease
            }
            Button {
                id: resetButton
                Layout.alignment: Qt.AlignHCenter
                text: "Reset scene"
                onClicked: shapeSpawner.reset()
            }
            Button {
                id: fireButton
                Layout.alignment: Qt.AlignHCenter
                text: "Fire!"
                onClicked: shapeSpawner.createBall(camera.position, camera.forward)
            }
        }
    }

}
