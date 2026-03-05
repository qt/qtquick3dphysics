// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtQuick3D
import QtQuick3D.Physics

//! [dice 2]
DynamicRigidBody {
    id: thisBody
    required property int index

    //! [textures 2]
    Texture {
        id: numberNormal
        source: "maps/numbers-normal.png"
    }

    Texture {
        id: numberFill
        source: "maps/numbers.png"
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    //! [textures 2]

    function randomInRange(min, max) {
        return Math.random() * (max - min) + min
    }

    function restore() {
        reset(initialPosition, eulerRotation)
    }

    scale: Qt.vector3d(scaleFactor, scaleFactor, scaleFactor)
    eulerRotation: Qt.vector3d(randomInRange(0, 360),
                               randomInRange(0, 360),
                               randomInRange(0, 360))

    property vector3d initialPosition: Qt.vector3d(11 + 1.5 * Math.cos(index/(Math.PI/4)),
                                                   6 + index * 1.5,
                                                   0)
    position: initialPosition

    property real scaleFactor: randomInRange(0.8, 1.4)
    property color baseCol: Qt.hsla(randomInRange(0, 1),
                                    randomInRange(0.6, 1.0),
                                    randomInRange(0.4, 0.7),
                                    1.0)

    collisionShapes: ConvexMeshShape {
        id: diceShape
        source: Math.random() < 0.25 ? "meshes/icosahedron.mesh"
              : Math.random() < 0.5 ? "meshes/dodecahedron.mesh"
              : Math.random() < 0.75 ? "meshes/octahedron.mesh"
                                     : "meshes/tetrahedron.mesh"
    }

    Model {
        id: thisModel
        source: diceShape.source
        receivesShadows: false
        materials: PrincipledMaterial {
            metalness: 1.0
            roughness: thisBody.randomInRange(0.2, 0.6)
            baseColor: thisBody.baseCol
            emissiveMap: numberFill
            emissiveFactor: Qt.vector3d(1, 1, 1)
            normalMap: numberNormal
            normalStrength: 0.75
        }
    }
}
//! [dice 2]
