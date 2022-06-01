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
import QtQuick3D.Helpers
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Qt Quick 3D Physics - Mass")

    //! [world]
    DynamicsWorld {
        running: true
        gravity: Qt.vector3d(0, -9.81, 0)
        typicalLength: 1
        typicalSpeed: 10
    }
    //! [world]

    //! [scene]
    View3D {
        id: viewport
        anchors.fill: parent

        //! [environment]
        environment: SceneEnvironment {
            clearColor: "lightblue"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 2, 5)
            eulerRotation: Qt.vector3d(-10, 0, 0)
            clipFar: 100
            clipNear: 0.01
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
            castsShadow: true
            brightness: 1
            shadowFactor: 100
        }
        //! [environment]

        //! [plane]
        StaticRigidBody {
            position: Qt.vector3d(0, 0, 0)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                materials: DefaultMaterial {
                    diffuseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }
        //! [plane]

        //! [rolypolys]
        RolyPoly {
            position: Qt.vector3d(-2, 0.5, 0)
            color: "blue"

            mass: 0.9
            centerOfMassPosition: Qt.vector3d(0, -0.5, 0)
            inertiaTensor: Qt.vector3d(0.217011, 0.0735887, 0.217011)
            massMode: DynamicRigidBody.MassAndInertiaTensor
        }

        RolyPoly {
            position: Qt.vector3d(0, 0.5, 0)
            color: "purple"

            mass: 0.9
            centerOfMassPosition: Qt.vector3d(0, -0.5, 0)
            inertiaTensor: Qt.vector3d(0.05, 100, 100)
            massMode: DynamicRigidBody.MassAndInertiaTensor
        }

        RolyPoly {
            position: Qt.vector3d(2, 0.5, 0)
            color: "red"

            mass: 0.9
            massMode: DynamicRigidBody.Mass
        }
        //! [rolypolys]

        //! [spawner]
        Node {
            id: shapeSpawner
            property var spheres: []

            function createBall(position, forward) {
                let diameter = 0.2;
                let speed = 20;
                let settings = {
                    position: position,
                    linearVelocity: forward.times(speed),
                    sphereDiameter: diameter
                };
                var component = Qt.createComponent("sphere.qml");
                let sphere = component.createObject(shapeSpawner, settings);

                var pair = {
                    "sphere" : sphere,
                    "date" : Date.now()
                };

                spheres.push(pair);

                if (sphere === null) {
                    console.log("Error creating object");
                }
            }

            function clean() {
                spheres = spheres.filter(sphere => {
                    let diff = Date.now() - sphere['date'];
                    if (diff > 5000) {
                        sphere['sphere'].destroy();
                        return false;
                    }
                    return true;
                });
            }

            Timer {
                interval: 200
                running: true
                repeat: true
                onTriggered: shapeSpawner.clean()
            }
        }
        //! [spawner]

    }
    //! [scene]

    //! [controller]
    WasdController {
        speed: 0.01
        controlledObject: camera
        Keys.onPressed: (event)=> {
            handleKeyPress(event);
            if (event.key === Qt.Key_Space) {
                shapeSpawner.createBall(camera.position, camera.forward);
            }
        }
        Keys.onReleased: (event)=> { handleKeyRelease(event) }
    }
    //! [controller]
}
