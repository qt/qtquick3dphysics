# Copyright (C) 2023 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(PROJECT_NAME "test_auto_invalidscene")

qt_internal_add_test(${PROJECT_NAME}
    GUI
    QMLTEST
    SOURCES
        tst_invalidscene.cpp
    LIBRARIES
        Qt::Core
        Qt::Qml
    TESTDATA
        tst_invalidscene.qml
        EmptyView.qml
        ImpellerScene.qml
    BUILTIN_TESTDATA
)

if(QT_BUILD_STANDALONE_TESTS)
    qt_import_qml_plugins(${PROJECT_NAME})
endif()
