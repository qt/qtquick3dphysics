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

#ifndef HEIGHTFIELDMESHSHAPE_H
#define HEIGHTFIELDMESHSHAPE_H

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
#include <QtQuick3DPhysics/private/qabstractcollisionshape_p.h>
#include <QtCore/QObject>
#include <QtGui/QVector3D>
#include <QtQml/QQmlEngine>
#include <QtQuick3D/QQuick3DGeometry>

namespace physx {
class PxBoxGeometry;
class PxTriangleMesh;
class PxTriangleMeshGeometry;
class PxHeightFieldGeometry;
class PxHeightField;
struct PxHeightFieldSample;
}

QT_BEGIN_NAMESPACE

class QQuick3DPhysicsHeightField;

class Q_QUICK3DPHYSICS_EXPORT QHeightFieldShape : public QAbstractCollisionShape
{
    Q_OBJECT
    Q_PROPERTY(QVector3D extents READ extents WRITE setExtents NOTIFY extentsChanged)
    Q_PROPERTY(QUrl heightMap READ heightMap WRITE setHeightMap NOTIFY heightMapChanged)
    QML_NAMED_ELEMENT(HeightFieldShape)
public:
    QHeightFieldShape();
    ~QHeightFieldShape();

    physx::PxGeometry *getPhysXGeometry() override;

    const QUrl &heightMap() const;
    void setHeightMap(const QUrl &newHeightMap);

    const QVector3D &hfOffset() const { return m_hfOffset; }

    const QVector3D &extents() const;
    void setExtents(const QVector3D &newExtents);
    bool isStaticShape() const override { return true; }

signals:
    void heightMapChanged();
    void extentsChanged();

private:
    void updatePhysXGeometry();
    void getSamples();
    void updateExtents();

    QQuick3DPhysicsHeightField *m_heightField = nullptr;

    physx::PxHeightFieldGeometry *m_heightFieldGeometry = nullptr;
    QVector3D m_hfOffset;
    QUrl m_heightMapSource;
    bool m_dirtyPhysx = false;
    QVector3D m_extents = { 100, 100, 100 };
    bool m_extentsSetExplicitly = false;
};

QT_END_NAMESPACE

#endif // HEIGHTFIELDMESHSHAPE_H
