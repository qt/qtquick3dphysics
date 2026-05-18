// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers
import QtQuick3D.Helpers
import QtQuick.Controls
import QtQuick.Layouts

Node {
    id: cart
    property bool limitAngular: false

    PhysicsMaterial {
        id: physicsMaterial
        staticFriction: 1.0
        dynamicFriction: 0.0
        restitution: 0.0
    }

    function destroyShapes() {
        box.collisionShapes = [];
        capsule.collisionShapes = [];
        capsule1.collisionShapes = [];
    }

    RevoluteJoint {
        id: jointLeft
        bodyA: capsule1
        bodyB: box
        positionA: Qt.vector3d(0, 0, 0)
        positionB: Qt.vector3d(0, -100, 250)
        angularLimitLower: -Math.PI / 4
        angularLimitUpper: Math.PI / 4
        enableAngularLimit: cart.limitAngular
    }

    RevoluteJoint {
        id: jointRight
        bodyA: capsule
        bodyB: box
        positionA: Qt.vector3d(0, 0, 0)
        positionB: Qt.vector3d(0, -100, -250)
        angularLimitLower: -Math.PI / 4
        angularLimitUpper: Math.PI / 4
        enableAngularLimit: cart.limitAngular
    }

    DynamicRigidBody {
        id: box
        physicsMaterial: physicsMaterial
        massMode: DynamicRigidBody.CustomDensity
        density: 10
        scale: Qt.vector3d(5, 1, 5)
        position: Qt.vector3d(0, 0, 0)
        Model {
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "red"
            }
        }
        collisionShapes: BoxShape {}
        sendTriggerReports: true
    }

    DynamicRigidBody {
        id: capsule
        physicsMaterial: physicsMaterial
        massMode: DynamicRigidBody.CustomDensity
        density: 10
        property vector3d startPosition: Qt.vector3d(0, -100, -250)
        eulerRotation: Qt.vector3d(0, 0, 0)
        position: startPosition
        Model {
            geometry: CapsuleGeometry {
                diameter: 100
                height: 400
            }
            materials: PrincipledMaterial {
                baseColor: "darkblue"
            }
        }
        Model {
            scale: Qt.vector3d(4, 1, 1)
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "pink"
            }
        }
        collisionShapes: CapsuleShape {
            diameter: 100
            height: 400
        }
    }

    DynamicRigidBody {
        id: capsule1
        physicsMaterial: physicsMaterial
        massMode: DynamicRigidBody.CustomDensity
        density: 10
        property vector3d startPosition: Qt.vector3d(0, -100, 250)
        position: startPosition
        Model {
            geometry: CapsuleGeometry {
                diameter: 100
                height: 400
            }
            materials: PrincipledMaterial {
                baseColor: "lightblue"
            }
        }
        Model {
            scale: Qt.vector3d(4, 1, 1)
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "pink"
            }
        }
        collisionShapes: CapsuleShape {
            diameter: 100
            height: 400
        }
    }
}
