// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.TestUtils

// A body with no physicsMaterial of its own is simulated with the default material
// properties. The test cases below check that such bodies are not affected by the materials
// of other bodies, and that the physicsMaterial property can be changed while the
// simulation is running. Most of them slide two cubes across a floor and compare how far
// they travel, which is decided by the friction of the cube and of the floor. The character
// controller cases instead drop a ball on its capsule and measure how high it bounces.

Item {
    width: 640
    height: 480
    visible: true

    // Set by the first phase of the test cases below, so that the second phase only starts
    // once the material has actually been changed
    property bool materialAssigned: false
    property bool materialSwitched: false
    property bool materialUnset: false
    property bool characterMaterialSwitched: false
    property bool characterMaterialUnset: false

    // How high the ball bounced off the character, before and after its material was unset
    property bool ballReachedCharacter: false
    property real ballApexAfterBounce: -999
    property bool ballReachedCharacterAgain: false
    property real ballApexAfterUnset: -999

    PhysicsWorld {
        gravity: Qt.vector3d(0, -9.81, 0)
        running: true
        forceDebugDraw: true
        typicalLength: 1
        typicalSpeed: 10
        minimumTimestep: 15
        maximumTimestep: 15
        scene: viewport.scene
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        Node {
            id: scene

            // The groups below are laid out in two columns of three, so that the whole scene
            // fits in the window when the test is run with the debug draw visible
            PerspectiveCamera {
                position: Qt.vector3d(0, 58, 95)
                eulerRotation: Qt.vector3d(-40, 0, 0)
                clipFar: 500
                clipNear: 0.01
            }

            DirectionalLight {
                eulerRotation.x: -45
                eulerRotation.y: 45
            }

            PhysicsMaterial {
                id: slipperyMaterial
                staticFriction: 0
                dynamicFriction: 0
            }

            PhysicsMaterial {
                id: stickyMaterial
                staticFriction: 1
                dynamicFriction: 1
            }

            PhysicsMaterial {
                id: bouncyMaterial
                restitution: 1
            }

            // A body with no physicsMaterial is simulated with the default properties
            Node {
                id: defaultNode
                x: -24

                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape { extents: Qt.vector3d(4, 1, 4) }
                }

                TestCube {
                    id: defaultCube
                    y: 2
                    color: "yellow"
                }
            }

            // Assigning a material to a single body must not change the friction of the
            // bodies that have no material of their own
            Node {
                id: assignNode
                x: -24
                z: 26

                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape { extents: Qt.vector3d(36, 1, 20) }
                }

                TestCube {
                    id: assignControlCube
                    x: -16
                    z: -3
                    color: "green"
                }

                TestCube {
                    id: assignCube
                    x: -16
                    z: 3
                    color: "red"
                }
            }

            // Switching from one material to another while the simulation is running
            Node {
                id: switchNode
                x: 24
                z: 26

                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape { extents: Qt.vector3d(36, 1, 20) }
                }

                TestCube {
                    id: switchControlCube
                    x: -16
                    z: -3
                    color: "blue"
                    physicsMaterial: slipperyMaterial
                }

                TestCube {
                    id: switchCube
                    x: -16
                    z: 3
                    color: "orange"
                    physicsMaterial: slipperyMaterial
                }
            }

            // Bodies using the same material share it, so editing it affects all of them
            Node {
                id: sharedNode
                x: -24
                z: 52

                PhysicsMaterial {
                    id: editedMaterial
                    staticFriction: 0
                    dynamicFriction: 0
                }

                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape { extents: Qt.vector3d(36, 1, 20) }
                }

                TestCube {
                    id: sharedCube1
                    x: -16
                    z: -3
                    color: "white"
                    physicsMaterial: editedMaterial
                }

                TestCube {
                    id: sharedCube2
                    x: -16
                    z: 3
                    color: "black"
                    physicsMaterial: editedMaterial
                }

                TestCube {
                    id: sharedControlCube
                    x: -16
                    z: 9
                    color: "grey"
                    physicsMaterial: slipperyMaterial
                }
            }

            // Setting physicsMaterial back to null must bring the body back to the default
            // properties
            Node {
                id: unsetNode
                x: 24
                z: 52

                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape { extents: Qt.vector3d(36, 1, 20) }
                }

                TestCube {
                    id: unsetControlCube
                    x: -16
                    z: -3
                    color: "magenta"
                    physicsMaterial: slipperyMaterial
                }

                TestCube {
                    id: unsetCube
                    x: -16
                    z: 3
                    color: "cyan"
                    physicsMaterial: slipperyMaterial
                }
            }

            // The material of a CharacterController must reach the shape of the controller,
            // so that the bodies bouncing off it do so according to the new material
            Node {
                id: characterNode
                x: 24

                StaticRigidBody {
                    position: Qt.vector3d(0, -1, 0)
                    collisionShapes: BoxShape { extents: Qt.vector3d(20, 1, 20) }
                }

                CharacterController {
                    id: character
                    position: Qt.vector3d(0, 0.5, 0)
                    gravity: Qt.vector3d(0, 0, 0)
                    movement: Qt.vector3d(0, 0, 0)
                    collisionShapes: CapsuleShape { diameter: 1; height: 1 }
                    physicsMaterial: PhysicsMaterial { restitution: 0 }
                }

                DynamicRigidBody {
                    id: characterBall
                    position: Qt.vector3d(0, 12, 0)
                    massMode: DynamicRigidBody.CustomDensity
                    density: 1000
                    angularAxisLock: DynamicRigidBody.LockX | DynamicRigidBody.LockY
                                     | DynamicRigidBody.LockZ
                    collisionShapes: SphereShape { diameter: 0.5 }
                    Model {
                        source: "#Sphere"
                        scale: Qt.vector3d(0.5, 0.5, 0.5).times(0.01)
                        materials: PrincipledMaterial { baseColor: "yellow" }
                    }
                }
            }

            // A body that keeps falling, used to drive the per-step checks
            DynamicRigidBody {
                id: stepDriver
                // Falls freely next to the groups above, so that it never hits anything
                position: Qt.vector3d(0, 40, -25)
                collisionShapes: SphereShape { diameter: 2 }
                property int simulationSteps: 0
                onPositionChanged: {
                    // Only do the checks every other step, since we have no guarantees on signal emission order
                    if (simulationSteps % 2) {
                        defaultCube.checkStable()
                        assignControlCube.checkStable()
                        assignCube.checkStable()
                        switchControlCube.checkStable()
                        switchCube.checkStable()
                        sharedCube1.checkStable()
                        sharedCube2.checkStable()
                        sharedControlCube.checkStable()
                        unsetControlCube.checkStable()
                        unsetCube.checkStable()
                        // Only track the apex from the moment the ball is about to land on
                        // the capsule, so that the height it is dropped from is not counted
                        if (characterBall.y < 2) {
                            if (characterMaterialUnset)
                                ballReachedCharacterAgain = true
                            else
                                ballReachedCharacter = true
                        }
                        if (characterMaterialUnset) {
                            if (ballReachedCharacterAgain)
                                ballApexAfterUnset = Math.max(ballApexAfterUnset,
                                                              characterBall.y)
                        } else if (ballReachedCharacter) {
                            ballApexAfterBounce = Math.max(ballApexAfterBounce, characterBall.y)
                        }
                    }
                    // Send the cubes sliding once the bodies have been created
                    if (simulationSteps === 4) {
                        const velocity = Qt.vector3d(15, 0, 0)
                        assignControlCube.setLinearVelocity(velocity)
                        assignCube.setLinearVelocity(velocity)
                        switchControlCube.setLinearVelocity(velocity)
                        switchCube.setLinearVelocity(velocity)
                        sharedCube1.setLinearVelocity(velocity)
                        sharedCube2.setLinearVelocity(velocity)
                        sharedControlCube.setLinearVelocity(velocity)
                        unsetControlCube.setLinearVelocity(velocity)
                        unsetCube.setLinearVelocity(velocity)
                    }
                    simulationSteps++
                }
            }
        }
    }

    // The test functions of a TestCase are run in alphabetical order, so they are numbered
    // where the order matters.

    PhysicsTestCase {
        name: "DefaultMaterial"
        goalReached: defaultCube.stable
        function test_1_body_without_material_is_simulated() {
            // Came to rest on top of the floor
            fuzzyCompare(defaultCube.y, 0, 0.01)
        }
        function test_2_material_has_default_values() {
            const material = defaultCube.physicsMaterial
            verify(material !== null)
            fuzzyCompare(material.staticFriction, 0.5, 0.001)
            fuzzyCompare(material.dynamicFriction, 0.5, 0.001)
            fuzzyCompare(material.restitution, 0.5, 0.001)
        }
    }

    PhysicsTestCase {
        name: "AssignMaterial"
        // Both cubes are sliding with the default friction
        goalReached: assignControlCube.x > -13 && assignCube.x > -13
        function test_1_bodies_slide_alike_without_materials() {
            verify(!assignControlCube.stable)
            verify(!assignCube.stable)
            fuzzyCompare(assignCube.x, assignControlCube.x, 0.5)
        }
        function test_2_assign_material_to_a_single_body() {
            assignCube.physicsMaterial = slipperyMaterial
            materialAssigned = true
        }
    }

    PhysicsTestCase {
        name: "AssignMaterial2"
        // The control cube keeps the default friction, so it stops first
        goalReached: materialAssigned && assignControlCube.stable
        function test_default_material_was_not_modified() {
            // The default material is shared by all bodies that have no material, so
            // assigning one to assignCube must not make assignControlCube slippery too
            verify(!assignCube.stable)
            verify(assignCube.x > assignControlCube.x + 2)
        }
    }

    PhysicsTestCase {
        name: "SwitchMaterial"
        // Both cubes are sliding with the same slippery material
        goalReached: switchControlCube.x > -13 && switchCube.x > -13
        function test_1_bodies_slide_alike_with_the_same_material() {
            verify(!switchControlCube.stable)
            verify(!switchCube.stable)
            fuzzyCompare(switchCube.x, switchControlCube.x, 0.5)
        }
        function test_2_switch_material() {
            switchCube.physicsMaterial = stickyMaterial
            materialSwitched = true
        }
    }

    PhysicsTestCase {
        name: "SwitchMaterial2"
        // The sticky material has a higher friction, so that cube stops first
        goalReached: materialSwitched && switchCube.stable
        function test_switched_material_is_used() {
            // The control cube still references the slippery material, which must not
            // have been affected by the switch
            verify(!switchControlCube.stable)
            verify(switchControlCube.x > switchCube.x + 2)
        }
    }

    PhysicsTestCase {
        name: "CharacterControllerMaterial"
        // The ball is still well above the capsule of the character
        goalReached: characterBall.y < 6
        function test_switch_the_character_material() {
            character.physicsMaterial = bouncyMaterial
            characterMaterialSwitched = true
        }
    }

    PhysicsTestCase {
        // The ball bounces back up high above the capsule, which it only does if the new
        // material reached the shape of the character controller. Times out otherwise.
        name: "CharacterControllerMaterial2"
        goalReached: characterMaterialSwitched && ballApexAfterBounce > 4.5
        function test_unset_the_character_material() {
            // Drop the ball again, with the character back to the default properties
            character.physicsMaterial = null
            characterBall.reset(Qt.vector3d(0, 12, 0), Qt.vector3d(0, 0, 0))
            characterMaterialUnset = true
        }
    }

    PhysicsTestCase {
        // The ball has bounced off the character again and is on its way down
        name: "CharacterControllerMaterial3"
        goalReached: ballApexAfterUnset > 2
                     && characterBall.y < ballApexAfterUnset - 0.5
        function test_character_uses_default_properties_again() {
            // The default restitution is lower than that of the material it had, so the ball
            // does not come anywhere near as high as it did before
            verify(ballApexAfterUnset < 5.5)
        }
    }

    PhysicsTestCase {
        name: "SharedMaterial"
        // All three cubes are sliding with a friction of 0
        goalReached: sharedCube1.x > -13 && sharedCube2.x > -13 && sharedControlCube.x > -13
        function test_1_bodies_slide_alike() {
            verify(!sharedCube1.stable)
            verify(!sharedCube2.stable)
            fuzzyCompare(sharedCube1.x, sharedCube2.x, 0.5)
        }
        function test_2_edit_shared_material() {
            editedMaterial.staticFriction = 1
            editedMaterial.dynamicFriction = 1
        }
    }

    PhysicsTestCase {
        name: "SharedMaterial2"
        // The edit brings both cubes using the material to a halt
        goalReached: sharedCube1.stable && sharedCube2.stable
        function test_edit_reaches_every_body_using_the_material() {
            fuzzyCompare(sharedCube1.x, sharedCube2.x, 0.5)
            // The cube using another material is unaffected and slides further
            verify(!sharedControlCube.stable)
            verify(sharedControlCube.x > sharedCube1.x + 2)
        }
    }

    PhysicsTestCase {
        name: "UnsetMaterial"
        // Both cubes are sliding with their own slippery material
        goalReached: unsetControlCube.x > -13 && unsetCube.x > -13
        function test_1_bodies_slide_alike_with_the_same_material() {
            verify(!unsetControlCube.stable)
            verify(!unsetCube.stable)
            fuzzyCompare(unsetCube.x, unsetControlCube.x, 0.5)
        }
        function test_2_unset_material() {
            unsetCube.physicsMaterial = null
            materialUnset = true
        }
    }

    PhysicsTestCase {
        name: "UnsetMaterial2"
        // Back to the default friction, which is higher, so that cube stops first
        goalReached: materialUnset && unsetCube.stable
        function test_body_uses_default_properties_again() {
            // The control cube keeps the slippery material and slides further
            verify(!unsetControlCube.stable)
            verify(unsetControlCube.x > unsetCube.x + 2)
        }
    }
}
