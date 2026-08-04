// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Tests that removing and adding joints does not crash.

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils
import QtQuick3D.Physics.Helpers

Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        scene: scene
    }

    View3D {
        id: viewport
        width: parent.width
        height: parent.height
        focus: true

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            backgroundMode: SceneEnvironment.Color
            clearColor: "#f0f0f0"
        }

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(-400, 500, 1000)
            eulerRotation: Qt.vector3d(-20, -20, 0)
            clipFar: 5000
            clipNear: 1
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
        }

        Node {
            id: scene

            SphericalJoint {
                id: sphericalJoint
                 coneLimitY: Math.PI/8
                 coneLimitZ: Math.PI/8
                 bodyB: boxA
                 positionA: Qt.vector3d(100, 0, 0)
                 positionB: Qt.vector3d(-100, 0, 0)
                 enableConeLimit: true
            }

            DynamicRigidBody {
                id: boxA
                position: Qt.vector3d(-100, 200, 0)
                kinematicPosition: Qt.vector3d(-100, 200, 0)
                scale: Qt.vector3d(2, 0.5, 0.5)
                collisionShapes: BoxShape {}
                Model {
                    source: "#Cube"
                    materials: PrincipledMaterial {
                        baseColor: "yellow"
                    }
                }
                isKinematic: true
            }

            DynamicRigidBody {
                id: boxB
                position: Qt.vector3d(100, 200, 0)
                scale: Qt.vector3d(2, 0.5, 0.5)
                collisionShapes: BoxShape {}
                Model {
                    source: "#Cube"
                    materials: PrincipledMaterial {
                        baseColor: "blue"
                    }
                }
            }

            Node {
                id: jointSpawner
                property var currJoint: null
                property var jointComponent: Qt.createComponent("Joint.qml")
                property int numSpawns: 0

                function createStack() {
                    let joint = jointComponent.incubateObject(jointSpawner, {
                                                              "bodyA": boxA,
                                                              "bodyB": boxB,
                                                          })
                    currJoint = joint
                    numSpawns = numSpawns + 1;
                }

                function reset() {
                    if (!currJoint || !currJoint.object)
                        return
                    currJoint.object.destroy()
                    currJoint = null
                }
            }

            Node {
                id: boxSpawner
                property var currBox: null
                property var boxComponent: Qt.createComponent("Box.qml")
                property int numSpawns: 0

                function createStack() {
                    if (currBox)
                        return
                    currBox = boxComponent.incubateObject(boxSpawner, {position: Qt.vector3d(-300, 200, 0)})
                    sphericalJoint.bodyA = currBox.object
                    numSpawns = numSpawns + 1;
                }

                function reset() {
                    if (!currBox || !currBox.object)
                        return
                    currBox.object.destroy()
                    currBox = null
                }
            }
        }
    }

    FrameAnimation {
        property int frame: 0
        running: true
        onTriggered: {
            if (frame % 2 == 0) {
                jointSpawner.reset()
            }
            if (frame % 2 == 1) {
                jointSpawner.createStack()
            }
            if (frame % 50 == 0) {
                boxSpawner.reset()
                boxSpawner.createStack()
            }
            if (frame % 50 == 5) {
                sphericalJoint.bodyA = boxSpawner.currBox.object
            }
            frame = frame + 1;
        }
    }

    PhysicsTestCase {
        name: "100 joints"
        goalReached: jointSpawner.numSpawns > 100
    }

    PhysicsTestCase {
        name: "5 boxes"
        goalReached: boxSpawner.numSpawns > 5
    }
}

