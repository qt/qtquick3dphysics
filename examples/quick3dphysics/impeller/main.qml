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

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Qt Quick 3D Physics - Impeller")

    //! [world]
    DynamicsWorld {
        gravity: Qt.vector3d(0, -490, 0)
    }
    //! [world]

    //! [scene]
    View3D {
        anchors.fill: parent

        //! [environment]
        environment: SceneEnvironment {
            clearColor: "#d6dbdf"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 200, 1000)
            clipFar: 2000
            clipNear: 1
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
            position: Qt.vector3d(0, -100, 0)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                scale: Qt.vector3d(500, 500, 0)
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }
        //! [plane]

        //! [sphere]
        DynamicRigidBody {
            id: sphere
            density: 0.00001
            position: Qt.vector3d(0, 600, 0)
            property bool inArea: false
            sendContactReports: true
            enableTriggerReports: true

            collisionShapes: SphereShape {}
            Model {
                source: "#Sphere"
                materials: PrincipledMaterial {
                    baseColor: sphere.inArea ? "yellow" : "red"
                }
            }
        }
        //! [sphere]

        //! [box]
        TriggerBody {
            position: Qt.vector3d(0, 350, 0)
            scale: Qt.vector3d(1, 2, 1)

            collisionShapes: BoxShape {
                id: boxShape
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: Qt.rgba(1, 0, 1, 0.2)
                    alphaMode: PrincipledMaterial.Blend
                }
            }

            onBodyEntered: (body) => {
                if (body.hasOwnProperty('inArea'))
                    body.inArea = true;
            }
            onBodyExited: (body) => {
                if (body.hasOwnProperty('inArea'))
                    body.inArea = false;
            }
        }
        //! [box]

        //! [impeller]
        StaticRigidBody {
            position: Qt.vector3d(0, 0, 0)
            scale: Qt.vector3d(2, 2, 2)
            receiveContactReports: true

            collisionShapes: SphereShape {}

            Model {
                source: "#Sphere"
                materials: PrincipledMaterial {
                    baseColor: "blue"
                }
            }

            onBodyContact: (body, positions, impulses, normals) => {
                for (var normal of normals) {
                    let force = normal.times(-2000);
                    body.applyCentralImpulse(force);
                }
            }
        }
        //! [impeller]
    }
    //! [scene]
}
