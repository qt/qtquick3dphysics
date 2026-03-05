// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics

//! [capsulelink]
DynamicRigidBody {
    id: root
    property real len: 170
    property real w: 17
    PrincipledMaterial {
        id: material3
        baseColor: "yellow"
        metalness: 1.0
        roughness: 0.5
    }
    Node {
        opacity: 1
        Model {
            materials: material3
            source: "#Cylinder"
            scale: Qt.vector3d(root.w / 100, root.len / 100, root.w / 100)
            eulerRotation.z: 90
            y: -root.len / 2
        }
        Model {
            materials: material3
            source: "#Cylinder"
            scale: Qt.vector3d(root.w / 100, root.len / 100, root.w / 100)
            eulerRotation.z: 90
            y: root.len / 2
        }
        Model {
            materials: material3
            source: "#Cylinder"
            scale: Qt.vector3d(root.w / 100, root.len / 100, root.w / 100)
            x: root.len / 2
        }
        Model {
            materials: material3
            source: "#Cylinder"
            scale: Qt.vector3d(root.w / 100, root.len / 100, root.w / 100)
            x: -root.len / 2
        }
        Model {
            materials: material3
            source: "#Sphere"
            scale: Qt.vector3d(root.w / 100, root.w / 100, root.w / 100)
            x: -root.len / 2
            y: -root.len / 2
        }
        Model {
            materials: material3
            source: "#Sphere"
            scale: Qt.vector3d(root.w / 100, root.w / 100, root.w / 100)
            x: -root.len / 2
            y: root.len / 2
        }
        Model {
            materials: material3
            source: "#Sphere"
            scale: Qt.vector3d(root.w / 100, root.w / 100, root.w / 100)
            x: root.len / 2
            y: -root.len / 2
        }
        Model {
            materials: material3
            source: "#Sphere"
            scale: Qt.vector3d(root.w / 100, root.w / 100, root.w / 100)
            x: root.len / 2
            y: root.len / 2
        }
    }
    collisionShapes: [
        CapsuleShape {
            y: -root.len / 2
            height: root.len
            diameter: root.w
        },
        CapsuleShape {
            y: root.len / 2
            height: root.len
            diameter: root.w
        },
        CapsuleShape {
            x: -root.len / 2
            eulerRotation.z: 90
            height: root.len
            diameter: root.w
        },
        CapsuleShape {
            x: root.len / 2
            eulerRotation.z: 90
            height: root.len
            diameter: root.w
        }
    ]
}
//! [capsulelink]
