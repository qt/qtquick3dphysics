// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Physics

CharacterController {
    enableShapeHitCallback: true
    onShapeHit: (body, position, impulse, normal) => {
        shapeHitCount += 1
    }

    property int shapeHitCount: 0

    collisionShapes: CapsuleShape {
        height: 1
        diameter: 1
    }

    Model {
        eulerRotation.z: 90
        scale: Qt.vector3d(0.01, 0.01, 0.01)
        geometry: CapsuleGeometry {}
        materials: PrincipledMaterial {
            baseColor: "blue"
        }
    }
}
