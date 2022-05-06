/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the test suite of the Qt Toolkit.
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

import QtCore
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick

Item {
    width: 640
    height: 480
    visible: true

    DynamicsWorld {
        gravity: Qt.vector3d(0, -9.81, 0)
        running: true
        forceDebugView: true
        typicalLength: 1
        typicalSpeed: 10
    }
    property bool simulationActuallyRunning: false

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        Node {
            id: scene
            PerspectiveCamera {
                id: camera1
                position: Qt.vector3d(0, 5, 10)
                eulerRotation: Qt.vector3d(-20, 0, 0)
                clipFar: 50
                clipNear: 0.01
            }

            DirectionalLight {
                eulerRotation.x: -45
                eulerRotation.y: 45
            }

            Node {
                id: fallingBoxNode
                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape {
                        extents: Qt.vector3d(2,1,2)
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(2, 1, 2).times(0.01)
                        eulerRotation: Qt.vector3d(0, 90, 0)
                        materials: DefaultMaterial {
                            diffuseColor: "green"
                        }
                    }
                }

                TestCube {
                    id: fallingBox
                    color: "yellow"
                }
            }

            Node {
                id: triggerNode
                x: 5

                TriggerBody {
                    id: triggerBox
                    position: Qt.vector3d(0, 3, 0)
                    collisionShapes: BoxShape {
                        extents: Qt.vector3d(1, 2, 1)
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

                DynamicRigidBody {
                    id: collisionSphere
                    density: 1000
                    position: Qt.vector3d(0, 6, 0)
                    enableTriggerReports: true
                    property bool inArea: false

                    collisionShapes: SphereShape {
                        id: sphereShape
                        diameter: 1
                    }
                    Model {
                        source: "#Sphere"
                        materials: PrincipledMaterial {
                            baseColor: collisionSphere.inArea ? "yellow" : "red"
                        }
                        scale: Qt.vector3d(0.01, 0.01, 0.01)
                    }
                }
            }

            Node {
                id: dynamicCreationNode
                x: -5
                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape {
                        extents: Qt.vector3d(2,1,2)
                    }
                    Model {
                        source: "#Cube"
                        scale: Qt.vector3d(2, 1, 2).times(0.01)
                        eulerRotation: Qt.vector3d(0, 90, 0)
                        materials: DefaultMaterial {
                            diffuseColor: "red"
                        }
                    }
                }

                property var createdObject: null
                property bool createdObjectIsStable: createdObject ? createdObject.stable : false
                function checkStable() {
                    if (createdObject)
                        createdObject.checkStable()
                }
                Component {
                    id: spawnComponent
                    TestCube {
                      color: "cyan"
                      y: 1
                    }
                }

                TestCase {
                    name: "DynamicCreation"
                    when: dynamicCreationNode.createdObjectIsStable
                    function test_created_object_is_simulated() {
                        fuzzyCompare(dynamicCreationNode.createdObject.y, 0, 0.001)
                    }
                }
            }

            Node {
                id: frictionNode
                z: -10
                eulerRotation.z: 20
                PhysicsMaterial {
                    id: frictionMaterial
                    dynamicFriction: 0
                    staticFriction: 0
                }
                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape {
                        id: slide
                        extents: Qt.vector3d(10, 1, 2)
                    }
                    physicsMaterial: frictionMaterial

                    Model {
                        source: "#Cube"
                        scale: slide.extents.times(0.01)
                        materials: DefaultMaterial {
                            diffuseColor: "orange"
                        }
                    }
                }
                TestCube {
                    id: slidingBox
                    x: 4
                    color: "red"
                    physicsMaterial: frictionMaterial
                    property real brakePoint: -9999
                }
                TestCase {
                    name: "Friction"
                    when: timer.simulationSteps > 20
                    function test_low_friction() {
                        verify(!slidingBox.stable)
                        verify(slidingBox.x < 4)
                    }
                    function test_set_high_friction() {
                        frictionMaterial.dynamicFriction = 0.5
                        frictionMaterial.staticFriction = 0.5
                        slidingBox.brakePoint = slidingBox.x
                    }
                }
                TestCase {
                    name: "Friction2"
                    when: slidingBox.stable
                    function test_high_friction() {
                        fuzzyCompare(slidingBox.y, 0, 0.001)
                        verify(slidingBox.x < slidingBox.brakePoint)
                    }
                }
            }

            Node {
                id: heightFieldNode
                z: -5
                x: -5
                StaticRigidBody {
                    position: "0, 0, 0"
                    collisionShapes: HeightFieldShape {
                        extents: Qt.vector3d(4, 4, 4)
                        heightMap: "hf.png"
                    }
                    physicsMaterial: frictionMaterial
                }

                DynamicRigidBody {
                    density: 1000
                    scale: "0.5, 0.5, 0.5"
                    position: Qt.vector3d(1, 2, 1)
                    id: hfBall

                    collisionShapes: SphereShape {
                        diameter: 1
                    }
                    Model {
                        source: "#Sphere"
                        materials: PrincipledMaterial {
                            baseColor: "yellow"
                        }
                        scale: Qt.vector3d(0.01, 0.01, 0.01)
                    }
                    property bool stable: false
                    property vector3d prevPos: "9999,9999,9999"
                    property vector3d prevPos2: "9999,9999,9999"
                    function fuzzyEquals(a, b) {
                        return Math.abs(a.x - b.x) < 0.01 && Math.abs(a.y - b.y) < 0.001 && Math.abs(a.z - b.z) < 0.01
                    }
                    function checkStable() {
                        // Compare against the previous two positions to avoid triggering on the top of a bounce
                        if (fuzzyEquals(position, prevPos) && fuzzyEquals(position, prevPos2)) {
                            stable = true
                        } else {
                            prevPos2 = prevPos
                            prevPos = position
                        }
                    }
                }

                TestCase {
                    name: "HeightField"
                    when: hfBall.stable
                    function test_ball_position() {
                        fuzzyCompare(hfBall.y, -1.75, 0.01)
                    }
                }
            }


            // Trick to get a callback when the physics simulation advances, no matter how slowly the CI machine is running
            DynamicRigidBody {
                id: timer
                position: "-10, 100, -10"
                collisionShapes: SphereShape {
                    diameter: 2
                }
                property int simulationSteps: 0
                onPositionChanged: {
                    // Only do the check(s) every other step, since we have no guarantees on signal emission order
                    if (simulationSteps % 2) {
                        fallingBox.checkStable()
                        dynamicCreationNode.checkStable()
                        slidingBox.checkStable()
                        hfBall.checkStable()
                        simulationActuallyRunning = true
                    }
                    simulationSteps++
                }
            }
        }
    }

    TestCase {
        name: "SceneStart"
        when: simulationActuallyRunning
        function test_collision_sphere() {
            verify(!collisionSphere.inArea)
            compare(triggerEnterSpy.count, 0)
            compare(triggerExitSpy.count, 0)
        }
        function test_falling_box() {
            verify(fallingBox.y > 0)
        }
        function test_spawn() {
            var obj = spawnComponent.createObject(dynamicCreationNode)
            verify(obj.y === 1)
            dynamicCreationNode.createdObject = obj
        }
    }

    TestCase {
        name: "FallingBox"
        when: fallingBox.stable
        function test_stable_position() {
            fuzzyCompare(fallingBox.y, 0, 0.0001)
            fuzzyCompare(fallingBox.eulerRotation.x, 0, 0.1)
            fuzzyCompare(fallingBox.eulerRotation.z, 0, 0.1)
        }
    }

    TestCase {
        name: "TriggerBody"
        when: collisionSphere.y < 0
        function test_enter_exit() {
            compare(triggerEnterSpy.count, 1)
            compare(triggerExitSpy.count, 1)
        }
        SignalSpy {
            id: triggerEnterSpy
            target: triggerBox
            signalName: "onBodyEntered"
        }
        SignalSpy {
            id: triggerExitSpy
            target: triggerBox
            signalName: "onBodyExited"
        }
    }
}
