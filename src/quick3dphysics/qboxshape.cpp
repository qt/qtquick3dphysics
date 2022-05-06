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

#include "qboxshape_p.h"

#include <QtQuick3D/QQuick3DGeometry>
#include <extensions/PxExtensionsAPI.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype BoxShape
    \inherits CollisionShape
    \inqmlmodule QtQuick3DPhysics
    \since 6.4
    \brief Box collision shape.

    This is the box collision shape.
*/

/*!
    \qmlproperty vector3d BoxShape::extents
    This property defines the xyz extents of the box
*/

QBoxShape::QBoxShape() = default;
QBoxShape::~QBoxShape()
{
    delete m_physXGeometry;
}

QVector3D QBoxShape::extents() const
{
    return m_extents;
}

physx::PxGeometry *QBoxShape::getPhysXGeometry()
{
    if (!m_physXGeometry || m_scaleDirty) {
        updatePhysXGeometry();
    }
    return m_physXGeometry;
}

void QBoxShape::setExtents(QVector3D extents)
{
    if (m_extents == extents)
        return;

    m_extents = extents;
    updatePhysXGeometry();

    emit needsRebuild(this);
    emit extentsChanged(m_extents);
}

void QBoxShape::updatePhysXGeometry()
{
    delete m_physXGeometry;
    const QVector3D half = m_extents * sceneScale() * 0.5f;
    m_physXGeometry = new physx::PxBoxGeometry(half.x(), half.y(), half.z());
    m_scaleDirty = false;
}

QT_END_NAMESPACE
