// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

import Geometry

Item {
    width: 640
    height: 480
    visible: true

    PhysicsWorld {
        scene: viewport.scene
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#d6dbdf"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(-200, 100, 500)
            eulerRotation: Qt.vector3d(-20, -20, 0)
            clipFar: 5000
            clipNear: 1
        }

        DirectionalLight {
            eulerRotation.x: -45
            eulerRotation.y: 45
            castsShadow: true
            brightness: 1
            shadowFactor: 100
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -100, 0)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            collisionShapes: PlaneShape {}
            Model {
                source: "#Rectangle"
                scale: Qt.vector3d(10, 10, 1)
                materials: DefaultMaterial {
                    diffuseColor: "green"
                }
                castsShadows: false
                receivesShadows: true
            }
        }

        DynamicRigidBody {
            id: dynamicBox
            property bool hit : false
            onBodyContact: () => {
                dynamicBox.hit = true
            }
            receiveContactReports: true
            sendContactReports: true

            position: Qt.vector3d(-50, 300, 0)
            collisionShapes: ConvexMeshShape {
                geometry: ExampleTriangleGeometry { }
            }
            Model {
                geometry: ExampleTriangleGeometry { }
                materials: PrincipledMaterial {
                    baseColor: "yellow"
                }
            }
        }

        StaticRigidBody {
            sendContactReports: true
            position: Qt.vector3d(0, 50, 0)
            collisionShapes: TriangleMeshShape {
                geometry: ExampleTriangleGeometry { }
            }
            Model {
                geometry: ExampleTriangleGeometry { }
                materials: PrincipledMaterial {
                    baseColor: "yellow"
                }
            }
        }
    }

    TestCase {
        name: "scene"
        when: dynamicBox.hit
        function triggered() {  }
    }
}
