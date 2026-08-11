// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "nopositiongeometry.h"
#include <QtGui/QVector3D>

NoPositionGeometry::NoPositionGeometry()
{
    QByteArray vertexData(3 * sizeof(QVector3D), Qt::Initialization::Uninitialized);
    setVertexData(vertexData);
    setStride(sizeof(QVector3D));
    setBounds(QVector3D(-1.0f, -1.0f, -1.0f), QVector3D(1.0f, 1.0f, 1.0f));
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Triangles);

    // Deliberately do not call addAttribute(PositionSemantic, ...) here: this
    // is what used to hit a reachable Q_UNREACHABLE() in
    // QQuick3DPhysicsMesh's attributeBySemantic() helper.
}
