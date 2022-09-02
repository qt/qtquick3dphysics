# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0

qt_get_tool_target_name(target_name cooker)
qt_internal_add_tool(${target_name}
    TOOLS_TARGET Quick3DPhysics
    SOURCES
        main.cpp
    LIBRARIES
        Qt::Core
        Qt::Quick3D
        Qt::Quick3DPrivate
        Qt::Quick3DPhysics
        Qt::Quick3DPhysicsPrivate
        Qt::BundledPhysX
)
qt_internal_return_unless_building_tools()

target_include_directories(${target_name} SYSTEM
    PRIVATE
    ../../src/3rdparty/PhysX/include
    ../../src/3rdparty/PhysX/pxshared/include
)
if (UNIX)
    # Needed for PxPreprocessor.h error
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        qt_internal_extend_target(${target_name} DEFINES _DEBUG)
    else()
        qt_internal_extend_target(${target_name} DEFINES NDEBUG)
    endif()
endif()
qt_internal_extend_target(${target_name} DEFINES PX_PHYSX_STATIC_LIB)
