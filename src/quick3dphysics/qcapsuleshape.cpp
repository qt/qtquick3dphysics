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

#include "qcapsuleshape_p.h"

#include <QtQuick3D/QQuick3DGeometry>
#include <geometry/PxCapsuleGeometry.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype CapsuleShape
    \inherits CollisionShape
    \inqmlmodule QtQuick3DPhysics
    \since 6.4
    \brief Capsule shape.

    This is the capsule shape. It is centered at the origin. It is specified by a diameter and a
    height value by which its axis extends along the positive and negative X-axis.

    \note When using a scale with this shape, the x component will be used to scale the height and
    the y component will be used to scale the diameter.
*/

/*!
    \qmlproperty float CapsuleShape::diameter
    This property defines the diameter of the capsule
*/

/*!
    \qmlproperty float CapsuleShape::height
    This property defines the height of the capsule
*/

QCapsuleShape::QCapsuleShape() = default;

QCapsuleShape::~QCapsuleShape()
{
    delete m_physXGeometry;
}

physx::PxGeometry *QCapsuleShape::getPhysXGeometry()
{
    if (!m_physXGeometry || m_scaleDirty) {
        updatePhysXGeometry();
    }

    return m_physXGeometry;
}

float QCapsuleShape::diameter() const
{
    return m_diameter;
}

void QCapsuleShape::setDiameter(float newDiameter)
{
    if (qFuzzyCompare(m_diameter, newDiameter))
        return;
    m_diameter = newDiameter;
    updatePhysXGeometry();

    emit needsRebuild(this);
    emit diameterChanged();
}

float QCapsuleShape::height() const
{
    return m_height;
}

void QCapsuleShape::setHeight(float newHeight)
{
    if (qFuzzyCompare(m_height, newHeight))
        return;
    m_height = newHeight;
    updatePhysXGeometry();

    emit needsRebuild(this);
    emit heightChanged();
}

void QCapsuleShape::updatePhysXGeometry()
{
    delete m_physXGeometry;
    QVector3D s = sceneScale();
    qreal rs = s.y();
    qreal hs = s.x();
    m_physXGeometry = new physx::PxCapsuleGeometry(rs * m_diameter * 0.5f, hs * m_height * 0.5f);
    m_scaleDirty = false;
}

QT_END_NAMESPACE
