// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef EXAMPLEGEOMETRY_H
#define EXAMPLEGEOMETRY_H

#include <QtQuick3D/QQuick3DGeometry>

class ExampleTriangleGeometry : public QQuick3DGeometry
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ExampleTriangleGeometry)

public:
    ExampleTriangleGeometry();
};

#endif
