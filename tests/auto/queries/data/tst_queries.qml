// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtTest
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Physics
import QtQuick
import QtQuick3D.Physics.TestUtils

Item {
    width: 640
    height: 480
    visible: true

    PhysicsWorld {
        id: caster
        gravity: Qt.vector3d(0, -9.81, 0)
        running: true
        forceDebugDraw: true
        typicalLength: 1
        typicalSpeed: 10
        minimumTimestep: 15
        maximumTimestep: 15
        scene: viewport.scene
    }

    // Helper shapes initialized for query parameters
    BoxShape {
        id: queryBoxShape
        extents: Qt.vector3d(0.5, 0.5, 0.5)
        position: Qt.vector3d(0, 5, 0)
    }

    SphereShape {
        id: querySphereShape
        diameter: 1.0
        position: Qt.vector3d(0, 5, 0)
    }

    BoxShape {
        id: queryOverlapBoxShape
        extents: Qt.vector3d(1, 1, 1)
        position: Qt.vector3d(0, -0.5, 0)
    }

    SphereShape {
        id: queryOverlapSphereShape
        diameter: 20.0
        position: Qt.vector3d(0, -0.5, 0)
    }

    CapsuleShape {
        id: queryCapsuleShape
        diameter: 1.0
        height: 1.0
        position: Qt.vector3d(0, 5, 0)
    }

    ConvexMeshShape {
        id: queryConvexShape
        geometry: CuboidGeometry {}
        position: Qt.vector3d(0, 5, 0)
        scale: Qt.vector3d(0.01, 0.01, 0.01)
    }

    // Not valid as query geometry: PhysX only accepts sphere, capsule, box and convex mesh
    PlaneShape {
        id: queryPlaneShape
        position: Qt.vector3d(0, 5, 0)
    }

    TriangleMeshShape {
        id: queryTriangleMeshShape
        geometry: CuboidGeometry {}
        position: Qt.vector3d(0, 5, 0)
        scale: Qt.vector3d(0.01, 0.01, 0.01)
    }

    // --- Test Flags ---
    property bool testRaycastHit: false
    property bool testRaycastMiss: false
    property bool singleRaycastHit: false
    property bool singleRaycastHitDetails: false
    property bool singleRaycastMiss: false
    property bool singleRaycastStaticOnly: false
    property bool singleRaycastDynamicOnly: false
    property bool multiRaycastHit: false

    property bool testSweepBoxHit: false
    property bool testSweepSphereHit: false
    property bool testSweepMiss: false
    property bool singleSweepBoxHit: false
    property bool singleSweepSphereHit: false
    property bool multiSweepBoxHit: false
    property bool multiSweepSphereHit: false

    property bool testOverlapBoxHit: false
    property bool testOverlapSphereHit: false
    property bool testOverlapMiss: false
    property bool multiOverlapBoxHit: false
    property bool multiOverlapSphereHit: false

    property bool testInvalidInputs: false

    // --- Query shape type coverage ---
    property bool sweepCapsuleQueryShape: false
    property bool sweepConvexQueryShape: false
    property bool overlapCapsuleQueryShape: false
    property bool overlapConvexQueryShape: false
    property bool unsupportedQueryShapesRejected: false

    // --- Target type coverage ---
    property bool raycastHitsTriangleMesh: false
    property bool raycastHitsCharacterController: false

    // --- Destroyed-object safety ---
    property bool queryAfterDestroyIsSafe: false
    property var spawnedBodyRef: null
    property int spawnedBodyDestroyed: 0

    // --- New Flags for MTD and Trigger Exclusion ---
    property bool testSweepMTD: false
    property bool testTriggerExclusion: false

    // --- Shape Validation Flags ---
    property bool singleRaycastShapeCheck: false
    property bool multiRaycastShapesCheck: false
    property bool singleSweepBoxShapeCheck: false
    property bool singleSweepSphereShapeCheck: false
    property bool multiSweepBoxShapesCheck: false
    property bool multiOverlapBoxShapesCheck: false

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
                    id: staticFloor
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape {
                        id: floorShape
                        extents: Qt.vector3d(20, 1, 20)
                    }
                }

                DynamicRigidBody {
                    id: dynamicBox
                    position: Qt.vector3d(0, 0, 0)
                    collisionShapes: BoxShape {
                        id: dynamicBoxShape
                        extents: Qt.vector3d(1, 1, 1)
                    }
                }

                // Trigger body placed directly in the ray/sweep path (Y = 2.5)
                TriggerBody {
                    id: triggerZone
                    position: Qt.vector3d(0, 2.5, 0)
                    collisionShapes: BoxShape {
                        id: triggerShape
                        extents: Qt.vector3d(2, 2, 2)
                    }
                }

                // Triangle mesh target, off to the side at X = 8
                StaticRigidBody {
                    id: meshBody
                    position: Qt.vector3d(8, 0, 0)
                    collisionShapes: TriangleMeshShape {
                        id: meshBodyShape
                        source: "#Cube"
                        scale: Qt.vector3d(0.02, 0.02, 0.02)
                    }
                }

                // Character controller target, off to the side at X = -8
                CharacterController {
                    id: characterTarget
                    position: Qt.vector3d(-8, 0, 0)
                    gravity: Qt.vector3d(0, 0, 0)
                    collisionShapes: CapsuleShape {
                        id: characterTargetShape
                        diameter: 1.0
                        height: 1.0
                    }
                }
            }
        }
    }

    // Helper for floating-point comparisons
    function fuzzyCompareVec3(v1, v2, eps = 0.001) {
        return Math.abs(v1.x - v2.x) < eps &&
               Math.abs(v1.y - v2.y) < eps &&
               Math.abs(v1.z - v2.z) < eps;
    }

    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            // --- 1. Invalid Input Validation Tests ---
            const zeroDir = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, 0, 0), 10, true, true
            );
            const negDist = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), -5, true, true
            );
            const nanDist = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), NaN, true, true
            );
            const bothFalse = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 10, false, false
            );
            const nullSweep = caster.singleSweepQuery(null, Qt.vector3d(0, -1, 0), 10, true, true);

            testInvalidInputs = (zeroDir.body === null) &&
                                (negDist.body === null) &&
                                (nanDist.body === null) &&
                                (bothFalse.body === null) &&
                                (nullSweep.body === null);

            // --- 2. Raycast Tests ---
            testRaycastHit = caster.testRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 100, true, true
            );
            testRaycastMiss = !caster.testRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, 1, 0), 10, true, true
            );

            const rayHitS = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 100, true, true
            );
            const rayHitD = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 100, false, true
            );
            singleRaycastHit = (rayHitD.body === dynamicBox && rayHitS.body === dynamicBox);

            singleRaycastShapeCheck = (rayHitS.shape === dynamicBoxShape) &&
                                      (rayHitD.shape === dynamicBoxShape);

            if (rayHitS.body === dynamicBox) {
                const expectedPos = Qt.vector3d(0, 0.5, 0);
                const expectedNormal = Qt.vector3d(0, 1, 0);
                const expectedDist = 4.5;

                singleRaycastHitDetails = fuzzyCompareVec3(rayHitS.position, expectedPos) &&
                                          fuzzyCompareVec3(rayHitS.normal, expectedNormal) &&
                                          Math.abs(rayHitS.distance - expectedDist) < 0.001 &&
                                          rayHitS.shape === dynamicBoxShape;
            }

            const rayMiss = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, 1, 0), 10, true, true
            );
            singleRaycastMiss = (rayMiss.body === null);

            const rayStatic = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 10, true, false
            );
            singleRaycastStaticOnly = (rayStatic.body === staticFloor &&
                                       rayStatic.shape === floorShape);

            const rayDynamic = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 10, false, true
            );
            singleRaycastDynamicOnly = (rayDynamic.body === dynamicBox &&
                                        rayDynamic.shape === dynamicBoxShape);

            const multiRayHits = caster.multiRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 10, true, true
            );
            multiRaycastHit = (multiRayHits.length >= 2 &&
                               multiRayHits.some(h => h.body === dynamicBox) &&
                               multiRayHits.some(h => h.body === staticFloor));

            const dynRayHit = multiRayHits.find(h => h.body === dynamicBox);
            const statRayHit = multiRayHits.find(h => h.body === staticFloor);
            multiRaycastShapesCheck = (dynRayHit && dynRayHit.shape === dynamicBoxShape) &&
                                      (statRayHit && statRayHit.shape === floorShape);

            // --- 3. Sweep Tests ---
            queryBoxShape.position = Qt.vector3d(0, 5, 0);
            querySphereShape.position = Qt.vector3d(0, 5, 0);

            testSweepBoxHit = caster.testSweepQuery(
                queryBoxShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            testSweepSphereHit = caster.testSweepQuery(
                querySphereShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            testSweepMiss = !caster.testSweepQuery(
                queryBoxShape, Qt.vector3d(0, 1, 0), 10, true, true
            );

            const sweepBoxS = caster.singleSweepQuery(
                queryBoxShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            const sweepBoxD = caster.singleSweepQuery(
                queryBoxShape, Qt.vector3d(0, -1, 0), 10, false, true
            );
            singleSweepBoxHit = (sweepBoxD.body === dynamicBox && sweepBoxS.body === dynamicBox);
            singleSweepBoxShapeCheck = (sweepBoxS.shape === dynamicBoxShape) &&
                                       (sweepBoxD.shape === dynamicBoxShape);

            const sweepSphereS = caster.singleSweepQuery(
                querySphereShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            const sweepSphereD = caster.singleSweepQuery(
                querySphereShape, Qt.vector3d(0, -1, 0), 10, false, true
            );
            singleSweepSphereHit = (sweepSphereD.body === dynamicBox &&
                                    sweepSphereS.body === dynamicBox);
            singleSweepSphereShapeCheck = (sweepSphereS.shape === dynamicBoxShape) &&
                                          (sweepSphereD.shape === dynamicBoxShape);

            const multiSweepBox = caster.multiSweepQuery(
                queryBoxShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            multiSweepBoxHit = (multiSweepBox.length >= 2 &&
                                multiSweepBox.some(h => h.body === dynamicBox) &&
                                multiSweepBox.some(h => h.body === staticFloor));

            const dynSweepHit = multiSweepBox.find(h => h.body === dynamicBox);
            const statSweepHit = multiSweepBox.find(h => h.body === staticFloor);
            multiSweepBoxShapesCheck = (dynSweepHit && dynSweepHit.shape === dynamicBoxShape) &&
                                       (statSweepHit && statSweepHit.shape === floorShape);

            const multiSweepSphere = caster.multiSweepQuery(
                querySphereShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            multiSweepSphereHit = (multiSweepSphere.length >= 2 &&
                                   multiSweepSphere.some(h => h.body === dynamicBox) &&
                                   multiSweepSphere.some(h => h.body === staticFloor));

            // --- 4. Overlap Tests ---
            queryOverlapBoxShape.position = Qt.vector3d(0, -0.5, 0);
            queryOverlapSphereShape.position = Qt.vector3d(0, -0.5, 0);

            testOverlapBoxHit = caster.testOverlapQuery(queryOverlapBoxShape, true, true);
            testOverlapSphereHit = caster.testOverlapQuery(queryOverlapSphereShape, true, true);

            queryOverlapBoxShape.position = Qt.vector3d(0, 50, 0);
            testOverlapMiss = !caster.testOverlapQuery(queryOverlapBoxShape, true, true);
            queryOverlapBoxShape.position = Qt.vector3d(0, -0.5, 0);

            const multiOverlapBox = caster.multiOverlapQuery(queryOverlapBoxShape, true, true);
            multiOverlapBoxHit = (multiOverlapBox.length >= 2 &&
                                  multiOverlapBox.some(h => h.body === dynamicBox) &&
                                  multiOverlapBox.some(h => h.body === staticFloor));

            const dynOverlapHit = multiOverlapBox.find(h => h.body === dynamicBox);
            const statOverlapHit = multiOverlapBox.find(h => h.body === staticFloor);
            multiOverlapBoxShapesCheck = (dynOverlapHit && dynOverlapHit.shape === dynamicBoxShape) &&
                                         (statOverlapHit && statOverlapHit.shape === floorShape);

            const multiOverlapSphere = caster.multiOverlapQuery(
                queryOverlapSphereShape, true, true
            );
            multiOverlapSphereHit = (multiOverlapSphere.length >= 2 &&
                                     multiOverlapSphere.some(h => h.body === dynamicBox) &&
                                     multiOverlapSphere.some(h => h.body === staticFloor));

            // --- 5. MTD Sweep Test (Initial Overlap) ---
            queryBoxShape.position = Qt.vector3d(0, 0, 0); // Position inside dynamicBox
            const mtdHit = caster.singleSweepQuery(
                queryBoxShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            testSweepMTD = (mtdHit.body === dynamicBox) && (mtdHit.distance < 0);
            queryBoxShape.position = Qt.vector3d(0, 5, 0); // Restore position

            // --- 6. Trigger Exclusion Test ---
            const triggerRayHit = caster.singleRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 10, true, true
            );
            const triggerMultiRay = caster.multiRaycastQuery(
                Qt.vector3d(0, 5, 0), Qt.vector3d(0, -1, 0), 10, true, true
            );

            queryBoxShape.position = Qt.vector3d(0, 5, 0);
            const triggerSweepHit = caster.singleSweepQuery(
                queryBoxShape, Qt.vector3d(0, -1, 0), 10, true, true
            );

            queryOverlapBoxShape.position = Qt.vector3d(0, 2.5, 0);
            const triggerOverlap = caster.multiOverlapQuery(queryOverlapBoxShape, true, true);
            queryOverlapBoxShape.position = Qt.vector3d(0, -0.5, 0);

            testTriggerExclusion = (triggerRayHit.body !== triggerZone) &&
                                   !triggerMultiRay.some(h => h.body === triggerZone) &&
                                   (triggerSweepHit.body !== triggerZone) &&
                                   !triggerOverlap.some(h => h.body === triggerZone);

            // --- 7. Query shape type coverage ---
            // PhysX accepts sphere, capsule, box and convex mesh as query geometry.
            // Box and sphere are covered above; cover the other two here.
            queryCapsuleShape.position = Qt.vector3d(0, 5, 0);
            sweepCapsuleQueryShape = caster.testSweepQuery(
                queryCapsuleShape, Qt.vector3d(0, -1, 0), 10, true, true
            );

            queryConvexShape.position = Qt.vector3d(0, 5, 0);
            sweepConvexQueryShape = caster.testSweepQuery(
                queryConvexShape, Qt.vector3d(0, -1, 0), 10, true, true
            );

            queryCapsuleShape.position = Qt.vector3d(0, -0.5, 0);
            overlapCapsuleQueryShape = caster.testOverlapQuery(queryCapsuleShape, true, true);
            queryCapsuleShape.position = Qt.vector3d(0, 5, 0);

            queryConvexShape.position = Qt.vector3d(0, -0.5, 0);
            overlapConvexQueryShape = caster.testOverlapQuery(queryConvexShape, true, true);
            queryConvexShape.position = Qt.vector3d(0, 5, 0);

            // Everything else must be rejected rather than silently producing garbage.
            const planeSweep = caster.testSweepQuery(
                queryPlaneShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            const planeOverlap = caster.multiOverlapQuery(queryPlaneShape, true, true);
            const meshSweep = caster.testSweepQuery(
                queryTriangleMeshShape, Qt.vector3d(0, -1, 0), 10, true, true
            );
            const meshOverlap = caster.multiOverlapQuery(queryTriangleMeshShape, true, true);
            unsupportedQueryShapesRejected = !planeSweep && planeOverlap.length === 0 &&
                                             !meshSweep && meshOverlap.length === 0;

            // --- 8. Target type coverage ---
            // Triangle mesh bodies are valid query *targets* even though they are not
            // valid query *shapes*.
            const meshHit = caster.singleRaycastQuery(
                Qt.vector3d(8, 5, 0), Qt.vector3d(0, -1, 0), 100, true, true
            );
            raycastHitsTriangleMesh = (meshHit.body === meshBody) &&
                                      (meshHit.shape === meshBodyShape);

            // A CharacterController reports a body but no shape, as documented.
            const charHit = caster.singleRaycastQuery(
                Qt.vector3d(-8, 5, 0), Qt.vector3d(0, -1, 0), 100, true, true
            );
            raycastHitsCharacterController = (charHit.body === characterTarget) &&
                                             (charHit.shape === null);

            // --- 9. Destroyed-object safety (must run last: it pauses the world) ---
            spawnedBodyRef = spawnedBodyComponent.createObject(scene);
            destroySpawnedBody.start();
        }
    }

    // A body whose PhysX actor outlives its QML object: the actor is only released on
    // the next physics frame, and while the world is paused that frame never comes.
    Component {
        id: spawnedBodyComponent
        StaticRigidBody {
            position: Qt.vector3d(0, 30, 0)
            collisionShapes: BoxShape { extents: Qt.vector3d(2, 2, 2) }
            Component.onDestruction: spawnedBodyDestroyed++
        }
    }

    Timer {
        id: destroySpawnedBody
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            caster.running = false;
            spawnedBodyRef.destroy();
            queryAfterDestroy.start();
        }
    }

    Timer {
        id: queryAfterDestroy
        interval: 50
        running: false
        repeat: true
        property int tries: 0
        onTriggered: {
            gc();
            tries++;
            if (spawnedBodyDestroyed === 0) {
                if (tries > 40)
                    queryAfterDestroy.stop();
                return;
            }
            queryAfterDestroy.stop();
            // Must not crash, and must not report the destroyed body.
            const hits = caster.multiRaycastQuery(
                Qt.vector3d(0, 40, 0), Qt.vector3d(0, -1, 0), 100, true, true
            );
            queryAfterDestroyIsSafe = !hits.some(h => h.body !== null && h.body === spawnedBodyRef);
        }
    }

    // --- Physics Test Cases ---

    PhysicsTestCase {
        name: "TestInvalidInputs"
        goalReached: testInvalidInputs
    }

    PhysicsTestCase {
        name: "TestRayCastHit"
        goalReached: testRaycastHit
    }

    PhysicsTestCase {
        name: "TestRayCastMiss"
        goalReached: testRaycastMiss
    }

    PhysicsTestCase {
        name: "SingleRayCast"
        goalReached: singleRaycastHit && singleRaycastShapeCheck
    }

    PhysicsTestCase {
        name: "SingleRayCastHitDetails"
        goalReached: singleRaycastHitDetails
    }

    PhysicsTestCase {
        name: "SingleRayCastMiss"
        goalReached: singleRaycastMiss
    }

    PhysicsTestCase {
        name: "SingleRayCastStaticOnly"
        goalReached: singleRaycastStaticOnly
    }

    PhysicsTestCase {
        name: "SingleRayCastDynamicOnly"
        goalReached: singleRaycastDynamicOnly
    }

    PhysicsTestCase {
        name: "MultiRayCast"
        goalReached: multiRaycastHit && multiRaycastShapesCheck
    }

    PhysicsTestCase {
        name: "TestSweepBoxHit"
        goalReached: testSweepBoxHit
    }

    PhysicsTestCase {
        name: "TestSweepSphereHit"
        goalReached: testSweepSphereHit
    }

    PhysicsTestCase {
        name: "TestSweepMiss"
        goalReached: testSweepMiss
    }

    PhysicsTestCase {
        name: "SingleSweepBox"
        goalReached: singleSweepBoxHit && singleSweepBoxShapeCheck
    }

    PhysicsTestCase {
        name: "SingleSweepSphere"
        goalReached: singleSweepSphereHit && singleSweepSphereShapeCheck
    }

    PhysicsTestCase {
        name: "MultiSweepBox"
        goalReached: multiSweepBoxHit && multiSweepBoxShapesCheck
    }

    PhysicsTestCase {
        name: "MultiSweepSphere"
        goalReached: multiSweepSphereHit
    }

    PhysicsTestCase {
        name: "TestSweepMTD"
        goalReached: testSweepMTD
    }

    PhysicsTestCase {
        name: "TestOverlapBoxHit"
        goalReached: testOverlapBoxHit
    }

    PhysicsTestCase {
        name: "TestOverlapSphereHit"
        goalReached: testOverlapSphereHit
    }

    PhysicsTestCase {
        name: "TestOverlapMiss"
        goalReached: testOverlapMiss
    }

    PhysicsTestCase {
        name: "MultiOverlapBox"
        goalReached: multiOverlapBoxHit && multiOverlapBoxShapesCheck
    }

    PhysicsTestCase {
        name: "MultiOverlapSphere"
        goalReached: multiOverlapSphereHit
    }

    PhysicsTestCase {
        name: "TestTriggerExclusion"
        goalReached: testTriggerExclusion
    }

    PhysicsTestCase {
        name: "CapsuleQueryShape"
        goalReached: sweepCapsuleQueryShape && overlapCapsuleQueryShape
    }

    PhysicsTestCase {
        name: "ConvexMeshQueryShape"
        goalReached: sweepConvexQueryShape && overlapConvexQueryShape
    }

    PhysicsTestCase {
        name: "UnsupportedQueryShapesRejected"
        goalReached: unsupportedQueryShapesRejected
    }

    PhysicsTestCase {
        name: "RaycastHitsTriangleMesh"
        goalReached: raycastHitsTriangleMesh
    }

    PhysicsTestCase {
        name: "RaycastHitsCharacterController"
        goalReached: raycastHitsCharacterController
    }

    PhysicsTestCase {
        name: "QueryAfterDestroyIsSafe"
        goalReached: queryAfterDestroyIsSafe
    }
}
