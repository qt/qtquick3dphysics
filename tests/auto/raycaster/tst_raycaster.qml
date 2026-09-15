// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

Item {
    id: root
    width: 640
    height: 480
    visible: true

    // Latched, since the tests go on to move the rays off their targets and the timeout
    // guard checks the goal again after they have run.
    property bool raysReady: false
    readonly property bool raysHitting: ray.isColliding && childRay.isColliding
    onRaysHittingChanged: raysReady = raysReady || raysHitting;

    // Draws a ray as a thin bar from its origin to where it ends, green while it is hitting
    // something and red while it is not. The bodies come from forceDebugDraw, which does not
    // know about rays.
    component RayVisual: Model {
        required property Raycaster raycaster
        readonly property real length: raycaster.isColliding ? raycaster.hit.distance
                                                             : raycaster.maxDistance

        source: "#Cube"
        z: -length / 2
        scale: Qt.vector3d(0.02, 0.02, length / 100)
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
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#101418"
        }

        // High and slightly to one side, so all the rays are in frame and each is seen along
        // its length rather than end on.
        PerspectiveCamera {
            position: Qt.vector3d(11, 64, 114)
            eulerRotation: Qt.vector3d(-25, -10, 0)
            clipFar: 1000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-40, 30, 0)
        }

        Raycaster {
            id: ray
            maxDistance: 100

            RayVisual {
                raycaster: ray
            }
        }

        StaticRigidBody {
            id: target
            z: -50
            collisionShapes: BoxShape {
                id: targetShape
                extents: Qt.vector3d(10, 10, 10)
            }
        }

        DynamicRigidBody {
            id: parentBody
            x: 50
            isKinematic: true
            kinematicPosition: position
            collisionShapes: BoxShape {
                extents: Qt.vector3d(10, 10, 10)
            }

            Raycaster {
                id: childRay
                maxDistance: 100

                RayVisual {
                    raycaster: childRay
                }
            }
        }

        StaticRigidBody {
            id: childTarget
            x: 50
            z: -50
            collisionShapes: BoxShape {
                extents: Qt.vector3d(10, 10, 10)
            }
        }

        // A ray at its own body's origin, which is how one is normally mounted. A raycast does
        // report the shape it starts inside, at distance 0, so without the exclusion this ray
        // sees its own body and nothing past it.
        DynamicRigidBody {
            id: mountBody
            x: -45
            isKinematic: true
            kinematicPosition: position
            collisionShapes: BoxShape {
                extents: Qt.vector3d(10, 10, 10)
            }

            Raycaster {
                id: mountedRay
                maxDistance: 100

                RayVisual {
                    raycaster: mountedRay
                }
            }
        }

        StaticRigidBody {
            id: behindMount
            x: -45
            z: -50
            collisionShapes: BoxShape {
                extents: Qt.vector3d(10, 10, 10)
            }
        }

        StaticRigidBody {
            id: outerBody
            x: 105
            collisionShapes: BoxShape {
                extents: Qt.vector3d(30, 30, 30)
            }

            StaticRigidBody {
                id: innerBody
                collisionShapes: BoxShape {
                    extents: Qt.vector3d(10, 10, 10)
                }

                Raycaster {
                    id: nestedRay
                    maxDistance: 100

                    RayVisual {
                        raycaster: nestedRay
                    }
                }
            }
        }

        StaticRigidBody {
            id: behindNested
            x: 105
            z: -50
            collisionShapes: BoxShape {
                extents: Qt.vector3d(10, 10, 10)
            }
        }

        HitMarker {
            raycaster: ray
        }

        HitMarker {
            raycaster: childRay
        }

        HitMarker {
            raycaster: mountedRay
        }

        HitMarker {
            raycaster: nestedRay
        }
    }

    SignalSpy {
        id: enteredSpy
        target: ray
        signalName: "bodyEntered"
    }

    SignalSpy {
        id: exitedSpy
        target: ray
        signalName: "bodyExited"
    }

    PhysicsTestCase {
        name: "Raycaster"
        // Both rays reaching their target is what the rest builds on, so wait for that rather
        // than for the window, which never arrives on a headless run and leaves the whole case
        // hanging.
        goalReached: root.raysReady

        function test_1_properties() {
            compare(ray.excludeParentBody, true);
            compare(ray.includeStatic, true);
            compare(ray.includeDynamic, true);

            tryCompare(ray, "isColliding", true);
            enteredSpy.clear();
            exitedSpy.clear();

            ray.direction = Qt.vector3d(0, 0, 0);
            compare(ray.direction, Qt.vector3d(0, 0, 0));
            compare(ray.isColliding, false);
            compare(ray.hit.body, null);
            compare(exitedSpy.count, 1);
            compare(exitedSpy.signalArguments[0][0], target);

            ray.maxDistance = 0;
            compare(ray.maxDistance, 0);
            ignoreWarning("Raycaster: maxDistance must be finite and non-negative, ignoring.");
            ray.maxDistance = -1;
            compare(ray.maxDistance, 0);

            ray.direction = Qt.vector3d(0, 0, -1);
            ray.maxDistance = 100;
        }

        function test_2_raycast() {
            tryCompare(ray, "isColliding", true);
            compare(ray.hit.body, target);
            compare(ray.hit.shape, targetShape);
            verify(ray.hit.distance > 0);
            verify(ray.hit.distance < ray.maxDistance);
            fuzzyCompare(ray.hit.position.z, -45, 0.01);
            compare(ray.hit.normal, Qt.vector3d(0, 0, 1));

            tryCompare(childRay, "isColliding", true);
            compare(childRay.hit.body, childTarget);

            enteredSpy.clear();
            exitedSpy.clear();

            target.x = 100;
            tryCompare(ray, "isColliding", false);
            compare(ray.hit.body, null);
            compare(ray.hit.shape, null);
            compare(ray.hit.position, Qt.vector3d(0, 0, 0));
            compare(ray.hit.normal, Qt.vector3d(0, 0, 0));
            compare(ray.hit.distance, 0);
            compare(exitedSpy.count, 1);
            compare(exitedSpy.signalArguments[0][0], target);

            target.x = 0;
            tryCompare(ray, "isColliding", true);
            compare(enteredSpy.count, 1);
            compare(enteredSpy.signalArguments[0][0], target);
        }

        function test_3_filtersAndInactiveStates() {
            ray.includeStatic = false;
            tryCompare(ray, "isColliding", false);

            ray.includeDynamic = false;
            compare(ray.isColliding, false);
            compare(ray.hit.body, null);

            ray.includeStatic = true;
            tryCompare(ray, "isColliding", true);

            enteredSpy.clear();
            exitedSpy.clear();
            ray.enabled = false;
            compare(ray.isColliding, false);
            compare(ray.hit.body, null);
            compare(exitedSpy.count, 1);
            compare(exitedSpy.signalArguments[0][0], target);

            ray.enabled = true;
            tryCompare(ray, "isColliding", true);

            ray.includeDynamic = true;
        }

        function test_4_excludeParentBody() {
            // Excluding, the body the ray sits in is passed over for the one behind.
            compare(mountedRay.excludeParentBody, true);
            tryCompare(mountedRay, "isColliding", true);
            compare(mountedRay.hit.body, behindMount);
            fuzzyCompare(mountedRay.hit.distance, 45, 0.01);

            // Not excluding, the ray stops dead on the shape it starts inside.
            mountedRay.excludeParentBody = false;
            tryVerify(() => mountedRay.hit.body === mountBody);
            fuzzyCompare(mountedRay.hit.distance, 0, 0.01);

            mountedRay.excludeParentBody = true;
            tryVerify(() => mountedRay.hit.body === behindMount);
        }

        function test_5_excludesEveryAncestorBody() {
            // The ray is inside two nested bodies, so passing over only the nearest would
            // leave the outer one reported at distance 0.
            tryCompare(nestedRay, "isColliding", true);
            compare(nestedRay.hit.body, behindNested);
            fuzzyCompare(nestedRay.hit.distance, 45, 0.01);
        }

        function test_6_excludedBodies() {
            // Without the exclusion the ray stops on the body it sits in.
            mountedRay.excludeParentBody = false;
            tryVerify(() => mountedRay.hit.body === mountBody);

            // Naming that body explicitly does the same job as the ancestor walk, and works
            // for bodies the ray is not mounted on.
            mountedRay.excludedBodies = [mountBody];
            tryVerify(() => mountedRay.hit.body === behindMount);
            fuzzyCompare(mountedRay.hit.distance, 45, 0.01);

            // Excluding both leaves nothing for the ray to report.
            mountedRay.excludedBodies = [mountBody, behindMount];
            tryCompare(mountedRay, "isColliding", false);

            mountedRay.excludedBodies = [];
            mountedRay.excludeParentBody = true;
            tryVerify(() => mountedRay.hit.body === behindMount);
        }
    }
}
