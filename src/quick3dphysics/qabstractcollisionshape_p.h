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

#ifndef ABSTRACTCOLLISIONSHAPE_H
#define ABSTRACTCOLLISIONSHAPE_H

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
#include <QtQuick3D/private/qquick3dnode_p.h>
#include <QtQml/QQmlEngine>

namespace physx {
class PxGeometry;
}

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QAbstractCollisionShape : public QQuick3DNode
{
    Q_OBJECT
    Q_PROPERTY(bool enableDebugView READ enableDebugView WRITE setEnableDebugView NOTIFY
                       enableDebugViewChanged)
    QML_NAMED_ELEMENT(CollisionShape)
    QML_UNCREATABLE("abstract interface")
public:
    explicit QAbstractCollisionShape(QQuick3DNode *parent = nullptr);
    virtual ~QAbstractCollisionShape();

    virtual physx::PxGeometry *getPhysXGeometry() = 0;
    bool enableDebugView() const;

public slots:
    void setEnableDebugView(bool enableDebugView);

signals:
    void enableDebugViewChanged(bool enableDebugView);
    void needsRebuild(QObject *);

protected:
    bool m_scaleDirty = true;
    QVector3D m_prevScale;

private slots:
    void handleScaleChange();

private:
    bool m_enableDebugView = false;
};

QT_END_NAMESPACE

#endif // ABSTRACTCOLLISIONSHAPE_H
