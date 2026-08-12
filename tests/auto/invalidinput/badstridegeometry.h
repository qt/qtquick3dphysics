// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef BADSTRIDEGEOMETRY_H
#define BADSTRIDEGEOMETRY_H

#include <QtQuick3D/QQuick3DGeometry>

// A deliberately malformed geometry: its PositionSemantic attribute is declared
// at an offset that doesn't fit within the vertex stride, so reading a position
// out of every stride-sized record would walk past the end of the buffer.
class BadStrideGeometry : public QQuick3DGeometry
{
    Q_OBJECT
    QML_NAMED_ELEMENT(BadStrideGeometry)

public:
    BadStrideGeometry();
};

#endif
