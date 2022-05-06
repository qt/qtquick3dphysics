/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of Qt Quick 3D Physics.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick
import QtQuick3D

Item {
    id: root

    property real xSpeed: 0.1
    property real ySpeed: 0.1

    property bool xInvert: false
    property bool yInvert: true

    property bool mouseEnabled: true
    property bool keysEnabled: true

    readonly property bool inputsNeedProcessing: status.useMouse

    property alias acceptedButtons: dragHandler.acceptedButtons

    implicitWidth: parent.width
    implicitHeight: parent.height
    focus: keysEnabled

    property bool moveForwards: false
    property bool moveBackwards: false
    property bool moveLeft: false
    property bool moveRight: false
    property bool moveUp: false
    property bool moveDown: false

    property vector2d cameraRotation: Qt.vector2d(0, 0)

    property bool sprintActive: false

    DragHandler {
        id: dragHandler
        target: null
        enabled: mouseEnabled
        onCentroidChanged: {
            mouseMoved(Qt.vector2d(centroid.position.x, centroid.position.y));
        }

        onActiveChanged: {
            if (active)
                mousePressed(Qt.vector2d(centroid.position.x, centroid.position.y));
            else
                mouseReleased(Qt.vector2d(centroid.position.x, centroid.position.y));
        }
    }

    TapHandler {
        onTapped: root.forceActiveFocus()
    }

    Keys.onPressed: (event)=> { if (keysEnabled) handleKeyPress(event) }
    Keys.onReleased: (event)=> { if (keysEnabled) handleKeyRelease(event) }

    function mousePressed(newPos) {
        root.forceActiveFocus()
        status.currentPos = newPos
        status.lastPos = newPos
        status.useMouse = true;
    }

    function mouseReleased(newPos) {
        status.useMouse = false;
    }

    function mouseMoved(newPos) {
        status.currentPos = newPos;
    }

    function forwardPressed() {
        moveForwards = true
        moveBackwards = false
    }

    function forwardReleased() {
        moveForwards = false
    }

    function backPressed() {
        moveBackwards = true
        moveForwards = false
    }

    function backReleased() {
        moveBackwards = false
    }

    function rightPressed() {
        moveRight = true
        moveLeft = false
    }

    function rightReleased() {
        moveRight = false
    }

    function leftPressed() {
        moveLeft = true
        moveRight = false
    }

    function leftReleased() {
        moveLeft = false
    }

    function upPressed() {
        moveUp = true
        moveDown = false
    }

    function upReleased() {
        moveUp = false
    }

    function downPressed() {
        moveDown = true
        moveUp = false
    }

    function downReleased() {
        moveDown = false
    }

    function shiftPressed() {
        sprintActive = true
    }

    function shiftReleased() {
        sprintActive = false
    }

    function handleKeyPress(event)
    {
        switch (event.key) {
        case Qt.Key_W:
        case Qt.Key_Up:
            forwardPressed();
            break;
        case Qt.Key_S:
        case Qt.Key_Down:
            backPressed();
            break;
        case Qt.Key_A:
        case Qt.Key_Left:
            leftPressed();
            break;
        case Qt.Key_D:
        case Qt.Key_Right:
            rightPressed();
            break;
        case Qt.Key_R:
        case Qt.Key_PageUp:
            upPressed();
            break;
        case Qt.Key_F:
        case Qt.Key_PageDown:
            downPressed();
            break;
        case Qt.Key_Shift:
            shiftPressed();
            break;
        }
    }

    function handleKeyRelease(event)
    {
        switch (event.key) {
        case Qt.Key_W:
        case Qt.Key_Up:
            forwardReleased();
            break;
        case Qt.Key_S:
        case Qt.Key_Down:
            backReleased();
            break;
        case Qt.Key_A:
        case Qt.Key_Left:
            leftReleased();
            break;
        case Qt.Key_D:
        case Qt.Key_Right:
            rightReleased();
            break;
        case Qt.Key_R:
        case Qt.Key_PageUp:
            upReleased();
            break;
        case Qt.Key_F:
        case Qt.Key_PageDown:
            downReleased();
            break;
        case Qt.Key_Shift:
            shiftReleased();
            break;
        }
    }

    Timer {
        id: updateTimer
        interval: 16
        repeat: true
        running: root.inputsNeedProcessing
        onTriggered: {
            processInputs();
        }
    }

    function processInputs()
    {
        if (root.inputsNeedProcessing)
            status.processInput();
    }

    QtObject {
        id: status

        property bool useMouse: false

        property vector2d lastPos: Qt.vector2d(0, 0)
        property vector2d currentPos: Qt.vector2d(0, 0)

        function processInput() {

            if (useMouse) {
                // Get the delta
                var delta = Qt.vector2d(lastPos.x - currentPos.x,
                                        lastPos.y - currentPos.y);
                // rotate x
                var rotateX = delta.x * xSpeed
                if (xInvert)
                    rotateX = -rotateX;
                cameraRotation.x += rotateX

                // rotate y
                var rotateY = delta.y * -ySpeed
                if (yInvert)
                    rotateY = -rotateY;
                cameraRotation.y += rotateY;
                lastPos = currentPos;
            }
        }
    }
}
