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

#ifndef CAPSULEGEOMETRY_H
#define CAPSULEGEOMETRY_H

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

#include <QQuick3DGeometry>

QT_BEGIN_NAMESPACE

class CapsuleGeometry : public QQuick3DGeometry
{
    Q_OBJECT
    QML_NAMED_ELEMENT(CapsuleGeometry)
    Q_PROPERTY(bool enableNormals READ enableNormals WRITE setEnableNormals NOTIFY
                       enableNormalsChanged)
    Q_PROPERTY(bool enableUV READ enableUV WRITE setEnableUV NOTIFY enableUVChanged)

    Q_PROPERTY(int longitudes READ longitudes WRITE setLongitudes NOTIFY longitudesChanged)
    Q_PROPERTY(int latitudes READ latitudes WRITE setLatitudes NOTIFY latitudesChanged)
    Q_PROPERTY(int rings READ rings WRITE setRings NOTIFY ringsChanged)
    Q_PROPERTY(float height READ height WRITE setHeight NOTIFY heightChanged)
    Q_PROPERTY(float diameter READ diameter WRITE setDiameter NOTIFY diameterChanged)

public:
    CapsuleGeometry();

    bool enableNormals() const { return m_enableNormals; }
    void setEnableNormals(bool enable);

    bool enableUV() const { return m_enableUV; }
    void setEnableUV(bool enable);

    int longitudes() const { return m_longitudes; }
    void setLongitudes(int longitudes);

    int latitudes() const { return m_latitudes; }
    void setLatitudes(int latitudes);

    int rings() const { return m_rings; }
    void setRings(int rings);

    float height() const { return m_height; }
    void setHeight(float height);

    float diameter() const { return m_diameter; }
    void setDiameter(float diameter);

signals:
    void enableNormalsChanged();
    void enableUVChanged();
    void longitudesChanged();
    void latitudesChanged();
    void ringsChanged();
    void heightChanged();
    void diameterChanged();

private:
    enum class UvProfile { Fixed, Aspect, Uniform };

    void updateData();

    bool m_enableNormals = true;
    bool m_enableUV = false;

    // Number of longitudes, or meridians, distributed by azimuth
    int m_longitudes = 32;
    // Number of latitudes, distributed by inclination. Must be even
    int m_latitudes = 16;
    // Number of sections in cylinder between hemispheres
    int m_rings = 1;
    // Height of the middle cylinder on the y axis, excluding the hemispheres
    float m_height = 100.f;
    // Diameter on the xz plane
    float m_diameter = 100.f;
    UvProfile m_uvProfile = UvProfile::Fixed;
};

QT_END_NAMESPACE

#endif
