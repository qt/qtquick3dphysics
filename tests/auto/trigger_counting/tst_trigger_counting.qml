// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

// Tests what a TriggerBody reports as being inside it.
//
// bodyExited is documented as being emitted when the trigger is no longer
// penetrated by the body, and collisionCount as the number of bodies currently
// colliding with it. PhysX reports one pair per pair of shapes, so a body with
// more than one shape, or a trigger with more than one shape, is reported
// several times over, and the shapes of a body are all replaced whenever any one
// of them changes, so the pairs of the shapes that went away are reported as
// lost. Neither of the two documented promises holds unless the reports are
// followed per pair of shapes.
//
// One scene per thing that can happen to a body a trigger holds, left to right
// and front to back:
//
//   two shapes, one leaves     a body deleted while inside
//   shapes rebuilt while in    shapes destroyed while inside
//   a trigger rebuilt          a shape carried out       a sleeping body
//   a body that only listens    a body that stops asking
//
// Both directions of reporting are per body: the trigger's bodyEntered and
// bodyExited, and the body's own enteredTriggerBody and exitedTriggerBody, which
// a body asks for separately and can ask for on its own.
//
// Bodies and shapes are deleted here while a trigger is holding them, and what
// it holds them by is pointers. Every handler below reads the body a report
// hands it and counts a body it did not expect as a hundred of them, so a stale
// pointer shows up as a failure rather than as a number that happens to look
// right. Worth running against a module built with -fsanitize=address, which
// makes a stale one that is read a use after free:
//
//   ASAN_OPTIONS=detect_leaks=0 QML_IMPORT_PATH=<build>/qml \
//       ./test_auto_trigger_counting
//
// The trigger volumes are drawn and light up while they report holding
// something, so the scene can also be judged by eye: every volume with a block
// in it has to be lit, and only those.

import QtCore
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

    PhysicsWorld {
        id: world
        // Nothing should move except what the test moves itself.
        gravity: Qt.vector3d(0, 0, 0)
        running: true
        typicalLength: 100
        typicalSpeed: 1000
        minimumTimestep: 16
        maximumTimestep: 16
        scene: viewport.scene

        // The scenes are stepped in simulated time, not wall clock time, so a
        // renderer that cannot keep up makes the test slower instead of making
        // it sample a scene that has not moved yet.
        property int frames: 0
        onFrameDone: world.frames++
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#151a3f"
            backgroundMode: SceneEnvironment.Color
        }

        PerspectiveCamera {
            position: Qt.vector3d(500, 300, 2100)
            eulerRotation.x: -9
            clipFar: 6000
        }

        DirectionalLight {
            eulerRotation.x: -35
            eulerRotation.y: 25
        }

        // A trigger volume, drawn so it brightens while it reports holding a body.
        component Volume: TriggerBody {
            id: volume
            property color tint: "#4488ff"
            property real span: 300
            readonly property bool occupied: volume.collisionCount > 0
            // What the volume is drawn as holding, which is what it counts
            // unless the scene it is in has a body it does not count.
            property bool lit: volume.occupied

            collisionShapes: BoxShape {
                extents: Qt.vector3d(volume.span, volume.span, volume.span)
            }

            Model {
                source: "#Cube"
                scale: Qt.vector3d(volume.span / 100, volume.span / 100, volume.span / 100)
                materials: PrincipledMaterial {
                    baseColor: volume.tint
                    opacity: volume.lit ? 0.55 : 0.14
                    lighting: PrincipledMaterial.NoLighting
                }
            }
        }

        // Reached once the simulation has taken "frames" steps since this was
        // started, which is what every step of every scene below waits for.
        component AfterFrames: Timer {
            id: gate
            property int frames: 36
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
                baseColor: "#e8e8e8"
                roughness: 0.5
            }
        }

        // ---- one body, two shapes, sliding out ----

        Volume {
            id: straddled
            objectName: "straddled"
            position: Qt.vector3d(-400, 0, 0)
            tint: "#4488ff"
        }

        DynamicRigidBody {
            id: strider
            objectName: "strider"
            isKinematic: true
            sendTriggerReports: true
            // Both directions of the same reports, which are both per body.
            receiveTriggerReports: true
            kinematicPosition: Qt.vector3d(-400 + slide.offset, 0, 0)
            collisionShapes: [
                BoxShape { extents: Qt.vector3d(40, 40, 40); position: Qt.vector3d(-100, 0, 0) },
                BoxShape { extents: Qt.vector3d(40, 40, 40); position: Qt.vector3d(100, 0, 0) }
            ]

            Block { position: Qt.vector3d(-100, 0, 0) }
            Block { position: Qt.vector3d(100, 0, 0) }
        }

        QtObject {
            id: slide
            property real offset: 0
            property int exits: 0
            // Read once the leading shape is outside the trigger and the trailing
            // one is still 30 units inside it, and once both are clear.
            property int countWhileHalfOut: -1
            property int exitsWhileHalfOut: -1
            property int countWhenOut: -1
            property int exitsWhenOut: -1
            // The same, as the body itself hears it.
            property int enteredSelf: 0
            property int exitedSelf: 0
            property int selfEntersWhileHalfOut: -1
            property int selfExitsWhileHalfOut: -1
            property int selfExitsWhenOut: -1
        }

        Connections {
            target: straddled
            function onBodyExited(body) {
                slide.exits += (body.objectName === "strider" ? 1 : 100);
            }
        }

        Connections {
            target: strider
            function onEnteredTriggerBody(body) {
                slide.enteredSelf += (body.objectName === "straddled" ? 1 : 100);
            }
            function onExitedTriggerBody(body) {
                slide.exitedSelf += (body.objectName === "straddled" ? 1 : 100);
            }
        }

        AfterFrames {
            running: true
            onReached: { slide.offset = 120; halfOutGate.running = true; }
        }

        AfterFrames {
            id: halfOutGate
            onReached: {
                slide.countWhileHalfOut = straddled.collisionCount;
                slide.exitsWhileHalfOut = slide.exits;
                slide.selfEntersWhileHalfOut = slide.enteredSelf;
                slide.selfExitsWhileHalfOut = slide.exitedSelf;
                slide.offset = 600;
                goneGate.running = true;
            }
        }

        AfterFrames {
            id: goneGate
            onReached: {
                slide.countWhenOut = straddled.collisionCount;
                slide.exitsWhenOut = slide.exits;
                slide.selfExitsWhenOut = slide.exitedSelf;
            }
        }

        // ---- a body deleted while inside ----

        Volume {
            id: outlived
            position: Qt.vector3d(1400, 0, 0)
            tint: "#ff9a2e"
        }

        DynamicRigidBody {
            id: doomed
            objectName: "doomed"
            sendTriggerReports: true
            position: Qt.vector3d(1400, 0, 0)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }

            Block {}
        }

        QtObject {
            id: deletion
            property int countAfter: -1
        }

        AfterFrames {
            frames: 56; running: true
            onReached: { doomed.destroy(); deletedGate.running = true; }
        }

        AfterFrames {
            id: deletedGate
            // Long enough that the body's actor has actually been taken out of
            // the scene, not just its QML object deleted.
            frames: 75
            onReached: deletion.countAfter = outlived.collisionCount
        }

        // ---- the shapes of a body inside rebuilt over and over ----

        Volume {
            id: shifting
            position: Qt.vector3d(-400, 0, -900)
            tint: "#63d471"
        }

        DynamicRigidBody {
            id: wiggler
            objectName: "wiggler"
            isKinematic: true
            sendTriggerReports: true
            kinematicPosition: Qt.vector3d(-400 + wiggle.offset, 0, -900)
            collisionShapes: BoxShape {
                id: wigglingShape
                extents: Qt.vector3d(40, 40, 40)
                position: Qt.vector3d(wiggle.shapeX, 0, 0)
            }

            Block { position: wigglingShape.position }
        }

        QtObject {
            id: wiggle
            property real offset: 0
            // Moving a shape within its body replaces every PhysX shape of that
            // body, so this keeps them being rebuilt while the body sits inside.
            property real shapeX: 0
            property int enters: 0
            property int exits: 0
            property int countWhileRebuilt: -1
            property int entersWhileRebuilt: -1
            property int exitsWhileRebuilt: -1
            property int countWhenOut: -1
            property int exitsWhenOut: -1
        }

        Connections {
            target: shifting
            function onBodyEntered(body) {
                wiggle.enters += (body.objectName === "wiggler" ? 1 : 100);
            }
            function onBodyExited(body) {
                wiggle.exits += (body.objectName === "wiggler" ? 1 : 100);
            }
        }

        Timer {
            interval: 16; running: true; repeat: true
            onTriggered: wiggle.shapeX = wiggle.shapeX > 0 ? -60 : 60
        }

        AfterFrames {
            frames: 62; running: true
            onReached: {
                wiggle.countWhileRebuilt = shifting.collisionCount;
                wiggle.entersWhileRebuilt = wiggle.enters;
                wiggle.exitsWhileRebuilt = wiggle.exits;
                wiggle.offset = 600;
                wiggleGoneGate.running = true;
            }
        }

        AfterFrames {
            id: wiggleGoneGate
            onReached: {
                wiggle.countWhenOut = shifting.collisionCount;
                wiggle.exitsWhenOut = wiggle.exits;
            }
        }

        // ---- the shapes of a body inside destroyed one by one ----

        Volume {
            id: trimmed
            position: Qt.vector3d(1400, 0, -900)
            tint: "#ffd34e"
        }

        DynamicRigidBody {
            id: shedder
            objectName: "shedder"
            isKinematic: true
            sendTriggerReports: true
            kinematicPosition: Qt.vector3d(1400, 0, -900)
            collisionShapes: [
                BoxShape {
                    id: keptShape
                    extents: Qt.vector3d(40, 40, 40)
                    position: Qt.vector3d(-60, 0, 0)
                },
                BoxShape {
                    id: droppedShape
                    extents: Qt.vector3d(40, 40, 40)
                    position: Qt.vector3d(60, 0, 0)
                }
            ]

            Block { position: Qt.vector3d(-60, 0, 0) }
            Block { position: Qt.vector3d(60, 0, 0) }
        }

        QtObject {
            id: trim
            property int exits: 0
            property int countWithOneShape: -1
            property int exitsWithOneShape: -1
            property int countWithNoShapes: -1
            property int exitsWithNoShapes: -1
        }

        Connections {
            target: trimmed
            function onBodyExited(body) {
                trim.exits += (body.objectName === "shedder" ? 1 : 100);
            }
        }

        AfterFrames {
            frames: 44; running: true
            onReached: { droppedShape.destroy(); oneShapeGate.running = true; }
        }

        AfterFrames {
            id: oneShapeGate
            frames: 44
            onReached: {
                trim.countWithOneShape = trimmed.collisionCount;
                trim.exitsWithOneShape = trim.exits;
                keptShape.destroy();
                noShapesGate.running = true;
            }
        }

        AfterFrames {
            id: noShapesGate
            frames: 44
            onReached: {
                trim.countWithNoShapes = trimmed.collisionCount;
                trim.exitsWithNoShapes = trim.exits;
            }
        }

        // ---- the shapes of the trigger itself rebuilt over and over ----

        Volume {
            id: resized
            position: Qt.vector3d(-1600, 0, -1800)
            tint: "#4dd0e1"
            span: resize.span
        }

        DynamicRigidBody {
            id: sitter
            objectName: "sitter"
            isKinematic: true
            sendTriggerReports: true
            kinematicPosition: Qt.vector3d(-1600, 0, -1800)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
            }

            Block {}
        }

        QtObject {
            id: resize
            property real span: 300
            property int enters: 0
            property int exits: 0
            property int countWhileRebuilt: -1
            property int entersWhileRebuilt: -1
            property int exitsWhileRebuilt: -1
        }

        Connections {
            target: resized
            function onBodyEntered(body) {
                resize.enters += (body.objectName === "sitter" ? 1 : 100);
            }
            function onBodyExited(body) {
                resize.exits += (body.objectName === "sitter" ? 1 : 100);
            }
        }

        Timer {
            interval: 16; running: true; repeat: true
            onTriggered: resize.span = resize.span > 320 ? 300 : 340
        }

        AfterFrames {
            frames: 62; running: true
            onReached: {
                resize.countWhileRebuilt = resized.collisionCount;
                resize.entersWhileRebuilt = resize.enters;
                resize.exitsWhileRebuilt = resize.exits;
            }
        }

        // ---- a shape carried out of the trigger by itself ----

        Volume {
            id: vacated
            position: Qt.vector3d(500, 0, -1800)
            tint: "#c86bff"
        }

        DynamicRigidBody {
            id: stayer
            objectName: "stayer"
            isKinematic: true
            sendTriggerReports: true
            kinematicPosition: Qt.vector3d(500, 0, -1800)
            // The body stays where it is and its only shape is moved out from
            // under it, which the simulation reports as the pair of a shape that
            // is already gone and nothing else.
            collisionShapes: BoxShape {
                id: carriedShape
                extents: Qt.vector3d(40, 40, 40)
                position: Qt.vector3d(carry.shapeX, 0, 0)
            }

            Block { position: carriedShape.position }
        }

        QtObject {
            id: carry
            property real shapeX: 0
            property int exits: 0
            property int countInside: -1
            property int countOutside: -1
            property int exitsOutside: -1
        }

        Connections {
            target: vacated
            function onBodyExited(body) {
                carry.exits += (body.objectName === "stayer" ? 1 : 100);
            }
        }

        AfterFrames {
            running: true
            onReached: {
                carry.countInside = vacated.collisionCount;
                carry.shapeX = 400;
                carriedGate.running = true;
            }
        }

        AfterFrames {
            id: carriedGate
            onReached: {
                carry.countOutside = vacated.collisionCount;
                carry.exitsOutside = carry.exits;
            }
        }

        // ---- the shapes of a sleeping body inside rebuilt ----

        Volume {
            id: undisturbed
            position: Qt.vector3d(2600, 0, -1800)
            tint: "#ff7b7b"
        }

        DynamicRigidBody {
            // Left to the simulation, and with nothing to move it, so it falls
            // asleep where it is well before its shape is nudged.
            id: dozer
            objectName: "dozer"
            sendTriggerReports: true
            position: Qt.vector3d(2600, 0, -1800)
            collisionShapes: BoxShape {
                extents: Qt.vector3d(40, 40, 40)
                position: Qt.vector3d(doze.shapeX, 0, 0)
            }

            Block { position: Qt.vector3d(doze.shapeX, 0, 0) }
        }

        QtObject {
            id: doze
            property real shapeX: 0
            property int exits: 0
            property int countAfterNudge: -1
            property int exitsAfterNudge: -1
        }

        Connections {
            target: undisturbed
            function onBodyExited(body) {
                doze.exits += (body.objectName === "dozer" ? 1 : 100);
            }
        }

        AfterFrames {
            // Well past the simulated second or so it takes the body to fall
            // asleep where it is.
            frames: 94; running: true
            onReached: { doze.shapeX = 20; nudgedGate.running = true; }
        }

        AfterFrames {
            id: nudgedGate
            frames: 56
            onReached: {
                doze.countAfterNudge = undisturbed.collisionCount;
                doze.exitsAfterNudge = doze.exits;
            }
        }

        // ---- a body that only asked to be told itself ----

        Volume {
            id: unwitting
            objectName: "unwitting"
            position: Qt.vector3d(500, 0, -2700)
            tint: "#9fe870"
            // It does not count this body, so what it counts is not what it is
            // drawn as holding.
            lit: listen.enters > listen.exits
        }

        DynamicRigidBody {
            id: listener
            objectName: "listener"
            isKinematic: true
            // Without sendTriggerReports the trigger neither counts it nor
            // reports it, but it is still told about itself, once for the two
            // shapes it has inside.
            receiveTriggerReports: true
            kinematicPosition: Qt.vector3d(500 + listen.offset, 0, -2700)
            collisionShapes: [
                BoxShape { extents: Qt.vector3d(40, 40, 40); position: Qt.vector3d(-100, 0, 0) },
                BoxShape { extents: Qt.vector3d(40, 40, 40); position: Qt.vector3d(100, 0, 0) }
            ]

            Block { position: Qt.vector3d(-100, 0, 0) }
            Block { position: Qt.vector3d(100, 0, 0) }
        }

        QtObject {
            id: listen
            property real offset: 0
            property int enters: 0
            property int exits: 0
            property int triggerReports: 0
            property int entersInside: -1
            property int countInside: -1
            property int triggerReportsInside: -1
            property int exitsWhenOut: -1
            property int countWhenOut: -1
        }

        Connections {
            target: listener
            function onEnteredTriggerBody(body) {
                listen.enters += (body.objectName === "unwitting" ? 1 : 100);
            }
            function onExitedTriggerBody(body) {
                listen.exits += (body.objectName === "unwitting" ? 1 : 100);
            }
        }

        Connections {
            target: unwitting
            // Neither of these is about a body that did not ask for them.
            function onBodyEntered(body) { listen.triggerReports++; }
            function onBodyExited(body) { listen.triggerReports++; }
        }

        AfterFrames {
            running: true
            onReached: {
                listen.entersInside = listen.enters;
                listen.countInside = unwitting.collisionCount;
                listen.triggerReportsInside = listen.triggerReports;
                listen.offset = 600;
                listenGoneGate.running = true;
            }
        }

        AfterFrames {
            id: listenGoneGate
            onReached: {
                listen.exitsWhenOut = listen.exits;
                listen.countWhenOut = unwitting.collisionCount;
            }
        }

        // ---- a body that stops asking while it is inside ----

        Volume {
            id: forsaken
            objectName: "forsaken"
            position: Qt.vector3d(2600, 0, -2700)
            tint: "#ff6fb5"
        }

        DynamicRigidBody {
            id: quitter
            objectName: "quitter"
            isKinematic: true
            // Turned off while the body is inside, so nothing is asked for by
            // the time it leaves. The trigger still has to stop holding it, and
            // still owes it the report it was holding it for.
            sendTriggerReports: quit.asking
            kinematicPosition: Qt.vector3d(2600 + quit.offset, 0, -2700)
            collisionShapes: BoxShape {
                id: quitterShape
                extents: Qt.vector3d(40, 40, 40)
                position: Qt.vector3d(quit.shapeX, 0, 0)
            }

            Block { position: quitterShape.position }
        }

        QtObject {
            id: quit
            property bool asking: true
            property real offset: 0
            // Moved once the body has stopped asking, to rebuild its shapes
            // while it is inside: the pairs of the old shape have to be taken
            // up again by the shape that replaces it, whatever the body is
            // asking for by then.
            property real shapeX: 0
            property int exits: 0
            property int countInside: -1
            property int countAfterRebuild: -1
            property int exitsAfterRebuild: -1
            property int countWhenOut: -1
            property int exitsWhenOut: -1
        }

        Connections {
            target: forsaken
            function onBodyExited(body) {
                quit.exits += (body.objectName === "quitter" ? 1 : 100);
            }
        }

        AfterFrames {
            running: true
            onReached: {
                quit.countInside = forsaken.collisionCount;
                quit.asking = false;
                quit.shapeX = 20;
                quitRebuiltGate.running = true;
            }
        }

        AfterFrames {
            id: quitRebuiltGate
            onReached: {
                quit.countAfterRebuild = forsaken.collisionCount;
                quit.exitsAfterRebuild = quit.exits;
                quit.offset = 600;
                quitGoneGate.running = true;
            }
        }

        AfterFrames {
            id: quitGoneGate
            onReached: {
                quit.countWhenOut = forsaken.collisionCount;
                quit.exitsWhenOut = quit.exits;
            }
        }

        // ---- a body relaying its overlap from one shape to another ----

        Volume {
            id: relayed
            objectName: "relayed"
            position: Qt.vector3d(-1600, 0, -2700)
            span: 100
            tint: "#7de08d"
        }

        DynamicRigidBody {
            id: relayer
            objectName: "relayer"
            isKinematic: true
            sendTriggerReports: true
            // Two shapes, far enough apart that only one of them is ever inside
            // the volume. Moved by the distance between them in one step, which
            // takes the one that was inside out and brings the other one in, so
            // PhysX reports the pair it lost and the pair it found in the same
            // batch. The body has not left, and must not be reported as having.
            kinematicPosition: Qt.vector3d(-1600 + relay.offset, 0, -2700)
            collisionShapes: [
                BoxShape {
                    id: relayerLeft
                    extents: Qt.vector3d(40, 40, 40)
                    position: Qt.vector3d(-200, 0, 0)
                },
                BoxShape {
                    id: relayerRight
                    extents: Qt.vector3d(40, 40, 40)
                    position: Qt.vector3d(200, 0, 0)
                }
            ]

            Block { position: relayerLeft.position }
            Block { position: relayerRight.position }
        }

        QtObject {
            id: relay
            // The left shape starts inside, the right one outside.
            property real offset: 200
            property int enters: 0
            property int exits: 0
            property int countInside: -1
            property int entersInside: -1
            property int countAfterRelay: -1
            property int entersAfterRelay: -1
            property int exitsAfterRelay: -1
        }

        Connections {
            target: relayed
            function onBodyEntered(body) {
                relay.enters += (body.objectName === "relayer" ? 1 : 100);
            }
            function onBodyExited(body) {
                relay.exits += (body.objectName === "relayer" ? 1 : 100);
            }
        }

        AfterFrames {
            running: true
            onReached: {
                relay.countInside = relayed.collisionCount;
                relay.entersInside = relay.enters;
                relay.offset = -200;
                relayGate.running = true;
            }
        }

        AfterFrames {
            id: relayGate
            onReached: {
                relay.countAfterRelay = relayed.collisionCount;
                relay.entersAfterRelay = relay.enters;
                relay.exitsAfterRelay = relay.exits;
            }
        }

        // ---- a body that starts asking while it is already inside ----

        Volume {
            id: unasked
            objectName: "unasked"
            position: Qt.vector3d(1400, 0, -2700)
            tint: "#c39bd3"
        }

        DynamicRigidBody {
            id: silent
            objectName: "silent"
            isKinematic: true
            // Asks for nothing as it enters, and starts asking once it is
            // inside. What it asks for then decides nothing about this stay, so
            // it must not be told it entered something it never crossed into.
            sendTriggerReports: mute.asking
            receiveTriggerReports: mute.asking
            kinematicPosition: Qt.vector3d(1400, 0, -2700)
            collisionShapes: BoxShape {
                id: silentShape
                extents: Qt.vector3d(40, 40, 40)
                position: Qt.vector3d(mute.shapeX, 0, 0)
            }

            Block { position: silentShape.position }
        }

        QtObject {
            id: mute
            property bool asking: false
            // Rebuilds the body's shapes while it sits inside, which is what
            // has PhysX report its pairs as found again.
            property real shapeX: 0
            property int enters: 0
            property int selfEnters: 0
            property int countAfterAsking: -1
            property int entersAfterAsking: -1
            property int selfEntersAfterAsking: -1
        }

        Timer {
            interval: 16; running: true; repeat: true
            onTriggered: mute.shapeX = mute.shapeX > 0 ? -20 : 20
        }

        Connections {
            target: unasked
            function onBodyEntered(body) {
                mute.enters += (body.objectName === "silent" ? 1 : 100);
            }
        }

        Connections {
            target: silent
            function onEnteredTriggerBody(body) {
                mute.selfEnters += (body.objectName === "unasked" ? 1 : 100);
            }
        }

        AfterFrames {
            running: true
            onReached: {
                mute.asking = true;
                mutedGate.running = true;
            }
        }

        AfterFrames {
            id: mutedGate
            onReached: {
                mute.countAfterAsking = unasked.collisionCount;
                mute.entersAfterAsking = mute.enters;
                mute.selfEntersAfterAsking = mute.selfEnters;
            }
        }

        // ---- what all of that has to add up to ----

        PhysicsTestCase {
            name: "one shape of two leaving does not report the body as gone"
            goalReached: slide.countWhileHalfOut === 1 && slide.exitsWhileHalfOut === 0
        }

        PhysicsTestCase {
            name: "the last shape leaving does report the body as gone"
            goalReached: slide.countWhenOut === 0 && slide.exitsWhenOut === 1
        }

        PhysicsTestCase {
            name: "the body hears about entering once, not once per shape"
            goalReached: slide.selfEntersWhileHalfOut === 1 && slide.selfExitsWhileHalfOut === 0
        }

        PhysicsTestCase {
            name: "the body hears about leaving when its last shape leaves"
            goalReached: slide.selfExitsWhenOut === 1
        }

        PhysicsTestCase {
            name: "a body deleted while inside stops being counted"
            goalReached: deletion.countAfter === 0
        }

        PhysicsTestCase {
            name: "a body whose shapes are rebuilt stays inside, and only once"
            goalReached: wiggle.countWhileRebuilt === 1 && wiggle.entersWhileRebuilt === 1
                         && wiggle.exitsWhileRebuilt === 0
        }

        PhysicsTestCase {
            name: "a body whose shapes were rebuilt still reports leaving"
            goalReached: wiggle.countWhenOut === 0 && wiggle.exitsWhenOut === 1
        }

        PhysicsTestCase {
            name: "one shape of two destroyed does not report the body as gone"
            goalReached: trim.countWithOneShape === 1 && trim.exitsWithOneShape === 0
        }

        PhysicsTestCase {
            name: "the last shape destroyed does report the body as gone"
            goalReached: trim.countWithNoShapes === 0 && trim.exitsWithNoShapes === 1
        }

        PhysicsTestCase {
            name: "rebuilding the shapes of the trigger reports nothing"
            goalReached: resize.countWhileRebuilt === 1 && resize.entersWhileRebuilt === 1
                         && resize.exitsWhileRebuilt === 0
        }

        PhysicsTestCase {
            name: "a shape moved out reports the body as gone"
            goalReached: carry.countInside === 1 && carry.countOutside === 0
                         && carry.exitsOutside === 1
        }

        PhysicsTestCase {
            name: "nudging the shape of a sleeping body keeps it inside"
            goalReached: doze.countAfterNudge === 1 && doze.exitsAfterNudge === 0
        }

        PhysicsTestCase {
            name: "a body that only listens is told once and counted not at all"
            goalReached: listen.entersInside === 1 && listen.countInside === 0
                         && listen.triggerReportsInside === 0
        }

        PhysicsTestCase {
            name: "a body that only listens is told about leaving once"
            goalReached: listen.exitsWhenOut === 1 && listen.countWhenOut === 0
        }

        PhysicsTestCase {
            name: "a body that stops asking while inside is still held"
            goalReached: quit.countInside === 1 && quit.countAfterRebuild === 1
                         && quit.exitsAfterRebuild === 0
        }

        PhysicsTestCase {
            name: "a body that starts asking while inside is not told it entered"
            goalReached: mute.countAfterAsking === 0 && mute.entersAfterAsking === 0
                         && mute.selfEntersAfterAsking === 0
        }

        PhysicsTestCase {
            name: "a body relaying its overlap in one step is still inside"
            goalReached: relay.countInside === 1 && relay.entersInside === 1
                         && relay.countAfterRelay === 1
        }

        PhysicsTestCase {
            name: "a body relaying its overlap in one step is not reported again"
            goalReached: relay.countAfterRelay === 1 && relay.entersAfterRelay === 1
                         && relay.exitsAfterRelay === 0
        }

        PhysicsTestCase {
            name: "a body that stops asking while inside is still let go of"
            goalReached: quit.countWhenOut === 0 && quit.exitsWhenOut === 1
        }
    }
}
