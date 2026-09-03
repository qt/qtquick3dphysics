// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef STATICPHYSXOBJECTS_H
#define STATICPHYSXOBJECTS_H

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

#include "qtconfigmacros.h"

#include <QtCore/qhash.h>

#include "extensions/PxDefaultAllocator.h"
#include "extensions/PxDefaultErrorCallback.h"

namespace physx {
class PxPvdTransport;
class PxPvd;
class PxFoundation;
class PxDefaultCpuDispatcher;
class PxCooking;
class PxMaterial;
}

QT_BEGIN_NAMESPACE

// The properties of a physics material. PhysX allows at most 64K materials, so instead of
// creating one per node, all nodes needing the same properties share a single PxMaterial. This
// means the materials must be treated as immutable: a node whose properties change is moved to
// the material with the new properties instead.
struct PhysicsMaterialProperties
{
    float staticFriction = 0.f;
    float dynamicFriction = 0.f;
    float restitution = 0.f;

    // Properties that no material can have, since friction and restitution are never negative.
    // Used by the nodes to tell that they have not picked up a material yet.
    static constexpr PhysicsMaterialProperties none() { return { -1.f, -1.f, -1.f }; }

    friend bool operator==(const PhysicsMaterialProperties &lhs,
                           const PhysicsMaterialProperties &rhs) noexcept
    {
        return lhs.staticFriction == rhs.staticFriction
                && lhs.dynamicFriction == rhs.dynamicFriction
                && lhs.restitution == rhs.restitution;
    }

    friend size_t qHash(const PhysicsMaterialProperties &properties, size_t seed = 0) noexcept
    {
        return qHashMulti(seed, properties.staticFriction, properties.dynamicFriction,
                          properties.restitution);
    }
};

struct SharedPhysicsMaterial
{
    physx::PxMaterial *material = nullptr;
    int nodeCount = 0;
};

struct StaticPhysXObjects
{
    physx::PxDefaultErrorCallback defaultErrorCallback;
    physx::PxDefaultAllocator defaultAllocatorCallback;
    physx::PxFoundation *foundation = nullptr;
    physx::PxPvd *pvd = nullptr;
    physx::PxPvdTransport *transport = nullptr;
    physx::PxPhysics *physics = nullptr;
    physx::PxDefaultCpuDispatcher *dispatcher = nullptr;
    physx::PxCooking *cooking = nullptr;

    // The materials in use, one per distinct set of properties, and how many nodes use each.
    // They belong to 'physics' and are destroyed together with it.
    QHash<PhysicsMaterialProperties, SharedPhysicsMaterial> materials;

    unsigned int foundationRefCount = 0;
    bool foundationCreated = false;
    bool physicsCreated = false;

    static StaticPhysXObjects &getReference();
};

QT_END_NAMESPACE

#endif
