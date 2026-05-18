// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtQuick3D.Physics

DistanceJoint {
    //yLimit: Math.PI/2
    //zLimit: Math.PI/2
    minDistance: 0
    maxDistance: 100

    positionA: Qt.vector3d(100, 0, 0)
    positionB: Qt.vector3d(-100, 0, 0)
}
