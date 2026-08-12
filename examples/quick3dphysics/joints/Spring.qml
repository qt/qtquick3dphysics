// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics

//! [full]
Node {
    id: root

    DynamicRigidBody {
        id: baseStand
        position: Qt.vector3d(0, 0, 0)

        collisionShapes: BoxShape {
            extents: Qt.vector3d(50, 10, 50)
        }

        Model {
            source: "#Cube"
            scale: Qt.vector3d(0.50, 0.10, 0.50)

            materials: PrincipledMaterial {
                baseColor: "darkslategray"
            }
        }
    }

    DynamicRigidBody {
        id: floatingSphere
        position: Qt.vector3d(0, 102.5, 0)

        collisionShapes: SphereShape {
            diameter: 20
        }

        Model {
            source: "#Sphere"
            // scale: Qt.vector3d(0.2, 0.2, 0.2)
            materials: PrincipledMaterial {
                baseColor: "cornflowerblue"
                roughness: 0.2
            }
        }
    }

    // D6 Joint acting as a soft spring wire
    D6Joint {
        bodyA: baseStand
        bodyB: floatingSphere

        positionA: Qt.vector3d(0, 2.5, 0)
        positionB: Qt.vector3d(0, -100, 0)

        xMotion: D6Joint.Locked
        yMotion: D6Joint.Locked
        zMotion: D6Joint.Locked

        // Allow omnidirectional rotation
        twistMotion: D6Joint.Limited
        swingMotionY: D6Joint.Limited
        swingMotionZ: D6Joint.Limited

        twistLimitLower: -0.07    // ~-4 degrees in radians
        twistLimitUpper: 0.07     // ~+4 degrees in radians
        swingLimitAngleY: 0.087   // ~5 degrees in radians
        swingLimitAngleZ: 0.087   // ~5 degrees in radians

        angularStiffness: 2550000.0
        angularDamping: 2500.0
    }
}
//! [full]
