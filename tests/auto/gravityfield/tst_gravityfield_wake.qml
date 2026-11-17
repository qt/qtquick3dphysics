// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick3D.Physics.Helpers
import QtQuick3D.Physics.TestUtils

// A body asleep under a gravity that goes away, or stops reaching it, is woken
// to fall under what is left. Each cube is held up by a field until it falls
// asleep; then that gravity is taken from it, and only waking lets it fall. A
// field without shapes cancels the world's gravity exactly, so its cube floats
// where it starts. A field with shapes only finds a body after the first step,
// by which time the body is falling, so it pushes its cube up against a
// ceiling instead.
Item {
    width: 800
    height: 600
    visible: true

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, -981, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 600, 2400)
            eulerRotation.x: -10
            clipFar: 8000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
        }

        // Asleep once, then `action` is run. Falls when it has dropped well
        // below where it slept.
        component Floater: DynamicRigidBody {
            id: floater
            property bool sleptFirst: false
            property var action: null
            readonly property bool fell: sleptFirst && position.y < -50
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !sleptFirst) {
                    sleptFirst = true;
                    action();
                }
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.4, 0.4, 0.4)
                materials: PrincipledMaterial {
                    baseColor: "#4a86e8"
                }
            }
        }

        component Lift: GravityField {
            direction: Qt.vector3d(0, 1, 0)
            gravity: 1962
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 200, 200)
            }
        }

        component FieldLift: GravityField {
            direction: Qt.vector3d(0, 1, 0)
            gravity: 981
        }

        StaticRigidBody {
            position: Qt.vector3d(-750, 100, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(1900, 20, 200)
            }
        }

        // Shaped field destroyed
        Loader3D {
            id: destroyedShapedField
            sourceComponent: Lift {
                position: Qt.vector3d(-1500, 0, 0)
            }
        }
        Floater {
            id: destroyedShapedFieldCube
            position: Qt.vector3d(-1500, 0, 0)
            action: () => destroyedShapedField.active = false
        }

        // Shaped field moved off the body
        Lift {
            id: movedShapedField
            position: Qt.vector3d(-1000, 0, 0)
        }
        Floater {
            id: movedShapedFieldCube
            position: Qt.vector3d(-1000, 0, 0)
            action: () => movedShapedField.position = Qt.vector3d(-1000, 0, -3000)
        }

        // Shaped field told to ignore the body's group
        Lift {
            id: ignoringShapedField
            position: Qt.vector3d(-500, 0, 0)
        }
        Floater {
            id: ignoredByShapedFieldCube
            position: Qt.vector3d(-500, 0, 0)
            filterGroup: 1
            action: () => ignoringShapedField.filterIgnoreGroups = 1 << 1
        }

        // Body told to ignore the shaped field's group
        Lift {
            position: Qt.vector3d(0, 0, 0)
            filterGroup: 2
        }
        Floater {
            id: ignoringShapedFieldCube
            position: Qt.vector3d(0, 0, 0)
            action: () => ignoringShapedFieldCube.filterIgnoreGroups = 1 << 2
        }

        // Each field reaches only its own group, so that it leaves the bodies
        // of the other cases alone.

        // Field destroyed
        Loader3D {
            id: destroyedField
            sourceComponent: FieldLift {
                filterIgnoreGroups: ~(1 << 10)
            }
        }
        Floater {
            id: destroyedFieldCube
            position: Qt.vector3d(500, 0, 0)
            filterGroup: 10
            action: () => destroyedField.active = false
        }

        // Field told to ignore the body's group
        FieldLift {
            id: ignoringField
            filterIgnoreGroups: ~(1 << 11)
        }
        Floater {
            id: ignoredByFieldCube
            position: Qt.vector3d(1000, 0, 0)
            filterGroup: 11
            action: () => ignoringField.filterIgnoreGroups = ~0
        }

        // Body told to ignore the field's group
        FieldLift {
            filterGroup: 12
            filterIgnoreGroups: ~(1 << 13)
        }
        Floater {
            id: ignoringFieldCube
            position: Qt.vector3d(1500, 0, 0)
            filterGroup: 13
            action: () => ignoringFieldCube.filterIgnoreGroups = 1 << 12
        }

        // Field that gets shapes away from the body: the body is left outside
        // them, and loses the field's gravity.
        BoxShape {
            id: farBox
            extents: Qt.vector3d(100, 100, 100)
        }
        FieldLift {
            id: shapingField
            position: Qt.vector3d(2000, 0, -3000)
            filterIgnoreGroups: ~(1 << 14)
        }
        Floater {
            id: leftOutsideCube
            position: Qt.vector3d(2000, 0, 0)
            filterGroup: 14
            action: () => shapingField.collisionShapes = [farBox]
        }

        // Field whose shapes, away from the body, are taken away: it now acts
        // on the whole scene, and lifts the body off the floor it slept on.
        StaticRigidBody {
            position: Qt.vector3d(2500, -40, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 40, 200)
            }
        }
        Lift {
            id: unshapingField
            position: Qt.vector3d(2500, 0, -3000)
            filterIgnoreGroups: ~(1 << 15)
        }
        DynamicRigidBody {
            id: liftedCube
            position: Qt.vector3d(2500, 0, 0)
            filterGroup: 15
            property bool sleptFirst: false
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !sleptFirst) {
                    sleptFirst = true;
                    unshapingField.collisionShapes = [];
                }
            }
        }

        // Shaped field moved onto a body asleep on a floor: the body is woken
        // and lifted. A Directional field does not wake what it acts on when
        // it moves, so only the body being reported entering its shapes wakes
        // it.
        component Sleeper: DynamicRigidBody {
            property bool sleptFirst: false
            property var action: null
            readonly property bool lifted: sleptFirst && position.y > 100
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            onIsSleepingChanged: (sleeping) => {
                if (sleeping && !sleptFirst) {
                    sleptFirst = true;
                    action();
                }
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(3500, -40, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 40, 200)
            }
        }
        Lift {
            id: movedOntoField
            position: Qt.vector3d(3500, 0, -3000)
        }
        Sleeper {
            id: movedOntoCube
            position: Qt.vector3d(3500, 0, 0)
            action: () => movedOntoField.position = Qt.vector3d(3500, 0, 0)
        }

        // The same with a Point field, centred above the body.
        StaticRigidBody {
            position: Qt.vector3d(4500, -40, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(200, 40, 200)
            }
        }
        GravityField {
            id: movedOntoPointField
            mode: GravityField.Point
            gravity: 1962
            position: Qt.vector3d(4500, 300, -3000)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(800, 800, 800)
            }
        }
        Sleeper {
            id: movedOntoPointCube
            position: Qt.vector3d(4500, 0, 0)
            action: () => movedOntoPointField.position = Qt.vector3d(4500, 300, 0)
        }

        PhysicsTestCase {
            name: "GravityField with shapes wakes the bodies inside it when it is destroyed"
            goalReached: destroyedShapedFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField with shapes wakes a body it moves off"
            goalReached: movedShapedFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField with shapes wakes a body it moves onto"
            goalReached: movedOntoCube.lifted
        }

        PhysicsTestCase {
            name: "Point GravityField with shapes wakes a body it moves onto"
            goalReached: movedOntoPointCube.lifted
        }

        PhysicsTestCase {
            name: "GravityField with shapes wakes a body it is told to ignore"
            goalReached: ignoredByShapedFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField with shapes wakes a body told to ignore it"
            goalReached: ignoringShapedFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField wakes the bodies it acts on when it is destroyed"
            goalReached: destroyedFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField wakes a body it is told to ignore"
            goalReached: ignoredByFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField wakes a body told to ignore it"
            goalReached: ignoringFieldCube.fell
        }

        PhysicsTestCase {
            name: "GravityField that gets shapes wakes a body left outside them"
            goalReached: leftOutsideCube.fell
        }

        PhysicsTestCase {
            name: "GravityField that loses its shapes wakes the bodies of the scene"
            goalReached: liftedCube.sleptFirst && liftedCube.position.y > 100
        }
    }
}
