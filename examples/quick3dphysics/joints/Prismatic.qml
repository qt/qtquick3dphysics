// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Physics.Helpers

//! [full]
Node {
    id: root
    property vector3d jointRotation : Qt.vector3d(0, 0, 90)

    PrismaticJoint {
        bodyA: prismaticBoxA
        bodyB: prismaticBoxB
        lowerLimit: -200
        upperLimit: 0
        positionA: Qt.vector3d(100, 0, 0)
        positionB: Qt.vector3d(-100, 0, 0)
    }

    DynamicRigidBody {
        id: prismaticBoxA
        position: Qt.vector3d(0, 200, 0)
        eulerRotation: root.jointRotation
        kinematicPosition: Qt.vector3d(0, 200, 0)
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
        id: prismaticBoxB
        position: Qt.vector3d(200 * Math.cos(root.jointRotation.z * Math.PI / 180),
                               200 + 200 * Math.sin(root.jointRotation.z * Math.PI / 180),
                               0)
        eulerRotation: root.jointRotation
        scale: Qt.vector3d(2, 0.4, 0.4)
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
