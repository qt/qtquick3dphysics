// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qtriggerbody_p.h"
#include "physxnode/qphysxtriggerbody_p.h"

#include <QtCore/QPointer>

QT_BEGIN_NAMESPACE

/*!
    \qmltype TriggerBody
    \inherits PhysicsNode
    \inqmlmodule QtQuick3D.Physics
    \since 6.4
    \brief Reports when objects enter a given volume.

    This type defines a trigger body. A trigger body is a body that does not interact
    physically but is used to detect when objects intersect with its volume.
*/

/*!
    \qmlproperty int TriggerBody::collisionCount
    This property returns the number of bodies currently colliding with the trigger body.
*/

/*!
    \qmlsignal TriggerBody::bodyEntered(PhysicsNode *body)
    This signal is emitted when the trigger body is penetrated by the specified \a body.
*/

/*!
    \qmlsignal TriggerBody::bodyExited(PhysicsNode *body)
    This signal is emitted when the trigger body is no longer penetrated by the specified \a body.

    \note This signal is not emitted for a body that is deleted while it is still inside the
    trigger body, since there is no longer a body to report. \l collisionCount does count such a
    body out, so a list kept by hand from these signals has to be cleared of deleted bodies
    another way.
*/

QTriggerBody::QTriggerBody() = default;

void QTriggerBody::registerCollision(QAbstractPhysicsNode *collision)
{
    int size = m_collisions.size();
    m_collisions.insert(collision);

    if (size != m_collisions.size()) {
        // Nothing takes a body off this list when it is deleted while still
        // inside, so the count would keep reporting a body that no longer
        // exists, and the list would keep a pointer to it. Connected before the
        // report below, since a handler for that is free to delete the body it
        // is handed.
        connect(collision, &QObject::destroyed, this, &QTriggerBody::dropDestroyedBody,
                Qt::UniqueConnection);

        // The first runs handlers, which are free to delete this trigger.
        const QPointer<QTriggerBody> self(this);
        emit bodyEntered(collision);
        if (self.isNull())
            return;

        // Back to what it was is a handler having deleted the body it was just
        // handed, which counted it out and reported that itself.
        if (size != m_collisions.size())
            emit collisionCountChanged();
    }
}

void QTriggerBody::deregisterCollision(QAbstractPhysicsNode *collision)
{
    int size = m_collisions.size();
    m_collisions.remove(collision);

    if (size != m_collisions.size()) {
        disconnect(collision, &QObject::destroyed, this, &QTriggerBody::dropDestroyedBody);

        const QPointer<QTriggerBody> self(this);
        emit bodyExited(collision);
        if (self.isNull())
            return;

        // Back to what it was is a handler having put a body inside, which
        // counted it in and reported that itself.
        if (size != m_collisions.size())
            emit collisionCountChanged();
    }
}

void QTriggerBody::dropDestroyedBody(QObject *body)
{
    // Runs from ~QObject, when nothing is left of the body but its QObject part,
    // so it is matched by comparing pointers rather than by casting one back to
    // what it can no longer be. Nothing is reported for it either, in either
    // direction: bodyExited would pass a half destroyed body to a handler, and
    // there is no body left to tell that it has left anything.
    QAbstractPhysicsNode *destroyed = nullptr;
    for (QAbstractPhysicsNode *collision : std::as_const(m_collisions)) {
        if (static_cast<QObject *>(collision) == body) {
            destroyed = collision;
            break;
        }
    }

    if (!destroyed)
        return;

    m_collisions.remove(destroyed);
    emit collisionCountChanged();
}

int QTriggerBody::collisionCount() const
{
    return m_collisions.count();
}

QAbstractPhysXNode *QTriggerBody::createPhysXBackend()
{
    return new QPhysXTriggerBody(this);
}

QT_END_NAMESPACE
