// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qtrianglemeshshape_p.h"

#include <QtQuick3D/QQuick3DGeometry>
#include <extensions/PxExtensionsAPI.h>

#include "qphysicsmeshutils_p_p.h"

//########################################################################################
// NOTE:
// Triangle mesh, heightfield or plane geometry shapes configured as eSIMULATION_SHAPE are
// not supported for non-kinematic PxRigidDynamic instances.
//########################################################################################

QT_BEGIN_NAMESPACE

/*!
    \qmltype TriangleMeshShape
    \inqmlmodule QtQuick3D.Physics
    \inherits CollisionShape
    \since 6.4
    \brief A collision shape based on a 3D mesh.

    This type defines a shape based on the same 3D mesh file format used by
    \l [QtQuick3D]{Model::source}{QtQuick3D.Model}.

    Objects that are controlled by the physics simulation cannot use TriangleMeshShape: It can only
    be used with \l StaticRigidBody and \l {DynamicRigidBody::isKinematic}{kinematic bodies}. Use \l
    ConvexMeshShape for non-kinematic dynamic bodies.

    \sa {Qt Quick 3D Physics Shapes and Bodies}{Shapes and Bodies overview documentation}
*/

/*!
    \qmlproperty url TriangleMeshShape::source
    This property defines the location of the mesh file used to define the shape.

    Internally, TriangleMeshShape converts the mesh to an optimized data structure. This conversion
    can be done in advance. See the \l{Qt Quick 3D Physics Cooking}{cooking overview documentation}
    for details.
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

const QUrl &QTriangleMeshShape::source() const
{
    return m_meshSource;
}

void QTriangleMeshShape::setSource(const QUrl &newSource)
{
    if (m_meshSource == newSource)
        return;
    m_meshSource = newSource;
    m_mesh = QQuick3DPhysicsMeshManager::getMesh(m_meshSource, this);

    updatePhysXGeometry();

    emit needsRebuild(this);
    emit sourceChanged();
}

QT_END_NAMESPACE
