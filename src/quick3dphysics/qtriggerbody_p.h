// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef TRIGGERBODY_H
#define TRIGGERBODY_H

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

class Q_QUICK3DPHYSICS_EXPORT QTriggerBody : public QAbstractPhysicsNode
{
    Q_OBJECT
    Q_PROPERTY(int collisionCount READ collisionCount NOTIFY collisionCountChanged)
    QML_NAMED_ELEMENT(TriggerBody)
public:
    QTriggerBody();

    // One shape of the trigger together with one shape of a body, which is what
    // the simulation reports an overlap for. The same shape listed twice on one
    // node builds two PhysX shapes that name the same pair, which is the same
    // answer: they are built from the same geometry at the same pose, so they
    // start and stop overlapping in the same step.
    using ShapePair = QPair<QAbstractCollisionShape *, QAbstractCollisionShape *>;

    void registerCollision(QAbstractPhysicsNode *collision, ShapePair shapes);
    void deregisterCollision(QAbstractPhysicsNode *collision, ShapePair shapes);
    void invalidateOverlaps(QAbstractPhysicsNode *node);
    void dropUnreportedOverlaps();

    int collisionCount() const;
    QAbstractPhysXNode *createPhysXBackend() final;

Q_SIGNALS:
    void bodyEntered(QAbstractPhysicsNode *body);
    void bodyExited(QAbstractPhysicsNode *body);
    void collisionCountChanged();

private:
    void dropDestroyedBody(QObject *body);

    // What is currently reported as overlapping for one body: the shape pairs it
    // is reported for, and those of them that are waiting to be reported again
    // because the shapes on one side of them have been replaced.
    struct Overlaps
    {
        QSet<ShapePair> pairs;
        QSet<ShapePair> unreported;
        // What the body asked for when it entered, so that the reports on the
        // way out are the ones that were made on the way in even if it changes
        // its mind while inside.
        bool sends = false;
        bool receives = false;
    };

    void reportEntered(QAbstractPhysicsNode *body, bool sends, bool receives);
    void reportExited(QAbstractPhysicsNode *body, bool sends, bool receives);

    // Keyed by body, so that one pair no longer overlapping does not report the
    // whole body as having left. The shapes in the pairs are only ever compared,
    // never dereferenced, since a shape can be gone before its pairs are.
    QHash<QAbstractPhysicsNode *, Overlaps> m_collisions;
    // How many of those asked to be counted and reported, kept as they come and
    // go rather than counted on demand: a body that only asked to be told
    // itself is held here too but is not one of these, and a trigger around a
    // whole scene has an entry per body in it while this is read from bindings
    // on every change.
    int m_reportedCount = 0;
};

QT_END_NAMESPACE

#endif // TRIGGERBODY_H
