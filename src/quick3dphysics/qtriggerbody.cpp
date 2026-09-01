// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qtriggerbody_p.h"
#include "physxnode/qphysxtriggerbody_p.h"

#include <QtCore/QPointer>
#include <QtCore/QVarLengthArray>

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

void QTriggerBody::registerCollision(QAbstractPhysicsNode *collision, ShapePair shapes)
{
    // PhysX reports one pair per pair of shapes, so a body with several shapes
    // inside the trigger, or a trigger with several shapes around one body, is
    // reported once per pair. Keeping the pairs apart means that one of them no
    // longer overlapping does not report the whole body as having left, and that
    // the same pair reported again is the same overlap.
    const auto it = m_collisions.find(collision);
    if (it != m_collisions.end()) {
        // Another pair of a body already inside, or one of its pairs reported
        // again after a rebuild, which is what says it still overlaps. A body
        // stays followed for as long as it is inside, whatever it asks for in
        // the meantime, or the report it is owed on the way out never comes.
        it->pairs.insert(shapes);
        it->unreported.remove(shapes);
        return;
    }

    // What a body asks for is read once, as it enters, so that the reports on
    // the way out are the ones that were made on the way in. One that asks for
    // neither is followed all the same, or it would be asked again every time
    // its shapes are rebuilt and could be reported as entering without having
    // moved.
    const bool sends = collision->sendTriggerReports();
    const bool receives = collision->receiveTriggerReports();

    Overlaps &overlaps = m_collisions[collision];
    overlaps.pairs.insert(shapes);
    overlaps.sends = sends;
    overlaps.receives = receives;
    if (sends)
        ++m_reportedCount;

    // Nothing takes a body off this list when it is deleted while still inside,
    // so the count would keep reporting a body that no longer exists.
    connect(collision, &QObject::destroyed, this, &QTriggerBody::dropDestroyedBody,
            Qt::UniqueConnection);
    reportEntered(collision, sends, receives);
}

void QTriggerBody::deregisterCollision(QAbstractPhysicsNode *collision, ShapePair shapes)
{
    const auto it = m_collisions.find(collision);
    if (it == m_collisions.end())
        return;

    it->pairs.remove(shapes);
    it->unreported.remove(shapes);
    if (!it->pairs.isEmpty())
        return;

    const bool sends = it->sends;
    const bool receives = it->receives;
    if (sends)
        --m_reportedCount;
    m_collisions.erase(it);
    disconnect(collision, &QObject::destroyed, this, &QTriggerBody::dropDestroyedBody);
    reportExited(collision, sends, receives);
}

// The trigger holds every body that asked to hear about one of the two, since
// both are about a body being inside it, not about a pair of shapes overlapping

// Both take what to report by value and hold the body and this trigger weakly,
// since the first report can leave the rest with a body that is gone, a trigger
// that is gone, and an entry taken out from under a reference into the list.
// That is reachable from dropUnreportedOverlaps(), which runs from the frame and
// not from a callback holding the world's lock

void QTriggerBody::reportEntered(QAbstractPhysicsNode *body, bool sends, bool receives)
{
    const QPointer<QTriggerBody> self(this);
    const QPointer<QAbstractPhysicsNode> weakBody(body);

    if (sends) {
        emit bodyEntered(body);
        // Off the list again is a handler having deleted the body it was just
        // handed, which counted it out and reported that itself.
        if (!self.isNull() && m_collisions.contains(body))
            emit collisionCountChanged();
    }
    if (receives && !self.isNull() && !weakBody.isNull())
        emit body->enteredTriggerBody(this);
}

void QTriggerBody::reportExited(QAbstractPhysicsNode *body, bool sends, bool receives)
{
    const QPointer<QTriggerBody> self(this);
    const QPointer<QAbstractPhysicsNode> weakBody(body);

    if (sends) {
        emit bodyExited(body);
        if (!self.isNull())
            emit collisionCountChanged();
    }
    if (receives && !self.isNull() && !weakBody.isNull())
        emit body->exitedTriggerBody(this);
}

void QTriggerBody::invalidateOverlaps(QAbstractPhysicsNode *node)
{
    // Every shape of node has just been replaced by a new one. PhysX does report
    // the pairs of the shapes it took away, but as pairs of a shape that is
    // already gone, which cannot be told apart and is ignored. So the pairs of
    // those shapes are held on to until the next round of reports, which says
    // which of them the new shapes are in: overlapping shapes are reported as
    // found again, and what is not reported again is no longer overlapping.
    //
    // Holding on to them, rather than dropping them and letting the reports
    // build the list up again, is what keeps a body inside a trigger from being
    // reported as leaving and entering again every time its shapes are rebuilt,
    // which is once per frame if any of them is animated.
    if (node == this) {
        for (Overlaps &overlaps : m_collisions)
            overlaps.unreported = overlaps.pairs;
        return;
    }

    const auto it = m_collisions.find(node);
    if (it != m_collisions.end())
        it->unreported = it->pairs;
}

void QTriggerBody::dropUnreportedOverlaps()
{
    struct PendingExit
    {
        QPointer<QAbstractPhysicsNode> body;
        bool sends = false;
        bool receives = false;
    };
    QVarLengthArray<PendingExit, 4> pending;

    for (auto it = m_collisions.begin(); it != m_collisions.end();) {
        if (it->unreported.isEmpty()) {
            ++it;
            continue;
        }

        it->pairs.subtract(it->unreported);
        it->unreported.clear();

        if (it->pairs.isEmpty()) {
            QAbstractPhysicsNode *body = it.key();
            disconnect(body, &QObject::destroyed, this, &QTriggerBody::dropDestroyedBody);
            if (it->sends)
                --m_reportedCount;
            pending.append({ body, it->sends, it->receives });
            it = m_collisions.erase(it);
        } else {
            ++it;
        }
    }

    // Reported once the list is settled, since a handler is free to register or
    // deregister a collision on this trigger. A handler is also free to delete
    // one of the bodies still waiting to be reported, or this trigger: one that
    // no longer exists is not handed out, the same way a body destroyed while
    // inside the trigger is not, and a trigger that no longer exists reports
    // nothing further.
    //
    // Several bodies can go at once here, and all of them are out of the list
    // before any of them is reported, so collisionCount is what it will be for
    // the whole round rather than counting down through it.
    const QPointer<QTriggerBody> self(this);

    for (const PendingExit &exit : pending) {
        if (self.isNull())
            return;

        if (!exit.body.isNull())
            reportExited(exit.body.data(), exit.sends, exit.receives);
        else if (exit.sends)
            emit collisionCountChanged();
    }
}

void QTriggerBody::dropDestroyedBody(QObject *body)
{
    // Runs from ~QObject, so only the QObject part of the body is left: it is
    // compared as a QObject and never passed on. No bodyExited() or
    // exitedTriggerBody() either, since those would pass a half destroyed body
    // to a handler, or read from one.
    for (auto it = m_collisions.cbegin(); it != m_collisions.cend(); ++it) {
        if (static_cast<QObject *>(it.key()) == body) {
            const bool wasCounted = it->sends;
            if (wasCounted)
                --m_reportedCount;
            m_collisions.erase(it);
            if (wasCounted)
                emit collisionCountChanged();
            return;
        }
    }
}

int QTriggerBody::collisionCount() const
{
    return m_reportedCount;
}

QAbstractPhysXNode *QTriggerBody::createPhysXBackend()
{
    return new QPhysXTriggerBody(this);
}

QT_END_NAMESPACE
