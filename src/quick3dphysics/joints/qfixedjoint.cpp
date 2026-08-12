// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qfixedjoint_p.h"

#include "physxnode/qphysxactorbody_p.h"
#include "qabstractphysicsnode_p.h"
#include "qstaticphysxobjects_p.h"

#include <extensions/PxFixedJoint.h>

QT_BEGIN_NAMESPACE

/*!
    \qmltype FixedJoint
    \inqmlmodule QtQuick3D.Physics
    \since 6.12
    \brief A fixed joint.

    A fixed joint that will keep the orientation of the bodies fixed.

    \sa {DistanceJoint}
    \sa {PrismaticJoint}
    \sa {RevoluteJoint}
    \sa {SphericalJoint}
    \sa {D6Joint}
*/

physx::PxJoint *QFixedJoint::createPhysxJoint(physx::PxRigidActor *actorA,
                                              physx::PxRigidActor *actorB,
                                              const physx::PxTransform &trfA,
                                              const physx::PxTransform &trfB)
{
    return physx::PxFixedJointCreate(*StaticPhysXObjects::getReference().physics, actorA, trfA,
                                     actorB, trfB);
}

void QFixedJoint::setJointProperties()
{
    return;
}

QT_END_NAMESPACE
