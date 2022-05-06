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

#include "qtrianglemeshshape_p.h"

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
    \qmltype TriangleMeshShape
    \inqmlmodule QtQuick3DPhysics
    \inherits CollisionShape
    \since 6.4
    \brief Triangle mesh shape.

    This is the triangle mesh shape.
*/

/*!
    \qmlproperty QUrl TriangleMeshShape::meshSource
    This property defines the location of the mesh file used to define the shape.
*/

QTriangleMeshShape::QTriangleMeshShape() = default;

QTriangleMeshShape::~QTriangleMeshShape()
{
    delete m_meshGeometry;
    if (m_mesh)
        QQuick3DPhysicsMeshManager::releaseMesh(m_mesh);
}

physx::PxGeometry *QTriangleMeshShape::getPhysXGeometry()
{
    if (m_dirtyPhysx || m_scaleDirty) {
        updatePhysXGeometry();
    }
    return m_meshGeometry;
}

void QTriangleMeshShape::updatePhysXGeometry()
{
    delete m_meshGeometry;
    m_meshGeometry = nullptr;

    if (!m_mesh)
        return;
    auto *triangleMesh = m_mesh->triangleMesh();
    if (!triangleMesh)
        return;

    auto meshScale = sceneScale();
    physx::PxMeshScale scale(physx::PxVec3(meshScale.x(), meshScale.y(), meshScale.z()),
                             physx::PxQuat(physx::PxIdentity));

    m_meshGeometry = new physx::PxTriangleMeshGeometry(triangleMesh, scale);
    m_dirtyPhysx = false;
}

const QUrl &QTriangleMeshShape::meshSource() const
{
    return m_meshSource;
}

void QTriangleMeshShape::setMeshSource(const QUrl &newMeshSource)
{
    if (m_meshSource == newMeshSource)
        return;
    m_meshSource = newMeshSource;
    m_mesh = QQuick3DPhysicsMeshManager::getMesh(m_meshSource, this);

    updatePhysXGeometry();

    emit needsRebuild(this);
    emit meshSourceChanged();
}

QT_END_NAMESPACE
