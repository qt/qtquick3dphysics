// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtCore
import QtQuick
import QtTest
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick3D.Physics.Helpers
import QtQuick3D.Physics.TestUtils

// Which bodies a shaped field tracks, and what it reports. The shaped fields have no
// gravity, so only what the test moves moves.
Item {
    width: 800
    height: 600
    visible: true

    // A shaped field exposes no count, so it is read from C++.
    RegionProbe {
        id: probe
    }

    PhysicsWorld {
        id: world
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 10
        typicalSpeed: 100
        minimumTimestep: 15
        maximumTimestep: 15
        forceDebugDraw: true
        scene: viewport.scene
        // Gates wait in steps, which is what carries the reports.
        property int frames: 0
        onFrameDone: world.frames++
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        LookAtNode {
            target: strideShapedField
            position: Qt.vector3d(0, 500, -1500)
            PerspectiveCamera {
                clipFar: 4000
            }
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, 155, 0)
            brightness: 1.5
            ambientColor: "#3a3a44"
            castsShadow: false
            shadowFactor: 100
        }

        // The frame gate from tst_trigger_counting.
        component AfterFrames: Timer {
            id: gate
            property int frames: 30
            property int startedAt: 0
            signal reached()

            interval: 16
            repeat: true
            onRunningChanged: if (running) gate.startedAt = world.frames
            onTriggered: {
                if (world.frames - gate.startedAt < gate.frames)
                    return;
                gate.running = false;
                gate.reached();
            }
        }

        component Block: Model {
            source: "#Cube"
            scale: Qt.vector3d(0.4, 0.4, 0.4)
            materials: PrincipledMaterial {
                baseColor: "#4a86e8"
                roughness: 0.5
                metalness: 0.1
            }
        }

        // A body with two shapes straddling a shaped field's edge stays tracked until its
        // last shape is out.
        GravityField {
            id: strideShapedField
            position: Qt.vector3d(0, 0, 0)
            gravity: 0
            collisionShapes: BoxShape {
                extents: Qt.vector3d(300, 300, 300)
            }
        }

        DynamicRigidBody {
            id: strider
            isKinematic: true
            kinematicPosition: Qt.vector3d(stride.offset, 0, 0)
            collisionShapes: [
                BoxShape { extents: Qt.vector3d(40, 40, 40); position: Qt.vector3d(-100, 0, 0) },
                BoxShape { extents: Qt.vector3d(40, 40, 40); position: Qt.vector3d(100, 0, 0) }
            ]
            Block { x: -100 }
            Block { x: 100 }
        }

        QtObject {
            id: stride
            property real offset: 0
            property bool halfOut: false
            // Read once at that moment: both shapes inside also counts as one.
            property int countHalfOut: -1
        }

        AfterFrames {
            running: true
            onReached: { stride.offset = 120; halfOutGate.running = true; }
        }

        AfterFrames {
            id: halfOutGate
            onReached: {
                stride.countHalfOut = probe.trackedCount(strideShapedField);
                stride.halfOut = true;
            }
        }

        // A shaped field tracks what it can act on, whatever sendTriggerReports says: not
        // the static bodies, but the kinematic one, which can become dynamic while
        // inside.
        GravityField {
            id: kindShapedField
            position: Qt.vector3d(700, 0, 0)
            gravity: 0
            collisionShapes: BoxShape {
                extents: Qt.vector3d(300, 300, 300)
            }
        }

        StaticRigidBody {
            position: Qt.vector3d(700, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            Block { }
        }

        StaticRigidBody {
            position: Qt.vector3d(800, 0, 0)
            sendTriggerReports: true
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            Block { }
        }

        DynamicRigidBody {
            isKinematic: true
            kinematicPosition: Qt.vector3d(600, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            Block { }
        }

        // A body in both a shaped field and a TriggerBody gets enteredTriggerBody for the
        // TriggerBody only.
        GravityField {
            position: Qt.vector3d(-700, 0, 0)
            gravity: 0
            collisionShapes: BoxShape {
                extents: Qt.vector3d(300, 300, 300)
            }
        }

        TriggerBody {
            id: overlappingTrigger
            position: Qt.vector3d(-700, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(300, 300, 300)
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(3, 3, 3)
                materials: PrincipledMaterial {
                    baseColor: Qt.rgba(0.6, 0.8, 1.0, 0.12)
                    alphaMode: PrincipledMaterial.Blend
                    cullMode: Material.NoCulling
                    lighting: PrincipledMaterial.NoLighting
                }
            }
        }

        DynamicRigidBody {
            id: receiver
            isKinematic: true
            kinematicPosition: Qt.vector3d(-700, 0, 0)
            receiveTriggerReports: true
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }
            Block { }
            property int reports: 0
            property var reportedBy: null
            onEnteredTriggerBody: (region) => { reports++; reportedBy = region; }
        }

        QtObject {
            id: overlap
            // Waited out, so that a second report in the same frame would be seen.
            property bool settled: false
        }

        AfterFrames {
            frames: 60
            running: true
            onReached: overlap.settled = true
        }

        // A TriggerBody and a GravityField with the same shape keep the body
        // through its shape and the shaped field's being rebuilt.
        TriggerBody {
            id: twinTrigger
            position: Qt.vector3d(0, 0, 700)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(300, 300, 300)
            }
            property int entered: 0
            property int exited: 0
            onBodyEntered: entered++
            onBodyExited: exited++
        }

        GravityField {
            id: twinShapedField
            position: Qt.vector3d(0, 0, 700)
            gravity: 0
            collisionShapes: BoxShape {
                id: twinShapedFieldShape
                extents: Qt.vector3d(300, 300, 300)
            }
        }

        DynamicRigidBody {
            isKinematic: true
            kinematicPosition: Qt.vector3d(0, 0, 700)
            sendTriggerReports: true
            collisionShapes: BoxShape {
                extents: Qt.vector3d(twin.width, 40, 40)
            }
            Block { }
        }

        AfterFrames {
            frames: 40
            running: true
            onReached: {
                twinShapedFieldShape.extents = Qt.vector3d(310, 310, 310);
                twinGate.running = true;
            }
        }

        AfterFrames {
            id: twinGate
            frames: 40
            onReached: twin.settled = true
        }

        QtObject {
            id: twin
            property bool settled: false
            property real width: 40
            NumberAnimation on width {
                from: 30; to: 50
                duration: 500
                loops: Animation.Infinite
                running: true
            }
        }

        PhysicsTestCase {
            name: "TriggerBody and GravityField with one shape both keep a body through rebuilds"
            goalReached: twin.settled && twinTrigger.entered === 1 && twinTrigger.exited === 0
                         && twinTrigger.collisionCount === 1
                         && probe.trackedCount(twinShapedField) === 1
        }

        PhysicsTestCase {
            name: "GravityField with shapes keeps a body whose other shape is still inside"
            goalReached: stride.halfOut && stride.countHalfOut === 1
        }

        // Read once settled: the count passes through 1 on the way to anything
        // higher.
        PhysicsTestCase {
            name: "GravityField with shapes does not track a body it cannot act on"
            goalReached: overlap.settled && probe.trackedCount(kindShapedField) === 1
        }

        PhysicsTestCase {
            name: "GravityField with shapes does not report itself through enteredTriggerBody"
            goalReached: overlap.settled && receiver.reports === 1
                         && receiver.reportedBy === overlappingTrigger
        }
    }
}
