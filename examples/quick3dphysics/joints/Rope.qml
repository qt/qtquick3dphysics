// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

//! [full]
Node {
    id: root

    SphericalJoint {
        bodyB: shape0
        positionA: root.position
        positionB: Qt.vector3d(-20, 0, 0)
    }

    SphericalJoint {
        bodyA: shape0
        bodyB: shape1
        positionA: Qt.vector3d(20, 0, 0)
        positionB: Qt.vector3d(-20, 0, 0)
    }

    SphericalJoint {
        bodyA: shape1
        bodyB: shape2
        positionA: Qt.vector3d(20, 0, 0)
        positionB: Qt.vector3d(-20, 0, 0)
    }

    SphericalJoint {
        bodyA: shape2
        bodyB: shape3
        positionA: Qt.vector3d(20, 0, 0)
        positionB: Qt.vector3d(-20, 0, 0)
    }

    SphericalJoint {
        bodyA: shape3
        bodyB: shape4
        positionA: Qt.vector3d(20, 0, 0)
        positionB: Qt.vector3d(-20, 0, 0)
    }

    SphericalJoint {
        bodyA: shape4
        bodyB: shape5
        positionA: Qt.vector3d(20, 0, 0)
        positionB: Qt.vector3d(-20, 0, 0)
    }

    FixedJoint {
        bodyA: shape5
        bodyB: sphere
        positionA: Qt.vector3d(20, 0, 0)
        positionB: Qt.vector3d(0, 0, 0)
    }

    DynamicRigidBody {
        id: shape0
        position: Qt.vector3d(0, 0, 0)
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
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: shape1
        position: Qt.vector3d(40, 0, 0)
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
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: shape2
        position: Qt.vector3d(80, 0, 0)
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
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: shape3
        position: Qt.vector3d(120, 0, 0)
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
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: shape4
        position: Qt.vector3d(160, 0, 0)
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
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: shape5
        position: Qt.vector3d(200, 0, 0)
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
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: sphere
        position: Qt.vector3d(240, 0, 0)
        scale: Qt.vector3d(0.5, 0.5, 0.5)
        collisionShapes: SphereShape {}
        Model {
            source: "#Sphere"
            materials: PrincipledMaterial {
                baseColor: "blue"
            }
        }
    }
}
//! [full]
