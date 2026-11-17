// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef PHYSXGRAVITY_H
#define PHYSXGRAVITY_H

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

#include "qphysicsgravity_p.h"

QT_BEGIN_NAMESPACE

class QAbstractPhysicsNode;
class QAbstractPhysXNode;

// Applying a GravityField's gravity to one body. Called
// once per frame, before the bodies are synced and the next step is simulated.
namespace QPhysXGravity {

// Contributes what `gravity` says at the body's position to it. A dynamic body
// gets it as a force, so one that is asleep is woken only when `wake` says the
// gravity is new to it; a character controller adds it to its own gravity.
void apply(const QPhysicsGravity &gravity, QPhysicsGravity::Target target,
           QAbstractPhysicsNode *node, QAbstractPhysXNode *backend, bool wake);

// Wakes a dynamic body that a gravity has started acting on.
void wake(QAbstractPhysicsNode *node, QAbstractPhysXNode *backend);

} // namespace QPhysXGravity

QT_END_NAMESPACE

#endif
