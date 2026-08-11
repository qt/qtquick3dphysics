// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick3D
import QtQuick3D.Physics

StaticRigidBody {
    sendContactReports: true
    collisionShapes: BoxShape {
        extents: Qt.vector3d(8, 2, 4)
    }
}
