// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick
import QtQuick3D
import QtQuick3D.Physics

// A sphere flying at high speed straight through a thin static wall. Without
// CCD, the discrete solver only checks the sphere's pose at the end of each
// step, so a sphere fast enough clears the wall in a single step and the two
// never register as overlapping. With CCD the swept path is checked instead,
// so the crossing is caught regardless of speed.
View3D {
    id: viewport
    property alias ccd: bullet.ccd
    property alias enableCCD: world.enableCCD
    property alias bulletPosition: bullet.position
    property bool contact: false

    environment: SceneEnvironment {
        clearColor: "#d6dbdf"
        backgroundMode: SceneEnvironment.Color
    }

    PerspectiveCamera {
        position: Qt.vector3d(0, 0, 1500)
        clipFar: 3000
        clipNear: 1
    }

    DirectionalLight {
        eulerRotation.x: -45
        eulerRotation.y: 45
        castsShadow: false
        brightness: 1
    }

    PhysicsWorld {
        id: world
        scene: viewport.scene
        gravity: Qt.vector3d(0, 0, 0)
        // Fixed timestep so the per-step travel distance is deterministic
        // regardless of the machine's actual frame rate.
        minimumTimestep: 15
        maximumTimestep: 15
    }

    StaticRigidBody {
        position: Qt.vector3d(0, 0, 0)
        collisionShapes: BoxShape { extents: Qt.vector3d(400, 8, 400) }
        sendContactReports: true
        Model {
            source: "#Cube"
            scale: Qt.vector3d(4, 0.08, 4)
            materials: PrincipledMaterial {
                baseColor: "blue"
            }
        }
    }

    DynamicRigidBody {
        id: bullet
        position: Qt.vector3d(0, 1000, 0)
        collisionShapes: SphereShape {}
        receiveContactReports: true
        onBodyContact: () => {
            viewport.contact = true
        }
        Component.onCompleted: setLinearVelocity(Qt.vector3d(0, -50000, 0))

        Model {
            source: "#Sphere"
            materials: PrincipledMaterial {
                baseColor: "red"
            }
        }
    }
}
