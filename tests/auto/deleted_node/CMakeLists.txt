# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(PROJECT_NAME "test_auto_deleted_node")

qt_internal_add_test(${PROJECT_NAME}
    GUI
    QMLTEST
    SOURCES
        ../shared/util.h
        tst_deleted_node.cpp
    LIBRARIES
        Qt::Core
        Qt::Qml
    TESTDATA
        tst_deleted_node.qml
        tst_scene_changed_mid_sync.qml
        tst_scene_changed_mid_trigger.qml
    BUILTIN_TESTDATA
)

if(QT_BUILD_STANDALONE_TESTS)
    qt_import_qml_plugins(${PROJECT_NAME})
endif()
