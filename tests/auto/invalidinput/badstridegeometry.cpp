// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "badstridegeometry.h"
#include <QtGui/QVector3D>

BadStrideGeometry::BadStrideGeometry()
{
    // stride 12 (one vec3 per vertex), but the position attribute is declared at
    // offset 8 -- offset + sizeof(vec3) = 20 doesn't fit inside a 12-byte stride.
    QByteArray vertexData(3 * sizeof(QVector3D), Qt::Initialization::Uninitialized);
    setVertexData(vertexData);
    setStride(sizeof(QVector3D));
    setBounds(QVector3D(-1.0f, -1.0f, -1.0f), QVector3D(1.0f, 1.0f, 1.0f));
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Triangles);
    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic, 8,
                 QQuick3DGeometry::Attribute::F32Type);
}
