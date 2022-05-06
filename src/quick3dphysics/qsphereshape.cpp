/****************************************************************************
**
** Copyright (C) 2021 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Quick 3D Physics Module.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "qsphereshape_p.h"
#include <QtQuick3D/QQuick3DGeometry>

#include <geometry/PxSphereGeometry.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype SphereShape
    \inqmlmodule QtQuick3DPhysics
    \inherits CollisionShape
    \since 6.4
    \brief Sphere shape.

    This is the sphere shape.
    \note When using a scale with this shape, the x component will be used to scale the diameter of
    the sphere.
*/

/*!
    \qmlproperty float SphereShape::diameter
    This property defines the diameter of the sphere
*/

QSphereShape::QSphereShape() = default;

QSphereShape::~QSphereShape()
{
    delete m_physXGeometry;
}

float QSphereShape::diameter() const
{
    return m_diameter;
}

physx::PxGeometry *QSphereShape::getPhysXGeometry()
{
    if (!m_physXGeometry || m_scaleDirty) {
        updatePhysXGeometry();
    }
    return m_physXGeometry;
}

void QSphereShape::setDiameter(float diameter)
{
    if (qFuzzyCompare(m_diameter, diameter))
        return;

    m_diameter = diameter;
    updatePhysXGeometry();

    emit needsRebuild(this);
    emit diameterChanged(m_diameter);
}

void QSphereShape::updatePhysXGeometry()
{
    delete m_physXGeometry;
    auto s = sceneScale();
    m_physXGeometry = new physx::PxSphereGeometry(m_diameter * 0.5f * s.x());
    m_scaleDirty = false;
}

QT_END_NAMESPACE
