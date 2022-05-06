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

#include "qabstractphysicsbody_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmltype PhysicsBody
    \inherits CollisionNode
    \inqmlmodule QtQuick3DPhysics
    \since 6.4
    \brief Base type for physics bodies.

    This is the base type for all physics bodies.
*/

/*!
    \qmlproperty PhysicsMaterial PhysicsBody::physicsMaterial
    This property defines the physical material of the body
*/

QAbstractPhysicsBody::QAbstractPhysicsBody()
{
    m_physicsMaterial = new QPhysicsMaterial(this);
}

QPhysicsMaterial *QAbstractPhysicsBody::physicsMaterial() const
{
    return m_physicsMaterial;
}

void QAbstractPhysicsBody::setPhysicsMaterial(QPhysicsMaterial *newPhysicsMaterial)
{
    if (m_physicsMaterial == newPhysicsMaterial)
        return;
    m_physicsMaterial = newPhysicsMaterial;
    emit physicsMaterialChanged();
}

QT_END_NAMESPACE
