// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

// Destroys and recreates the only PhysicsWorld while bodies with mesh and
// height field shapes stay in the scene. Destroying the last world releases
// the PxPhysics and with it every mesh and height field created from it, so
// the shapes must give the next world new ones instead of the old pointers.
// The boxes are dropped again on each world and must land, which shows that
// the shapes were rebuilt and not just left dangling.

Item {
    width: 640
    height: 480
    visible: true

    // Create the first world only once the scene it refers to exists.
    Component.onCompleted: worldLoader.active = true

    Loader {
        id: worldLoader
        active: false
        sourceComponent: PhysicsWorld {
            minimumTimestep: 15
            maximumTimestep: 15
        }
        // Inside the component the viewport id resolves to null when the Loader
        // creates the world, so the scene is set from here.
        onLoaded: item.scene = viewport.scene
    }

    View3D {
        id: viewport
        anchors.fill: parent

        PerspectiveCamera {
            position: Qt.vector3d(0, 100, 800)
            clipFar: 5000
        }

        DirectionalLight {
            eulerRotation.x: -45
        }

        // The boxes start just above their floors so that each world is done
        // with quickly.
        DynamicRigidBody {
            id: convexBox
            property bool hit: false
            readonly property vector3d startPosition: Qt.vector3d(-300, 60, 0)
            position: startPosition
            receiveContactReports: true
            onBodyContact: () => {
                hit = true
                control.bodyHit()
            }
            collisionShapes: ConvexMeshShape {
                source: "qrc:/data/cube.mesh"
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "yellow"
                }
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(-300, -100, 0)
            sendContactReports: true
            collisionShapes: TriangleMeshShape {
                source: "qrc:/data/cube.mesh"
                scale: Qt.vector3d(4, 1, 4)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(4, 1, 4)
                materials: PrincipledMaterial {
                    baseColor: "green"
                }
            }
        }

        DynamicRigidBody {
            id: heightFieldBox
            property bool hit: false
            readonly property vector3d startPosition: Qt.vector3d(300, -100, 0)
            position: startPosition
            receiveContactReports: true
            onBodyContact: () => {
                hit = true
                control.bodyHit()
            }
            collisionShapes: ConvexMeshShape {
                source: "qrc:/data/cube.mesh"
            }
            Model {
                source: "#Cube"
                materials: PrincipledMaterial {
                    baseColor: "yellow"
                }
            }
        }

        StaticRigidBody {
            sendContactReports: true
            collisionShapes: HeightFieldShape {
                source: "qrc:/data/hf.png"
                position: Qt.vector3d(300, -300, 0)
                extents: "400, 200, 400"
            }
        }
    }

    QtObject {
        id: control
        // Each world is destroyed once both boxes have landed in it, so this many
        // worlds means that many minus one recreations with the bodies kept.
        readonly property int worldsWanted: 4
        property int worldsDestroyed: 0
        property bool done: false
        // The world on its way out. A reference to a deleted object reads as null.
        property var oldWorld: null

        function bodyHit() {
            if (oldWorld !== null || !convexBox.hit || !heightFieldBox.hit)
                return
            oldWorld = worldLoader.item
            worldLoader.active = false
            deletionPoll.start()
        }

        function worldDestroyed() {
            oldWorld = null
            worldsDestroyed++
            if (worldsDestroyed == worldsWanted) {
                done = true
                return
            }
            convexBox.hit = false
            heightFieldBox.hit = false
            convexBox.position = convexBox.startPosition
            heightFieldBox.position = heightFieldBox.startPosition
            worldLoader.active = true
        }
    }

    // The Loader deletes the old world with deleteLater(), and its
    // Component.onDestruction already fires when the Loader lets go of it, so
    // wait for the reference to turn null before creating the next one.
    // Otherwise the two worlds would overlap and the PxPhysics would never be
    // released in between.
    Timer {
        id: deletionPoll
        interval: 1
        repeat: true
        onTriggered: {
            if (control.oldWorld !== null)
                return
            stop()
            control.worldDestroyed()
        }
    }

    PhysicsTestCase {
        name: "Recreate world"
        goalReached: control.done
    }
}
