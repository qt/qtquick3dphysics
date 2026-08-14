// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick3D

Item {
    id: wasd
    focus: true
    anchors.fill: parent

    readonly property vector3d moveVector: {
        let x = 0;
        let y = 0;
        let z = 0;

        if (w) z -= 1;
        if (s) z += 1;
        if (a) x -= 1;
        if (d) x += 1;
        if (space) y += 1; // Continuous upward thrust for jetpack

        let dir = Qt.vector3d(x, y, z);
        return dir.length() > 0 ? dir.normalized() : Qt.vector3d(0, 0, 0);
    }

    // Direct flag for single-shot jump logic
    readonly property bool spacePressed: space

    property bool w: false
    property bool a: false
    property bool s: false
    property bool d: false
    property bool space: false

    property real rotationX: 0 // Pitch (looking up/down)
    property real rotationY: 180 // Yaw (looking left/right), starting with the sun behind
    property real mouseSensitivity: 0.15

    Keys.onPressed: (event) => {
                        if (event.isAutoRepeat) return;
                        updateKey(event.key, true);
                    }

    Keys.onReleased: (event) => {
                         if (event.isAutoRepeat) return;
                         updateKey(event.key, false);
                     }

    function updateKey(key, pressed) {
        switch (key) {
        case Qt.Key_W: w = pressed; break;
        case Qt.Key_A: a = pressed; break;
        case Qt.Key_S: s = pressed; break;
        case Qt.Key_D: d = pressed; break;
        case Qt.Key_Space: space = pressed; break;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property point lastPos: Qt.point(0, 0)

        onPressed: (mouse) => {
                       lastPos = Qt.point(mouse.x, mouse.y);
                       wasd.forceActiveFocus();
                   }

        onPositionChanged: (mouse) => {
                               // Handle drag when right or left mouse button is held down
                               if (pressedButtons & (Qt.RightButton | Qt.LeftButton)) {
                                   let deltaX = mouse.x - lastPos.x;
                                   let deltaY = mouse.y - lastPos.y;

                                   // Update rotations based on mouse delta
                                   wasd.rotationY -= deltaX * wasd.mouseSensitivity;
                                   wasd.rotationX -= deltaY * wasd.mouseSensitivity;

                                   // Clamp pitch angle to avoid camera flipping (-89 to +89 degrees)
                                   wasd.rotationX = Math.max(-89.0, Math.min(89.0, wasd.rotationX));
                               }
                               lastPos = Qt.point(mouse.x, mouse.y);
                           }
    }
}
