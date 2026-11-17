// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef PHYSXGRAVITYFIELD_H
#define PHYSXGRAVITYFIELD_H

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

#include "physxnode/qphysxactorbody_p.h"
#include "qfilterdata_p.h"
#include "qphysicsgravity_p.h"

#include <QtCore/QPointer>

#include <optional>

QT_BEGIN_NAMESPACE

class QAbstractPhysicsNode;
class QGravityField;

class QPhysXGravityField : public QPhysXActorBody
{
public:
    QPhysXGravityField(QGravityField *frontEnd);
    void init(QPhysicsWorld *world, QPhysXWorld *physX) override;
    void sync(float deltaTime, QHash<QQuick3DNode *, QMatrix4x4> &transformCache) override;
    bool useTriggerFlag() override { return true; }
    DebugDrawBodyType getDebugDrawBodyType() override;

    // The gravity of a field without shapes, for the world to apply to the
    // bodies of the scene.
    struct SceneGravity
    {
        QPhysicsGravity gravity;
        QFilterData filterData;
        // Whether the bodies it acts on are to be woken.
        bool wake = false;
    };

    // Called by the world each frame, before the bodies are synced. Wakes the
    // bodies queued for it, and appends to `staleFilters` the filter of the
    // field as it acted on the whole scene, if it no longer does, so that the
    // world wakes what it let through. A field with shapes then applies its
    // gravity to the bodies inside them; one without returns its gravity.
    std::optional<SceneGravity> applyGravity(QList<QFilterData> &staleFilters);

    // Called as the field is destroyed: hands to its backend what the world
    // is to wake as the backend is deregistered, which is what the field last
    // acted on.
    static void fieldDestroyed(QGravityField *field);

    QList<QPointer<QAbstractPhysicsNode>> wakesOnRemoval;
    std::optional<QFilterData> staleFilterOnRemoval;

private:
    // What the field last acted on: the whole scene through this filter, or
    // the bodies inside its shapes.
    bool m_applied = false;
    bool m_sceneWide = false;
    QFilterData m_filterData;
};

QT_END_NAMESPACE

#endif // PHYSXGRAVITYFIELD_H
