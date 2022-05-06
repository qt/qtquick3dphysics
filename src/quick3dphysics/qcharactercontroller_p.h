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

#ifndef CHARACTERCONTROLLER_H
#define CHARACTERCONTROLLER_H

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
#include <QtQuick3DPhysics/private/qabstractphysicsbody_p.h>
#include <QtQml/QQmlEngine>
#include <QVector3D>

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QCharacterController : public QAbstractPhysicsBody
{
    Q_OBJECT
    Q_PROPERTY(QVector3D speed READ speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(QVector3D gravity READ gravity WRITE setGravity NOTIFY gravityChanged)
    Q_PROPERTY(bool midAirControl READ midAirControl WRITE setMidAirControl NOTIFY
                       midAirControlChanged)
    Q_PROPERTY(Collisions collisions READ collisions NOTIFY collisionsChanged)
    QML_NAMED_ELEMENT(CharacterController)
public:
    QCharacterController();

    enum class Collision {
        None = 0,
        Side = 1 << 0,
        Up = 1 << 1,
        Down = 1 << 2,
    };
    Q_DECLARE_FLAGS(Collisions, Collision)
    Q_FLAG(Collisions)

    const QVector3D &speed() const;
    void setSpeed(const QVector3D &newSpeed);
    const QVector3D &gravity() const;
    void setGravity(const QVector3D &newGravity);
    QVector3D getMovement(float deltaTime);
    bool getTeleport(QVector3D &position);

    bool midAirControl() const;
    void setMidAirControl(bool newMidAirControl);

    Q_INVOKABLE void teleport(const QVector3D &position);

    const Collisions &collisions() const;
    void setCollisions(const Collisions &newCollisions);

signals:
    void speedChanged();
    void gravityChanged();

    void midAirControlChanged();

    void impulseChanged();

    void collisionsChanged();

private:
    QVector3D m_speed;
    QVector3D m_gravity;
    bool m_midAirControl = true;

    QVector3D m_freeFallVelocity; // actual speed at start of next tick, if free fall

    QVector3D m_teleportPosition;
    bool m_teleport = false;
    Collisions m_collisions;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(QCharacterController::Collisions)

QT_END_NAMESPACE

#endif // CHARACTERCONTROLLER_H
