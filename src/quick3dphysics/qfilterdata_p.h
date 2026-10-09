// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef QFILTERDATA_P_H
#define QFILTERDATA_P_H

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

#include <QtCore/qtypes.h>

QT_BEGIN_NAMESPACE

// The Qt side of physx::PxFilterData: what a node's filterGroup and
// filterIgnoreGroups say, and all that is ever written to the two words PhysX
// gives a shape to say it with. PhysX reads those words in
// contactReportFilterShader() as it decides what to pair; everything on this
// side that has to agree with that reads a QFilterData instead, and
// QPhysicsUtils converts between the two.
struct QFilterData
{
    quint32 group = 0;
    quint32 ignoreGroups = 0;
};

QT_END_NAMESPACE

#endif
