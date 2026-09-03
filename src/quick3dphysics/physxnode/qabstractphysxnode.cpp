// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qabstractphysxnode_p.h"

#include "qabstractphysicsnode_p.h"
#include "qphysicsmaterial_p.h"
#include "qstaticphysxobjects_p.h"

#include "PxPhysics.h"
#include "PxMaterial.h"
#include "PxShape.h"

#define PHYSX_RELEASE(x)                                                                           \
    if (x != nullptr) {                                                                            \
        x->release();                                                                              \
        x = nullptr;                                                                               \
    }

QT_BEGIN_NAMESPACE

QAbstractPhysXNode::QAbstractPhysXNode(QAbstractPhysicsNode *node) : frontendNode(node)
{
    Q_ASSERT(node->m_backendObject == nullptr);
    node->m_backendObject = this;
}

QAbstractPhysXNode::~QAbstractPhysXNode() {
    if (!frontendNode) {
        Q_ASSERT(isRemoved);
        return;
    }

    Q_ASSERT(frontendNode->m_backendObject == this);
    frontendNode->m_backendObject = nullptr;
}

bool QAbstractPhysXNode::cleanupIfRemoved(QPhysXWorld *physX)
{
    if (isRemoved) {
        cleanup(physX);
        delete this;
        return true;
    }
    return false;
}

void QAbstractPhysXNode::updateDefaultDensity(float) { }

static PhysicsMaterialProperties propertiesFor(const QPhysicsMaterial *qtMaterial)
{
    if (!qtMaterial) {
        return { QPhysicsMaterial::defaultStaticFriction, QPhysicsMaterial::defaultDynamicFriction,
                 QPhysicsMaterial::defaultRestitution };
    }
    return { qtMaterial->staticFriction(), qtMaterial->dynamicFriction(),
             qtMaterial->restitution() };
}

QPhysicsMaterial *QAbstractPhysXNode::qtMaterial() const
{
    return nullptr;
}

bool QAbstractPhysXNode::updateMaterial()
{
    const PhysicsMaterialProperties properties = propertiesFor(qtMaterial());
    if (properties == materialProperties)
        return false;

    physx::PxMaterial *previousMaterial = material;
    releaseMaterial();
    materialProperties = properties;

    auto &s_physx = StaticPhysXObjects::getReference();
    SharedPhysicsMaterial &shared = s_physx.materials[properties];
    if (!shared.material) {
        shared.material = s_physx.physics->createMaterial(
                properties.staticFriction, properties.dynamicFriction, properties.restitution);
        if (!shared.material) {
            // PhysX allows at most 64K materials. Without a material the node gets no shapes,
            // so it will not collide with anything.
            qWarning() << "QtQuick3DPhysics: could not create physics material, the body will "
                          "not take part in collisions.";
            s_physx.materials.remove(properties);
            return material != previousMaterial;
        }
    }

    ++shared.nodeCount;
    material = shared.material;
    return material != previousMaterial;
}

void QAbstractPhysXNode::releaseMaterial()
{
    if (!material)
        return;

    auto &materials = StaticPhysXObjects::getReference().materials;
    const auto it = materials.find(materialProperties);
    if (it != materials.end() && it->material == material && --it->nodeCount == 0) {
        // Any shape still referencing the material keeps it alive until it is rebuilt
        it->material->release();
        materials.erase(it);
    }
    material = nullptr;
    materialProperties = PhysicsMaterialProperties::none();
}

void QAbstractPhysXNode::markDirtyShapes() { }

void QAbstractPhysXNode::rebuildDirtyShapes(QPhysicsWorld *, QPhysXWorld *) { }

void QAbstractPhysXNode::updateFilters() { }

void QAbstractPhysXNode::cleanup(QPhysXWorld *)
{
    for (auto *shape : std::as_const(shapes))
        PHYSX_RELEASE(shape);
    releaseMaterial();
    shapes.clear();
}

bool QAbstractPhysXNode::debugGeometryCapability()
{
    return false;
}

physx::PxTransform QAbstractPhysXNode::getGlobalPose()
{
    return {};
}

bool QAbstractPhysXNode::useTriggerFlag()
{
    return false;
}

DebugDrawBodyType QAbstractPhysXNode::getDebugDrawBodyType()
{
    return DebugDrawBodyType::Unknown;
}

bool QAbstractPhysXNode::shapesDirty() const
{
    return frontendNode && frontendNode->m_shapesDirty;
}

void QAbstractPhysXNode::setShapesDirty(bool dirty)
{
    frontendNode->m_shapesDirty = dirty;
}

bool QAbstractPhysXNode::filtersDirty() const
{
    return frontendNode && frontendNode->m_filtersDirty;
}

void QAbstractPhysXNode::setFiltersDirty(bool dirty)
{
    Q_ASSERT(frontendNode);
    frontendNode->m_filtersDirty = dirty;
}

QT_END_NAMESPACE
