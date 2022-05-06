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

#ifndef CAPSULESHAPE_H
#define CAPSULESHAPE_H

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
#include <QtQml/QQmlEngine>

namespace physx {
class PxCapsuleGeometry;
}

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QCapsuleShape : public QAbstractCollisionShape
{
    Q_OBJECT
    QML_NAMED_ELEMENT(CapsuleShape)
    Q_PROPERTY(float diameter READ diameter WRITE setDiameter NOTIFY diameterChanged)
    Q_PROPERTY(float height READ height WRITE setHeight NOTIFY heightChanged)
public:
    QCapsuleShape();
    ~QCapsuleShape();

    float diameter() const;
    void setDiameter(float newDiameter);

    float height() const;
    void setHeight(float newHeight);

    physx::PxGeometry *getPhysXGeometry() override;

Q_SIGNALS:
    void diameterChanged();
    void heightChanged();

private:
    void updatePhysXGeometry();
    physx::PxCapsuleGeometry *m_physXGeometry = nullptr;
    float m_diameter = 100.0f;
    float m_height = 100.0f;
};

QT_END_NAMESPACE

#endif // CAPSULESHAPE_H
