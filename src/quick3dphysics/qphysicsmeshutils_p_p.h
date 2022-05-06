/****************************************************************************
**
** Copyright (C) 2022 The Qt Company Ltd.
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

#ifndef QPHYSICSMESHUTILS_P_P_H
#define QPHYSICSMESHUTILS_P_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtQuick3DPhysics/qtquick3dphysicsglobal.h>
#include <QtGui/QVector3D>
#include <QtQuick3DUtils/private/qssgmesh_p.h>

namespace physx {
class PxBoxGeometry;
class PxConvexMesh;
class PxConvexMeshGeometry;
class PxTriangleMesh;
}

QT_BEGIN_NAMESPACE

class QQuick3DGeometry;

class QQuick3DPhysicsMesh
{
public:
    QQuick3DPhysicsMesh(const QString &qmlSource) : m_meshPath(qmlSource) { }
    ~QQuick3DPhysicsMesh() { }

    QList<QVector3D> positions();

    QPair<QVector3D, QVector3D> bounds()
    {
        loadSsgMesh();
        if (m_ssgMesh.isValid()) {
            auto b = m_ssgMesh.subsets().first().bounds;
            return { b.min, b.max };
        }
        return {};
    }

    void ref() { ++refCount; }
    int deref() { return --refCount; }

    physx::PxConvexMesh *convexMesh();
    physx::PxTriangleMesh *triangleMesh();

    enum MeshType { Convex, Triangle };

private:
    void loadSsgMesh();

    QString m_meshPath;
    QSSGMesh::Mesh m_ssgMesh;
    int m_posOffset = 0;

    physx::PxConvexMesh *m_convexMesh = nullptr;
    physx::PxTriangleMesh *m_triangleMesh = nullptr;
    int refCount = 0;
};

class QQuick3DPhysicsMeshManager
{
public:
    static QQuick3DPhysicsMesh *getMesh(const QUrl &source, const QObject *contextObject);
    static void releaseMesh(QQuick3DPhysicsMesh *mesh);

private:
    static QHash<QString, QQuick3DPhysicsMesh *> meshHash;
};

QT_END_NAMESPACE

#endif // QPHYSICSMESHUTILS_P_P_H
