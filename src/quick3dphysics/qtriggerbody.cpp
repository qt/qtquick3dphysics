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

#include "qtriggerbody_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmltype TriggerBody
    \inherits CollisionNode
    \inqmlmodule QtQuick3DPhysics
    \since 6.4
    \brief Base type for a trigger body.

    This is the base type for a trigger body. A trigger body is a body that does not interact
    physically but is used to detect when objects intersect.
*/

/*!
    \qmlproperty int TriggerBody::collisionCount
    This property returns the number of bodies currently colliding with the trigger body.
*/

/*!
    \qmlsignal TriggerBody::bodyEntered(CollisionNode *body)
    This signal is emitted when the trigger body is penetrated by the specified \a body.
*/

/*!
    \qmlsignal TriggerBody::bodyExited(CollisionNode *body)
    This signal is emitted when the trigger body is no longer penetrated by the specified \a body.
*/

QTriggerBody::QTriggerBody() = default;

void QTriggerBody::registerCollision(QAbstractCollisionNode *collision)
{
    int size = m_collisions.size();
    m_collisions.insert(collision);

    if (size != m_collisions.size()) {
        emit bodyEntered(collision);
        emit collisionCountChanged();
    }
}

void QTriggerBody::deregisterCollision(QAbstractCollisionNode *collision)
{
    int size = m_collisions.size();
    m_collisions.remove(collision);

    if (size != m_collisions.size()) {
        emit bodyExited(collision);
        emit collisionCountChanged();
    }
}

int QTriggerBody::collisionCount() const
{
    return m_collisions.count();
}

QT_END_NAMESPACE
