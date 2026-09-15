// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Deletes the body two rays hit while the world syncs, so the same frame goes on
// to update the rays with that body's actor still in the scene. The actor only
// leaves on the next frame, and until then nothing leads from it back to a body.
// The rays must look past it to the body behind it rather than report no hit.
// One ray has no parent body and one is excluding its parent, since those took
// different queries.
//
// The deleting is done from the position handler of a body that moves every
// frame, as that runs in the middle of the sync, and through a helper, as
// destroy() would only delete between frames.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils
import RaycasterTest

Item {
    id: root
    width: 640
    height: 480

    // Latched, since the test then deletes the near target out from under the rays and the
    // timeout guard checks the goal again after it has run.
    property bool raysReady: false
    readonly property bool raysOnNearTarget: freeRay.hit.body === nearTarget
                                             && mountedRay.hit.body === nearTarget
    onRaysOnNearTargetChanged: raysReady = raysReady || raysOnNearTarget;

    property bool deleteRequested: false
    property bool deleted: false
    // What the rays hit in the frame the body was deleted in.
    property bool recorded: false
    property PhysicsNode freeRayBody
    property PhysicsNode mountedRayBody

    // Draws a ray as a thin bar from its origin to where it ends, green while it is hitting
    // something and red while it is not. The bodies come from forceDebugDraw, which does not
    // know about rays.
    component RayVisual: Model {
        required property Raycaster raycaster
        readonly property real length: raycaster.isColliding ? raycaster.hit.distance
                                                             : raycaster.maxDistance

        source: "#Cube"
        z: -length / 2
        scale: Qt.vector3d(0.04, 0.04, length / 100)
        materials: PrincipledMaterial {
            baseColor: raycaster.isColliding ? "#24a148" : "#da1e28"
            lighting: PrincipledMaterial.NoLighting
        }
    }

    // Marks where a ray currently ends. Belongs to the scene rather than to the ray, since
    // the hit position is in scene coordinates.
    component HitMarker: Model {
        required property Raycaster raycaster

        visible: raycaster.isColliding
        position: raycaster.hit.position
        source: "#Sphere"
        scale: Qt.vector3d(0.08, 0.08, 0.08)
        materials: PrincipledMaterial {
            baseColor: "#f1c21b"
            lighting: PrincipledMaterial.NoLighting
        }
    }

    PhysicsWorld {
        gravity: Qt.vector3d(0, 0, 0)
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene

        onFrameDone: {
            if (root.deleted && !root.recorded) {
                root.freeRayBody = freeRay.hit.body;
                root.mountedRayBody = mountedRay.hit.body;
                root.recorded = true;
            }
        }
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#101418"
        }

        // Steep and from above, so the near wall and the far one behind it read as two
        // separate bars and the rays are seen jumping from one to the other when the near one
        // goes.
        PerspectiveCamera {
            position: Qt.vector3d(50, 105, 45)
            eulerRotation: Qt.vector3d(-52, 0, 0)
            clipFar: 1000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-40, 30, 0)
        }

        Raycaster {
            id: freeRay
            maxDistance: 200

            RayVisual {
                raycaster: freeRay
            }
        }

        StaticRigidBody {
            id: mount
            x: 100
            collisionShapes: BoxShape {
                extents: Qt.vector3d(10, 10, 10)
            }

            Raycaster {
                id: mountedRay
                maxDistance: 200

                RayVisual {
                    raycaster: mountedRay
                }
            }
        }

        StaticRigidBody {
            id: nearTarget
            x: 50
            z: -50
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 10, 10)
            }
        }

        StaticRigidBody {
            id: farTarget
            x: 50
            z: -100
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 10, 10)
            }
        }

        DynamicRigidBody {
            id: mover
            y: 500
            gravityEnabled: false
            collisionShapes: SphereShape {
                diameter: 1
            }
            Component.onCompleted: setLinearVelocity(Qt.vector3d(0, 10, 0))
            onPositionChanged: {
                if (root.deleteRequested && !root.deleted) {
                    ImmediateDeleter.deleteObject(nearTarget);
                    root.deleted = true;
                }
            }
        }

        HitMarker {
            raycaster: freeRay
        }

        HitMarker {
            raycaster: mountedRay
        }
    }

    PhysicsTestCase {
        name: "RaycasterDeletedBody"
        // Both rays reaching the near target is the starting state the test deletes out from
        // under them, so wait for that rather than for the window, which never arrives on a
        // headless run and hangs the case.
        goalReached: root.raysReady

        function test_deletedBodyIsPassedOver() {
            tryVerify(() => freeRay.hit.body === nearTarget && mountedRay.hit.body === nearTarget);

            root.deleteRequested = true;
            tryVerify(() => root.recorded);
            compare(root.freeRayBody, farTarget);
            compare(root.mountedRayBody, farTarget);

            compare(freeRay.hit.body, farTarget);
            fuzzyCompare(freeRay.hit.distance, 95, 0.01);
            compare(mountedRay.hit.body, farTarget);
            fuzzyCompare(mountedRay.hit.distance, 95, 0.01);
        }
    }
}
