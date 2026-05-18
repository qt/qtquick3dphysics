// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtQuick3D.Physics

DynamicRigidBody {
    scale: Qt.vector3d(2, 0.5, 0.5)
    collisionShapes: BoxShape {}
    Model {
        source: "#Cube"
        materials: PrincipledMaterial {
            baseColor: "pink"
        }
    }
}
