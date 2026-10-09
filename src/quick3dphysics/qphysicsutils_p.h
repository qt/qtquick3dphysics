// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Qt-Security score:significant reason:default

#ifndef QPHYSICSUTILS_P_H
#define QPHYSICSUTILS_P_H

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

#include <QVector3D>
#include <QQuaternion>
#include <foundation/PxTransform.h>
#include <foundation/PxMat33.h>
#include <foundation/PxQuat.h>
#include <foundation/PxVec3.h>
#include <PxFiltering.h>

#include "qfilterdata_p.h"

namespace physx {
class PxRigidBody;
}

namespace QPhysicsUtils {

Q_ALWAYS_INLINE physx::PxVec3 toPhysXType(const QVector3D &qvec)
{
    return physx::PxVec3(qvec.x(), qvec.y(), qvec.z());
}

Q_ALWAYS_INLINE physx::PxQuat toPhysXType(const QQuaternion &qquat)
{
    return physx::PxQuat(qquat.x(), qquat.y(), qquat.z(), qquat.scalar());
}

Q_ALWAYS_INLINE physx::PxMat33 toPhysXType(const QMatrix3x3 &m)
{
    return physx::PxMat33(const_cast<float *>(m.constData()));
}

Q_ALWAYS_INLINE QVector3D toQtType(const physx::PxVec3 &vec)
{
    return QVector3D(vec.x, vec.y, vec.z);
}

Q_ALWAYS_INLINE QQuaternion toQtType(const physx::PxQuat &quat)
{
    return QQuaternion(quat.w, quat.x, quat.y, quat.z);
}

Q_ALWAYS_INLINE physx::PxTransform toPhysXTransform(const QVector3D &position,
                                                    const QQuaternion &rotation)
{
    return physx::PxTransform(QPhysicsUtils::toPhysXType(position),
                              QPhysicsUtils::toPhysXType(rotation));
}

Q_ALWAYS_INLINE bool fuzzyEquals(const physx::PxTransform &a, const physx::PxTransform &b)
{
    return qFuzzyCompare(a.p.x, b.p.x) && qFuzzyCompare(a.p.y, b.p.y) && qFuzzyCompare(a.p.z, b.p.z)
            && qFuzzyCompare(a.q.x, b.q.x) && qFuzzyCompare(a.q.y, b.q.y)
            && qFuzzyCompare(a.q.z, b.q.z) && qFuzzyCompare(a.q.w, b.q.w);
}

Q_ALWAYS_INLINE QFilterData toQtType(const physx::PxFilterData &data)
{
    QFilterData qtData;
    qtData.group = data.word0;
    qtData.ignoreGroups = data.word1;
    return qtData;
}

Q_ALWAYS_INLINE physx::PxFilterData toPhysXType(const QFilterData &data)
{
    physx::PxFilterData pxData;
    pxData.word0 = data.group;
    pxData.word1 = data.ignoreGroups;
    return pxData;
}

// Whether two nodes are filtered out from each other: either side naming the
// other's group among the ones it ignores is enough. PhysX asks this in
// contactReportFilterShader() as it decides what to pair, and a
// CharacterController, which moves through scene queries rather than pairs,
// asks it of what it sweeps against, so that the answer is the same either
// way.
Q_ALWAYS_INLINE bool isFilteredOut(const QFilterData &a, const QFilterData &b)
{
    const auto isBitSet = [](quint32 value, quint32 position) {
        Q_ASSERT(position < 32);
        return (value & (1u << position)) != 0u;
    };

    return a.group < 32 && b.group < 32
            && (isBitSet(a.ignoreGroups, b.group) || isBitSet(b.ignoreGroups, a.group));
}

Q_ALWAYS_INLINE bool isFinite(const QVector3D &v)
{
    return qIsFinite(v.x()) && qIsFinite(v.y()) && qIsFinite(v.z());
}

Q_ALWAYS_INLINE bool isFinite(const QQuaternion &q)
{
    return qIsFinite(q.x()) && qIsFinite(q.y()) && qIsFinite(q.z()) && qIsFinite(q.scalar());
}

Q_ALWAYS_INLINE bool isFinite(const physx::PxVec3 &v)
{
    return qIsFinite(v.x) && qIsFinite(v.y) && qIsFinite(v.z);
}

inline const QQuaternion kMinus90YawRotation = QQuaternion::fromEulerAngles(0, -90, 0);
}

#endif // QPHYSICSUTILS_P_H
