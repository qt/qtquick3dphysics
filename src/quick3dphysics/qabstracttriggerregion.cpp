// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qabstracttriggerregion_p.h"

#include <QtCore/QPointer>
#include <QtCore/QVarLengthArray>

QT_BEGIN_NAMESPACE

QAbstractTriggerRegion::QAbstractTriggerRegion() = default;

void QAbstractTriggerRegion::registerCollision(QAbstractPhysicsNode *collision, ShapePair shapes)
{
    // PhysX reports one pair per pair of shapes, so a body with several shapes
    // inside the region, or a region with several shapes around one body, is
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
    const bool reports = countsBody(collision);
    const bool receives = reportsToBodies() && collision->receiveTriggerReports();

    Overlaps &overlaps = m_collisions[collision];
    overlaps.pairs.insert(shapes);
    overlaps.reports = reports;
    overlaps.receives = receives;
    if (reports)
        ++m_reportedCount;

    // Nothing takes a body off this list when it is deleted while still inside,
    // and a field dereferences what is on it every frame.
    connect(collision, &QObject::destroyed, this, &QAbstractTriggerRegion::dropDestroyedBody,
            Qt::UniqueConnection);
    reportEntered(collision, reports, receives);
}

void QAbstractTriggerRegion::deregisterCollision(QAbstractPhysicsNode *collision, ShapePair shapes)
{
    const auto it = m_collisions.find(collision);
    if (it == m_collisions.end())
        return;

    it->pairs.remove(shapes);
    it->unreported.remove(shapes);
    if (!it->pairs.isEmpty())
        return;

    const bool reports = it->reports;
    const bool receives = it->receives;
    if (reports)
        --m_reportedCount;
    m_collisions.erase(it);
    disconnect(collision, &QObject::destroyed, this, &QAbstractTriggerRegion::dropDestroyedBody);
    reportExited(collision, reports, receives);
}

// Both take what to report by value and hold the body and this region weakly,
// since the first report can leave the rest with a body that is gone, a region
// that is gone, and an entry taken out from under a reference into the list.
// That is reachable from dropUnreportedOverlaps(), which runs from the frame and
// not from a callback holding the world's lock

void QAbstractTriggerRegion::reportEntered(QAbstractPhysicsNode *body, bool reports, bool receives)
{
    const QPointer<QAbstractTriggerRegion> self(this);
    const QPointer<QAbstractPhysicsNode> weakBody(body);

    if (reports) {
        bodyDidEnter(body);
        // Off the list again is a handler having deleted the body it was just
        // handed, which counted it out and reported that itself.
        if (!self.isNull() && m_collisions.contains(body))
            emit collisionCountChanged();
    }
    if (receives && !self.isNull() && !weakBody.isNull())
        emit body->enteredTriggerBody(this);
}

void QAbstractTriggerRegion::reportExited(QAbstractPhysicsNode *body, bool reports, bool receives)
{
    const QPointer<QAbstractTriggerRegion> self(this);
    const QPointer<QAbstractPhysicsNode> weakBody(body);

    if (reports) {
        bodyDidExit(body);
        if (!self.isNull())
            emit collisionCountChanged();
    }
    if (receives && !self.isNull() && !weakBody.isNull())
        emit body->exitedTriggerBody(this);
}

void QAbstractTriggerRegion::invalidateOverlaps(QAbstractPhysicsNode *node)
{
    // Every shape of node has just been replaced by a new one. PhysX does report
    // the pairs of the shapes it took away, but as pairs of a shape that is
    // already gone, which cannot be told apart and is ignored. So the pairs of
    // those shapes are held on to until the next round of reports, which says
    // which of them the new shapes are in: overlapping shapes are reported as
    // found again, and what is not reported again is no longer overlapping.
    //
    // Holding on to them, rather than dropping them and letting the reports
    // build the list up again, is what keeps a body inside a region from being
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

void QAbstractTriggerRegion::dropUnreportedOverlaps()
{
    struct PendingExit
    {
        QPointer<QAbstractPhysicsNode> body;
        bool reports = false;
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
            disconnect(body, &QObject::destroyed, this, &QAbstractTriggerRegion::dropDestroyedBody);
            if (it->reports)
                --m_reportedCount;
            pending.append({ body, it->reports, it->receives });
            it = m_collisions.erase(it);
        } else {
            ++it;
        }
    }

    // Reported once the list is settled, since a handler is free to register or
    // deregister a collision on this region. A handler is also free to delete
    // one of the bodies still waiting to be reported, or this region: one that
    // no longer exists is not passed to a handler, the same way a body
    // destroyed while inside the region is not, and a region that no longer
    // exists reports nothing further.
    //
    // Several bodies can leave at once here, and all of them are out of the
    // list before any of them is reported, so collisionCount is what it will
    // be for the whole round rather than counting down through it.
    const QPointer<QAbstractTriggerRegion> self(this);

    for (const PendingExit &exit : pending) {
        if (self.isNull())
            return;

        if (!exit.body.isNull())
            reportExited(exit.body.data(), exit.reports, exit.receives);
        else if (exit.reports)
            emit collisionCountChanged();
    }
}

void QAbstractTriggerRegion::dropDestroyedBody(QObject *body)
{
    // Runs from ~QObject, so only the QObject part of the body is left: it is
    // compared as a QObject and never passed on. No bodyDidExit() or
    // exitedTriggerBody() either, since those would pass a half destroyed body
    // to a handler, or read from one.
    for (auto it = m_collisions.cbegin(); it != m_collisions.cend(); ++it) {
        if (static_cast<QObject *>(it.key()) == body) {
            const bool wasCounted = it->reports;
            if (wasCounted)
                --m_reportedCount;
            m_collisions.erase(it);
            if (wasCounted)
                emit collisionCountChanged();
            return;
        }
    }
}

bool QAbstractTriggerRegion::countsBody(const QAbstractPhysicsNode *body) const
{
    return body->sendTriggerReports();
}

bool QAbstractTriggerRegion::reportsToBodies() const
{
    return false;
}

int QAbstractTriggerRegion::collisionCount() const
{
    return m_reportedCount;
}

void QAbstractTriggerRegion::bodyDidEnter(QAbstractPhysicsNode *) { }

void QAbstractTriggerRegion::bodyDidExit(QAbstractPhysicsNode *) { }

QT_END_NAMESPACE
