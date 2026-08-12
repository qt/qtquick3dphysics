// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

//! [full]
Node {
    id: root

    property real stiffness : 15000
    property real damping : 500

    SphericalJoint {
        bodyB: shape0
        positionA: root.position
        positionB: Qt.vector3d(-25, 0, 0)
    }

    PrismaticJoint {
        bodyA: shape0
        bodyB: shape1
        positionA: Qt.vector3d(25, 0, 0)
        positionB: Qt.vector3d(-25, 0, 0)
        stiffness: root.stiffness
        damping: root.damping
        lowerLimit: -20
        upperLimit: 0
    }

    SphericalJoint {
        bodyA: shape1
        bodyB: shape2
        positionA: Qt.vector3d(25, 0, 0)
        positionB: Qt.vector3d(-25, 0, 0)
    }

    PrismaticJoint {
        bodyA: shape2
        bodyB: shape3
        positionA: Qt.vector3d(25, 0, 0)
        positionB: Qt.vector3d(-25, 0, 0)
        stiffness: root.stiffness
        damping: root.damping
        lowerLimit: -20
        upperLimit: 0
    }

    FixedJoint {
        bodyA: shape3
        bodyB: sphere
        positionA: Qt.vector3d(25, 0, 0)
        positionB: Qt.vector3d(0, 0, 0)
    }

    // Neighboring links touch exactly at their joints, so each body ignores collisions
    // with its immediate neighbors to avoid fighting the joint with contact forces.
    DynamicRigidBody {
        id: shape0
        position: Qt.vector3d(25, 0, 0)
        filterGroup: 0
        filterIgnoreGroups: 0b00010
        collisionShapes: CapsuleShape {
            diameter: 10
            height: 40
        }
        Model {
            geometry: CapsuleGeometry {
                diameter: 10
                height: 40
            }
            materials: PrincipledMaterial {
                baseColor: "blueviolet"
            }
        }
    }

    DynamicRigidBody {
        id: shape1
        position: Qt.vector3d(75, 0, 0)
        filterGroup: 1
        filterIgnoreGroups: 0b00101
        collisionShapes: CapsuleShape {
            diameter: 10
            height: 40
        }
        Model {
            geometry: CapsuleGeometry {
                diameter: 10
                height: 40
            }
            materials: PrincipledMaterial {
                baseColor: "blueviolet"
            }
        }
    }

    DynamicRigidBody {
        id: shape2
        position: Qt.vector3d(125, 0, 0)
        filterGroup: 2
        filterIgnoreGroups: 0b01010
        collisionShapes: CapsuleShape {
            diameter: 10
            height: 40
        }
        Model {
            geometry: CapsuleGeometry {
                diameter: 10
                height: 40
            }
            materials: PrincipledMaterial {
                baseColor: "blueviolet"
            }
        }
    }

    DynamicRigidBody {
        id: shape3
        position: Qt.vector3d(175, 0, 0)
        filterGroup: 3
        filterIgnoreGroups: 0b10100
        collisionShapes: CapsuleShape {
            diameter: 10
            height: 40
        }
        Model {
            geometry: CapsuleGeometry {
                diameter: 10
                height: 40
            }
            materials: PrincipledMaterial {
                baseColor: "blueviolet"
            }
        }
    }

    DynamicRigidBody {
        id: sphere
        position: Qt.vector3d(200, 0, 0)
        scale: Qt.vector3d(0.5, 0.5, 0.5)
        filterGroup: 4
        filterIgnoreGroups: 0b01000
        collisionShapes: SphereShape {}


        Model {
            source: "#Sphere"
            materials: PrincipledMaterial {
                baseColor: "blueviolet"
            }
        }
    }
}
//! [full]
