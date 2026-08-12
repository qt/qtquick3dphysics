// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

//! [full]
Node {
    id: root
    property vector3d jointRotation : Qt.vector3d(0, 90, 0)

    RevoluteJoint {
        bodyA: revoluteBoxA
        bodyB: revoluteBoxB
        positionA: Qt.vector3d(100, 0, 0)
        positionB: Qt.vector3d(100, 0, 0)
        orientationB: Quaternion.fromEulerAngles(0, 0, 90)
        angularLimitLower: -Math.PI / 4
        angularLimitUpper: Math.PI / 4
        enableAngularLimit: true
    }

    DynamicRigidBody {
        id: revoluteBoxA
        position: Qt.vector3d(0, 0, 0)
        eulerRotation: root.jointRotation
        kinematicPosition: Qt.vector3d(0, 0, 0)
        kinematicEulerRotation: root.jointRotation
        isKinematic: true
        scale: Qt.vector3d(2, 0.5, 0.5)
        collisionShapes: BoxShape {}
        Model {
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "yellow"
            }
        }
    }

    DynamicRigidBody {
        id: revoluteBoxB
        position: Qt.vector3d(0, 100, -100)
        eulerRotation: Qt.vector3d(0, 90, -90)
        scale: Qt.vector3d(2, 0.5, 0.5)
        collisionShapes: BoxShape {}
        Model {
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "blue"
            }
        }
    }
}
//! [full]
