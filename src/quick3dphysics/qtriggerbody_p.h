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
#include "qabstracttriggerregion_p.h"
#include <QtQml/QQmlEngine>

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QTriggerBody : public QAbstractTriggerRegion
{
    Q_OBJECT
    Q_PROPERTY(int collisionCount READ collisionCount NOTIFY collisionCountChanged)
    QML_NAMED_ELEMENT(TriggerBody)
public:
    QTriggerBody();

    QAbstractPhysXNode *createPhysXBackend() final;

Q_SIGNALS:
    void bodyEntered(QAbstractPhysicsNode *body);
    void bodyExited(QAbstractPhysicsNode *body);

protected:
    void bodyDidEnter(QAbstractPhysicsNode *body) override;
    void bodyDidExit(QAbstractPhysicsNode *body) override;
    // A trigger body is what PhysicsNode::enteredTriggerBody and exitedTriggerBody report.
    bool reportsToBodies() const override;
};

QT_END_NAMESPACE

#endif // TRIGGERBODY_H
