# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qt_internal_add_test(test_auto_raycaster
    GUI
    QMLTEST
    SOURCES
        ../shared/util.h
        tst_raycaster.cpp
    LIBRARIES
        Qt::Core
        Qt::Qml
    TESTDATA
        tst_raycaster.qml
        tst_raycaster_deleted_body.qml
    BUILTIN_TESTDATA
)

if(QT_BUILD_STANDALONE_TESTS)
    qt_import_qml_plugins(test_auto_raycaster)
endif()
