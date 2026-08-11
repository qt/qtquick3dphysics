// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef NOPOSITIONGEOMETRY_H
#define NOPOSITIONGEOMETRY_H

#include <QtQuick3D/QQuick3DGeometry>

// A deliberately malformed geometry: it has non-empty vertex data and a
// Triangles primitive type, but no PositionSemantic attribute at all.
class NoPositionGeometry : public QQuick3DGeometry
{
    Q_OBJECT
    QML_NAMED_ELEMENT(NoPositionGeometry)

public:
    NoPositionGeometry();
};

#endif
