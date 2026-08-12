# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(PROJECT_NAME "test_auto_invalidinput")

qt_internal_add_test(${PROJECT_NAME}
    GUI
    QMLTEST
    SOURCES
        ../shared/util.h
        tst_invalidinput.cpp
    LIBRARIES
        Qt::Core
        Qt::Qml
        Qt::Gui
        Qt::Quick3D
    TESTDATA
        tst_invalidinput.qml
    BUILTIN_TESTDATA
)

if(QT_BUILD_STANDALONE_TESTS)
    qt_import_qml_plugins(${PROJECT_NAME})
endif()

qt_add_qml_module(${PROJECT_NAME}
    URI PhysicsTest.InvalidInput
    VERSION 1.0
    QML_FILES
        tst_invalidinput.qml
    SOURCES
        nopositiongeometry.cpp nopositiongeometry.h
        badstridegeometry.cpp badstridegeometry.h
    RESOURCE_PREFIX "/qt/qml"
    IMPORTS
        QtQuick3D
)
