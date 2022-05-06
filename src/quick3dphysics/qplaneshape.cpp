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

#include "qplaneshape_p.h"

#include <QtQuick3D/QQuick3DGeometry>
#include <extensions/PxExtensionsAPI.h>

#include "qphysicsmeshutils_p_p.h"

//########################################################################################
// NOTE:
// Triangle mesh, heightfield or plane geometry shapes configured as eSIMULATION_SHAPE are
// not supported for non-kinematic PxRigidDynamic instances.
//########################################################################################

#include "qdynamicsworld_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmltype PlaneShape
    \inqmlmodule QtQuick3DPhysics
    \inherits CollisionShape
    \since 6.4
    \brief Plane shape.

    This is the plane shape. Planes divide space into "above" and "below" them. Everything "below"
    the plane will collide with it and be pushed above it. The Plane lies on the XY plane with
    "above" pointing towards positive Z.
*/

QPlaneShape::QPlaneShape() = default;

QPlaneShape::~QPlaneShape()
{
    delete m_planeGeometry;
}

physx::PxGeometry *QPlaneShape::getPhysXGeometry()
{
    if (!m_planeGeometry) {
        updatePhysXGeometry();
    }
    return m_planeGeometry;
}

void QPlaneShape::updatePhysXGeometry()
{
    delete m_planeGeometry;
    // TODO: we need only one plane geometry, and it should live in the backend
    m_planeGeometry = new physx::PxPlaneGeometry();
}

QT_END_NAMESPACE
