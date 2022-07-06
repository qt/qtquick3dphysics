# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.14)
project(example_cannon LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(NOT DEFINED INSTALL_EXAMPLESDIR)
  set(INSTALL_EXAMPLESDIR "examples")
endif()

set(INSTALL_EXAMPLEDIR "${INSTALL_EXAMPLESDIR}/quick3dphysics/${PROJECT_NAME}")

find_package(Qt6 COMPONENTS Core)
find_package(Qt6 COMPONENTS Gui)
find_package(Qt6 COMPONENTS Quick)
find_package(Qt6 COMPONENTS Quick3D)
find_package(Qt6 COMPONENTS Quick3DPhysics)

qt_add_executable(${PROJECT_NAME}
    main.cpp
)
set_target_properties(${PROJECT_NAME} PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)
target_link_libraries(${PROJECT_NAME} PUBLIC
    Qt::Core
    Qt::Gui
    Qt::Quick
    Qt::Quick3D
    Qt::Quick3DPhysics
)

# Resources:
set(qml_resource_files
    "main.qml"
    "box.qml"
    "sphere.qml"
    "Crosshair.qml"
)

qt6_add_resources(${PROJECT_NAME} "qml"
    PREFIX
        "/"
    FILES
        ${qml_resource_files}
)

install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION "${INSTALL_EXAMPLEDIR}"
    BUNDLE DESTINATION "${INSTALL_EXAMPLEDIR}"
    LIBRARY DESTINATION "${INSTALL_EXAMPLEDIR}"
)
