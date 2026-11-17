// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qtriggerbody_p.h"
#include "physxnode/qphysxtriggerbody_p.h"

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

    A body counts once, however many of its collision shapes are inside the trigger body.

    Only a body that had \l {PhysicsNode::sendTriggerReports}{sendTriggerReports} set when it
    entered is counted, and it goes on counting for as long as it is inside, whatever it sets
    that property to in the meantime.
*/

/*!
    \qmlsignal TriggerBody::bodyEntered(PhysicsNode *body)
    This signal is emitted when the trigger body is penetrated by the specified \a body.

    Emitted once per body, however many of its collision shapes penetrate the trigger body.
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

void QTriggerBody::bodyDidEnter(QAbstractPhysicsNode *body)
{
    emit bodyEntered(body);
}

void QTriggerBody::bodyDidExit(QAbstractPhysicsNode *body)
{
    emit bodyExited(body);
}

bool QTriggerBody::reportsToBodies() const
{
    return true;
}

QAbstractPhysXNode *QTriggerBody::createPhysXBackend()
{
    return new QPhysXTriggerBody(this);
}

QT_END_NAMESPACE
