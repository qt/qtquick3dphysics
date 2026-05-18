# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(PROJECT_NAME "test_auto_callback_create_delete_joints")

qt_internal_add_test(${PROJECT_NAME}
    GUI
    QMLTEST
    SOURCES
        ../shared/util.h
        tst_callback_create_delete_joints.cpp
    LIBRARIES
        Qt::Core
        Qt::Qml
    TESTDATA
        tst_callback_create_delete_joints.qml
        Box.qml
        Joint.qml
    BUILTIN_TESTDATA
)

if(QT_BUILD_STANDALONE_TESTS)
    qt_import_qml_plugins(${PROJECT_NAME})
endif()
