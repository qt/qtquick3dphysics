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

#ifndef CONVEXMESHSHAPE_H
#define CONVEXMESHSHAPE_H

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

namespace physx {
class PxBoxGeometry;
class PxConvexMesh;
class PxConvexMeshGeometry;
}

QT_BEGIN_NAMESPACE
class QQuick3DPhysicsMesh;

class Q_QUICK3DPHYSICS_EXPORT QConvexMeshShape : public QAbstractCollisionShape
{
    Q_OBJECT
    Q_PROPERTY(QUrl meshSource READ meshSource WRITE setMeshSource NOTIFY meshSourceChanged)
    QML_NAMED_ELEMENT(ConvexMeshShape)
public:
    QConvexMeshShape();
    ~QConvexMeshShape();

    physx::PxGeometry *getPhysXGeometry() override;

    const QUrl &meshSource() const;
    void setMeshSource(const QUrl &newMeshSource);

signals:
    void meshSourceChanged();

private:
    void updatePhysXGeometry();

    bool m_dirtyPhysx = false;
    physx::PxConvexMeshGeometry *m_meshGeometry = nullptr;
    QUrl m_meshSource;
    QQuick3DPhysicsMesh *m_mesh = nullptr;
};

QT_END_NAMESPACE

#endif // CONVEXMESHSHAPE_H
