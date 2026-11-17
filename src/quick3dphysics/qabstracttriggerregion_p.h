// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef ABSTRACTTRIGGERREGION_H
#define ABSTRACTTRIGGERREGION_H

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
#include "qabstractphysicsnode_p.h"
#include <QtCore/QHash>
#include <QtCore/QSet>
#include <QtQml/QQmlEngine>

QT_BEGIN_NAMESPACE

// What a node whose shapes are PhysX triggers keeps track of: the bodies
// overlapping it. TriggerBody reports them; a region could equally act on them.
class Q_QUICK3DPHYSICS_EXPORT QAbstractTriggerRegion : public QAbstractPhysicsNode
{
    Q_OBJECT
    QML_ANONYMOUS
public:
    QAbstractTriggerRegion();

    // One shape of the region together with one shape of a body, which is what
    // the simulation reports an overlap for. The same shape listed twice on one
    // node builds two PhysX shapes that name the same pair, which is the same
    // answer: they are built from the same geometry at the same pose, so they
    // start and stop overlapping in the same step.
    using ShapePair = QPair<QAbstractCollisionShape *, QAbstractCollisionShape *>;

    void registerCollision(QAbstractPhysicsNode *collision, ShapePair shapes);
    void deregisterCollision(QAbstractPhysicsNode *collision, ShapePair shapes);
    void invalidateOverlaps(QAbstractPhysicsNode *node);
    void dropUnreportedOverlaps();

    // Whether `body` is counted by collisionCount and passed to bodyDidEnter()
    // and bodyDidExit(). By default, whether it asked for that with
    // PhysicsNode::sendTriggerReports.
    virtual bool countsBody(const QAbstractPhysicsNode *body) const;

    // Whether bodies that set PhysicsNode::receiveTriggerReports are told about
    // this region through PhysicsNode::enteredTriggerBody and exitedTriggerBody.
    // Those signals name a TriggerBody, so by default they are not.
    virtual bool reportsToBodies() const;

    // The number of bodies inside the region that countsBody() accepted.
    int collisionCount() const;

Q_SIGNALS:
    void collisionCountChanged();

protected:
    // Called when a node actually enters or leaves, i.e. not for repeated
    // reports about a node that is already tracked.
    virtual void bodyDidEnter(QAbstractPhysicsNode *body);
    virtual void bodyDidExit(QAbstractPhysicsNode *body);

    // What is currently reported as overlapping for one body: the shape pairs it
    // is reported for, and those of them that are waiting to be reported again
    // because the shapes on one side of them have been replaced.
    struct Overlaps
    {
        QSet<ShapePair> pairs;
        QSet<ShapePair> unreported;
        // countsBody() and what the body asked for, as of when it entered, so
        // that the reports on the way out are the ones made on the way in.
        bool reports = false;
        bool receives = false;
    };

    // Every body overlapping the region, counted or not. The shapes in the
    // pairs are only ever compared, never dereferenced, since a shape can be
    // gone before its pairs are.
    const QHash<QAbstractPhysicsNode *, Overlaps> &collisions() const { return m_collisions; }

private:
    void dropDestroyedBody(QObject *body);
    void reportEntered(QAbstractPhysicsNode *body, bool reports, bool receives);
    void reportExited(QAbstractPhysicsNode *body, bool reports, bool receives);

    QHash<QAbstractPhysicsNode *, Overlaps> m_collisions;
    // How many of those are counted, kept as they come and go rather than
    // counted on every read.
    int m_reportedCount = 0;
};

QT_END_NAMESPACE

#endif // ABSTRACTTRIGGERREGION_H
