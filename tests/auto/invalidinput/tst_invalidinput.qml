// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Regression tests for invalid/edge-case input that previously crashed or was
// silently mishandled instead of being rejected or failing gracefully.

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils
import PhysicsTest.InvalidInput

Item {
    width: 64
    height: 64

    TriggerBody {
        id: filterGroupNode
        collisionShapes: BoxShape {}
    }

    DynamicRigidBody {
        id: kinematicTestNode
        isKinematic: true
        collisionShapes: BoxShape {}
    }

    SphereShape {
        id: sphereShapeTestNode
    }

    CapsuleShape {
        id: capsuleShapeTestNode
    }

    BoxShape {
        id: boxShapeTestNode
    }

    CharacterController {
        id: characterControllerTestNode
    }

    TestCase {
        name: "invalidinput_shapeAndControllerProperties"

        // SphereShape.diameter/CapsuleShape.diameter,height/BoxShape.extents reached
        // PxSphereGeometry/PxCapsuleGeometry/PxBoxGeometry unvalidated: the character
        // controller's per-frame controller->setRadius()/resize() (qphysxcharactercontroller.cpp)
        // bypasses the null-createShape() guard that protects the regular shape-building path
        // (see the SphereShape/BoxShape/CapsuleShape entries in invalidShapeScene below), so a
        // zero/negative/NaN dimension needed rejecting at the property level instead.
        function test_sphereDiameterRejectsInvalid() {
            sphereShapeTestNode.diameter = 10
            sphereShapeTestNode.diameter = 0
            compare(sphereShapeTestNode.diameter, 10, "zero diameter should be rejected")
            sphereShapeTestNode.diameter = -1
            compare(sphereShapeTestNode.diameter, 10, "negative diameter should be rejected")
            sphereShapeTestNode.diameter = NaN
            compare(sphereShapeTestNode.diameter, 10, "NaN diameter should be rejected")
        }

        function test_capsuleDimensionsRejectInvalid() {
            capsuleShapeTestNode.diameter = 10
            capsuleShapeTestNode.height = 10
            capsuleShapeTestNode.diameter = 0
            capsuleShapeTestNode.height = NaN
            compare(capsuleShapeTestNode.diameter, 10, "zero diameter should be rejected")
            compare(capsuleShapeTestNode.height, 10, "NaN height should be rejected")
        }

        function test_boxExtentsRejectsInvalid() {
            boxShapeTestNode.extents = Qt.vector3d(10, 10, 10)
            boxShapeTestNode.extents = Qt.vector3d(10, -1, 10)
            compare(boxShapeTestNode.extents, Qt.vector3d(10, 10, 10),
                    "a negative extents component should be rejected")
        }

        // CharacterController.movement/gravity reach PxController::move() with no
        // finiteness check anywhere in PhysX's character-kinematic code, checked build or not.
        function test_characterControllerRejectsNonFinite() {
            characterControllerTestNode.movement = Qt.vector3d(1, 2, 3)
            characterControllerTestNode.movement = Qt.vector3d(NaN, 0, 0)
            compare(characterControllerTestNode.movement, Qt.vector3d(1, 2, 3),
                    "non-finite movement should be rejected")

            characterControllerTestNode.gravity = Qt.vector3d(0, -9, 0)
            characterControllerTestNode.gravity = Qt.vector3d(0, -Infinity, 0)
            compare(characterControllerTestNode.gravity, Qt.vector3d(0, -9, 0),
                    "non-finite gravity should be rejected")
        }

        // CharacterController.teleport() forwards its argument to
        // PxController::setPosition() -> Cct::Controller::setPos() with no validation of any
        // kind, not even a checked-build-only one. Actual crash-safety is exercised by
        // teleportTestNode in invalidShapeScene below; this just confirms the invokable
        // itself doesn't misbehave.
        function test_teleportRejectsNonFinite() {
            characterControllerTestNode.teleport(Qt.vector3d(NaN, 0, 0))
        }
    }

    TestCase {
        name: "invalidinput_worldProperties"

        // PxScene::setGravity()/PxScene::simulate() have no validation of their own (not
        // even a checked-build-only one for gravity; the elapsedTime check on simulate()
        // is checked-build-only and this project only enables that in Debug). A NaN value
        // used to reach them directly.
        function test_gravityRejectsNonFinite() {
            invalidShapeWorld.gravity = Qt.vector3d(0, -900, 0)
            compare(invalidShapeWorld.gravity, Qt.vector3d(0, -900, 0))

            invalidShapeWorld.gravity = Qt.vector3d(NaN, 0, 0)
            compare(invalidShapeWorld.gravity, Qt.vector3d(0, -900, 0),
                    "non-finite gravity should be rejected, keeping the previous value")
        }

        function test_timestepRejectsNonFinite() {
            invalidShapeWorld.minimumTimestep = 15
            invalidShapeWorld.minimumTimestep = NaN
            verify(!isNaN(invalidShapeWorld.minimumTimestep),
                   "non-finite minimumTimestep should be rejected")

            invalidShapeWorld.maximumTimestep = 15
            invalidShapeWorld.maximumTimestep = NaN
            verify(!isNaN(invalidShapeWorld.maximumTimestep),
                   "non-finite maximumTimestep should be rejected")
        }

        // DynamicRigidBody.kinematicPosition/Rotation/EulerRotation/Pivot used to reach
        // PxRigidDynamic::setKinematicTarget() with no finiteness check at all.
        function test_kinematicPositionRejectsNonFinite() {
            kinematicTestNode.kinematicPosition = Qt.vector3d(1, 2, 3)
            compare(kinematicTestNode.kinematicPosition, Qt.vector3d(1, 2, 3))

            kinematicTestNode.kinematicPosition = Qt.vector3d(NaN, 0, 0)
            compare(kinematicTestNode.kinematicPosition, Qt.vector3d(1, 2, 3),
                    "non-finite kinematicPosition should be rejected, keeping the previous value")
        }

        // DynamicRigidBody.centerOfMassPosition/centerOfMassRotation feed
        // PxRigidBody::setCMassLocalPose() (via QPhysicsCommandSetMassAndInertiaTensor/Matrix in
        // qphysicscommands.cpp) with no finiteness check of their own; that call's own
        // PX_CHECK_AND_RETURN(pose.isSane(), ...) is compiled out outside PX_CHECKED (Debug-only)
        // builds.
        function test_centerOfMassRejectsNonFinite() {
            kinematicTestNode.centerOfMassPosition = Qt.vector3d(1, 2, 3)
            compare(kinematicTestNode.centerOfMassPosition, Qt.vector3d(1, 2, 3))

            kinematicTestNode.centerOfMassPosition = Qt.vector3d(NaN, 0, 0)
            compare(kinematicTestNode.centerOfMassPosition, Qt.vector3d(1, 2, 3),
                    "non-finite centerOfMassPosition should be rejected, keeping the previous value")

            kinematicTestNode.centerOfMassRotation = Qt.quaternion(1, 0, 0, 0)
            compare(kinematicTestNode.centerOfMassRotation, Qt.quaternion(1, 0, 0, 0))

            kinematicTestNode.centerOfMassRotation = Qt.quaternion(NaN, 0, 0, 0)
            compare(kinematicTestNode.centerOfMassRotation, Qt.quaternion(1, 0, 0, 0),
                    "non-finite centerOfMassRotation should be rejected, keeping the previous value")
        }

        // PhysicsWorld.defaultDensity bypasses DynamicRigidBody.setDensity()'s validation
        // entirely -- updateDefaultDensity() enqueues a QPhysicsCommandSetDensity directly --
        // so it needs the same clamp applied independently, or a non-finite/non-positive value
        // reaches PxRigidBodyExt::updateMassAndInertia() unguarded for every DefaultDensity body.
        function test_defaultDensityRejectsInvalid() {
            invalidShapeWorld.defaultDensity = 5
            invalidShapeWorld.defaultDensity = 0
            verify(invalidShapeWorld.defaultDensity > 0,
                   "zero defaultDensity should be clamped to a small positive value")

            invalidShapeWorld.defaultDensity = NaN
            verify(!isNaN(invalidShapeWorld.defaultDensity),
                   "non-finite defaultDensity should be clamped")
        }
    }

    TestCase {
        name: "invalidinput_filterGroup"

        // PhysicsNode.filterGroup is only meaningful in [0, 31] (see
        // physxnode/qphysxworld.cpp's isFilteredOut()/isBitSet()). Values outside
        // that range used to be accepted silently and made the collision filter
        // fail open (the pair would collide normally instead of being filtered).
        function test_filterGroupRejectsOutOfRange() {
            filterGroupNode.filterGroup = 5
            compare(filterGroupNode.filterGroup, 5)

            filterGroupNode.filterGroup = 31
            compare(filterGroupNode.filterGroup, 31, "boundary value 31 should be accepted")

            filterGroupNode.filterGroup = 32
            compare(filterGroupNode.filterGroup, 31,
                    "out-of-range value 32 should be rejected, keeping the previous value")

            filterGroupNode.filterGroup = -1
            compare(filterGroupNode.filterGroup, 31,
                    "negative value should be rejected, keeping the previous value")
        }
    }

    // Shared smoke-test scene: bodies below previously crashed the simulation on
    // malformed input. Each PhysicsTestCase asserts the world keeps running instead.
    // No rendering is needed for any of this, so scene is a plain Node rather than
    // a View3D.
    Node {
        id: invalidShapeScene

        // A Geometry with no position attribute used to hit a reachable
        // Q_UNREACHABLE() in QQuick3DPhysicsMesh's attributeBySemantic() helper.
        StaticRigidBody {
            position: Qt.vector3d(0, 100, 0)
            collisionShapes: ConvexMeshShape { geometry: NoPositionGeometry {} }
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -100, 0)
            collisionShapes: TriangleMeshShape { geometry: NoPositionGeometry {} }
        }

        // A Geometry whose position attribute offset doesn't fit within its stride
        // used to make convexMeshGeometrySource()/triangleMeshGeometrySource() read
        // past the end of the vertex buffer while cooking the mesh.
        StaticRigidBody {
            position: Qt.vector3d(0, 300, 0)
            collisionShapes: ConvexMeshShape { geometry: BadStrideGeometry {} }
        }

        StaticRigidBody {
            position: Qt.vector3d(0, -300, 0)
            collisionShapes: TriangleMeshShape { geometry: BadStrideGeometry {} }
        }

        // Shapes with zero/negative dimensions used to crash
        // QPhysXActorBody::rebuildShapes() via an unchecked null return from
        // PxPhysics::createShape(). None of these are expected to do anything
        // physically meaningful -- the goal here is just that the world keeps
        // simulating instead of crashing.
        StaticRigidBody {
            position: Qt.vector3d(-100, 0, 0)
            collisionShapes: SphereShape { diameter: 0 }
        }

        StaticRigidBody {
            position: Qt.vector3d(100, 0, 0)
            collisionShapes: BoxShape { extents: Qt.vector3d(-1, 5, 5) }
        }

        StaticRigidBody {
            position: Qt.vector3d(200, 0, 0)
            collisionShapes: CapsuleShape { diameter: 0; height: 0 }
        }

        // A shape's own diameter/height/extents is already validated finite and positive at
        // its own setter, but the *scaled* value used to build the actual PxGeometry
        // (updatePhysXGeometry(), which multiplies by sceneScale() -- the ancestor
        // QQuick3DNode chain's scale, not validated by this module) was never re-checked, so a
        // degenerate ancestor scale still reached PxPhysics::createShape() with an invalid
        // geometry, completely unvalidated outside PX_CHECKED (Debug-only) builds.
        StaticRigidBody {
            position: Qt.vector3d(-200, 0, 0)
            collisionShapes: SphereShape { diameter: 100; scale: Qt.vector3d(0, 0, 0) }
        }

        // scale is listed before extents here (unlike the SphereShape/CapsuleShape cases
        // above): QML applies same-object-literal properties in source order, and if extents
        // is set first it builds one (valid, then-discarded) geometry with the still-default
        // scale before scale is applied -- exercising the same fix either way, just via a
        // different code path.
        StaticRigidBody {
            position: Qt.vector3d(-300, 0, 0)
            collisionShapes: BoxShape { scale: Qt.vector3d(0, 0, 0); extents: Qt.vector3d(10, 10, 10) }
        }

        StaticRigidBody {
            position: Qt.vector3d(-400, 0, 0)
            collisionShapes: CapsuleShape {
                diameter: 100
                height: 100
                scale: Qt.vector3d(0, 0, 0)
            }
        }

        // A non-finite position used to reach PxPhysics::createRigidStatic() at creation
        // and, every synced frame afterwards, PxRigidStatic::setGlobalPose() -- neither is
        // validated in Release builds, and worse: fuzzyEquals(Infinity, Infinity) is false
        // (Infinity - Infinity is NaN), so the "only sync if moved" check never short-circuits
        // and setGlobalPose() would otherwise be called with the bad pose every single frame.
        StaticRigidBody {
            position: Qt.vector3d(1 / 0, 0, 0)
            collisionShapes: BoxShape {}
        }

        // teleport()'s position reaches PxController::setPosition() with no validation at
        // all, in every build configuration (not even a checked-build-only guard exists).
        CharacterController {
            id: teleportTestNode
            position: Qt.vector3d(0, 500, 0)
            collisionShapes: CapsuleShape { height: 100; diameter: 100 }
            Component.onCompleted: teleport(Qt.vector3d(NaN, 0, 0))
        }

        // A CharacterController's capsule scaled by a degenerate ancestor scene scale used to
        // reach PxShape::setGeometry() with a non-positive capsule geometry, completely
        // unvalidated (PxCapsuleGeometry::isValid()'s own check is compiled out outside
        // PX_CHECKED, Debug-only, builds -- see physxnode/qphysxcharactercontroller.cpp). The
        // scale only degenerates after a few frames so the controller is already created
        // (with a valid capsule) by the time it happens -- a zero scale from the start instead
        // makes PxControllerManager::createController() itself reject the geometry immediately
        // (unconditionally, not a Debug-only check), which never exercises the per-frame
        // resize()/setRadius() path this guards.
        Node {
            id: badScaleControllerAncestor
            CharacterController {
                position: Qt.vector3d(0, 550, 0)
                collisionShapes: CapsuleShape { height: 100; diameter: 100 }
            }
        }

        // DynamicRigidBody's velocity setters, force/impulse appliers, and reset() all
        // forward straight to e.g. PxRigidDynamic::setLinearVelocity()/addForce()/
        // setGlobalPose() with no validation of their own; those calls' own
        // PX_CHECK_AND_RETURN(...isFinite()/isSane()...) guards are compiled out
        // (PX_CHECKED, Debug-only).
        DynamicRigidBody {
            id: nonFiniteInvokablesTestNode
            position: Qt.vector3d(700, 0, 0)
            collisionShapes: BoxShape {}
            Component.onCompleted: {
                setLinearVelocity(Qt.vector3d(NaN, 0, 0));
                setAngularVelocity(Qt.vector3d(NaN, 0, 0));
                applyCentralForce(Qt.vector3d(1 / 0, 0, 0));
                applyForce(Qt.vector3d(1 / 0, 0, 0), Qt.vector3d(0, 0, 0));
                applyTorque(Qt.vector3d(NaN, 0, 0));
                applyCentralImpulse(Qt.vector3d(NaN, 0, 0));
                applyImpulse(Qt.vector3d(NaN, 0, 0), Qt.vector3d(0, 0, 0));
                applyTorqueImpulse(Qt.vector3d(NaN, 0, 0));
                reset(Qt.vector3d(NaN, 0, 0), Qt.vector3d(0, 0, 0));
            }
        }

        // A running body with massMode: CustomDensity and density: 0 shouldn't hang or
        // crash the simulation.
        DynamicRigidBody {
            id: zeroDensityBody
            position: Qt.vector3d(0, 200, 0)
            massMode: DynamicRigidBody.CustomDensity
            density: 0
            collisionShapes: SphereShape { diameter: 10 }
        }

        // inertiaTensor must reject negative components.
        DynamicRigidBody {
            position: Qt.vector3d(0, 400, 0)
            massMode: DynamicRigidBody.MassAndInertiaTensor
            inertiaTensor: Qt.vector3d(-1, -1, -1)
            collisionShapes: SphereShape { diameter: 10 }
        }

        // A non-finite centerOfMassPosition/centerOfMassRotation used to reach
        // PxRigidBody::setCMassLocalPose() completely unvalidated.
        DynamicRigidBody {
            position: Qt.vector3d(0, 500, 0)
            massMode: DynamicRigidBody.MassAndInertiaTensor
            centerOfMassPosition: Qt.vector3d(NaN, 0, 0)
            centerOfMassRotation: Qt.quaternion(NaN, 0, 0, 0)
            collisionShapes: SphereShape { diameter: 10 }
        }

        // A collision shape's own position/rotation (its local offset within the body, as
        // opposed to the body's own position tested elsewhere in this scene) is a plain
        // QQuick3DNode property with no finiteness validation anywhere in this module, and
        // reached PxShape::setLocalPose() completely unvalidated.
        StaticRigidBody {
            position: Qt.vector3d(0, 550, 0)
            collisionShapes: BoxShape { position: Qt.vector3d(NaN, 0, 0) }
        }

        // A non-finite position reached PxRigidDynamic::setGlobalPose() every synced frame via
        // QPhysXTriggerBody::sync() with no isSane() check at all -- unlike the analogous
        // static-body per-frame sync just above, which already guards this.
        TriggerBody {
            position: Qt.vector3d(1 / 0, 600, 0)
            collisionShapes: BoxShape {}
        }

        // A kinematic body parented under a Node with a non-finite position used to reach
        // PxRigidDynamic::setKinematicTarget() with a non-finite target: kinematicPosition/
        // kinematicRotation are validated at their own setters, but the ancestor chain
        // calculateKinematicNodeTransform() walks (physxnode/qphysxdynamicbody.cpp) is not,
        // and the composed result was never checked before reaching PhysX.
        Node {
            position: Qt.vector3d(NaN, 0, 0)
            DynamicRigidBody {
                position: Qt.vector3d(0, 700, 0)
                isKinematic: true
                collisionShapes: BoxShape {}
            }
        }

        // PhysicsMaterial properties must reject NaN.
        StaticRigidBody {
            position: Qt.vector3d(300, 0, 0)
            collisionShapes: BoxShape {}
            physicsMaterial: PhysicsMaterial {
                staticFriction: NaN
                dynamicFriction: NaN
                restitution: NaN
            }
        }
    }

    PhysicsWorld {
        id: invalidShapeWorld
        scene: invalidShapeScene
        running: true
        minimumTimestep: 15
        maximumTimestep: 15

        property int frameCount: 0
        onFrameDone: {
            invalidShapeWorld.frameCount++;
            // Let the character controller and shapes above get built successfully with a
            // valid scale first, then degenerate it.
            if (invalidShapeWorld.frameCount === 3)
                badScaleControllerAncestor.scale = Qt.vector3d(0, 0, 0);
        }
    }

    PhysicsTestCase {
        name: "invalidinput_noPositionGeometry"
        goalReached: invalidShapeWorld.frameCount > 5
    }

    PhysicsTestCase {
        name: "invalidinput_shapeDimensions"
        goalReached: invalidShapeWorld.frameCount > 5
    }

    PhysicsTestCase {
        name: "invalidinput_badStride"
        goalReached: invalidShapeWorld.frameCount > 5
    }

    PhysicsTestCase {
        name: "invalidinput_massAndMaterial"
        goalReached: invalidShapeWorld.frameCount > 5
    }

    PhysicsTestCase {
        name: "invalidinput_teleport"
        goalReached: invalidShapeWorld.frameCount > 5
    }

    TestCase {
        name: "invalidinput_density"

        // DynamicRigidBody.density's setter now clamps to (0, inf], matching its
        // documented range, instead of silently storing an invalid value that only
        // failed later in the deferred command execution.
        function test_zeroDensityIsClamped() {
            verify(zeroDensityBody.density > 0,
                   "density: 0 should be clamped to a small positive value, not stored as-is")
        }
    }
}
