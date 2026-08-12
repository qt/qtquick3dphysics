// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only


#ifndef PHYSICSFLEXIBLEJOINT_H
#define PHYSICSFLEXIBLEJOINT_H

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

#include "joints/qjoint_p.h"

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QFlexibleJoint: public QPhysicsJoint
{
    Q_OBJECT

    Q_PROPERTY(float stiffness READ stiffness WRITE setStiffness NOTIFY stiffnessChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float damping READ damping WRITE setDamping NOTIFY dampingChanged
                       FINAL REVISION(6, 13))

    QML_NAMED_ELEMENT(FlexibleJoint)
    QML_UNCREATABLE("abstract interface")

public:
    Q_REVISION(6, 13) float stiffness() const;
    Q_REVISION(6, 13) void setStiffness(float stiffness);

    Q_REVISION(6, 13) float damping() const;
    Q_REVISION(6, 13) void setDamping(float damping);

signals:
    Q_REVISION(6, 13) void stiffnessChanged();
    Q_REVISION(6, 13) void dampingChanged();

protected:

    float m_stiffness = 0.0f;
    float m_damping = 0.0f;
};

QT_END_NAMESPACE

#endif // PHYSICSFLEXIBLEJOINT_H
