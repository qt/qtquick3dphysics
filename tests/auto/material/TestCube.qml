// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtQuick3D.Physics

// TestCube is a DynamicRigidBody with a "stable" property. Its rotation is locked so that it
// slides instead of tumbling, which makes the distance it travels depend on friction alone.

DynamicRigidBody {
    property alias color: cubemat.baseColor
    massMode: DynamicRigidBody.CustomDensity
    density: 1000
    angularAxisLock: DynamicRigidBody.LockX | DynamicRigidBody.LockY | DynamicRigidBody.LockZ
    collisionShapes: BoxShape { extents: Qt.vector3d(1, 1, 1) }
    Model {
        source: "#Cube"
        scale: Qt.vector3d(1, 1, 1).times(0.01)
        eulerRotation: Qt.vector3d(0, 90, 0)
        materials: PrincipledMaterial {
            id: cubemat
            baseColor: "red"
        }
    }
    property bool stable: false
    property vector3d prevPos: Qt.vector3d(9999, 9999, 9999)
    property quaternion prevRot
    function checkStable() {
        if (position === prevPos && rotation === prevRot) {
            stable = true
        } else {
            prevPos = position
            prevRot = rotation
        }
    }
}
