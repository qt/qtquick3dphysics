# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(PROJECT_NAME "test_auto_gravityfield")

qt_internal_add_test(${PROJECT_NAME}
    GUI
    QMLTEST
    SOURCES
        ../shared/util.h
        tst_gravityfield.cpp
    LIBRARIES
        Qt::Core
        Qt::Qml
        Qt::Quick3DPhysicsPrivate
        Qt::Quick3DPrivate
    TESTDATA
        tst_gravityfield.qml
        tst_gravityfield_character.qml
        tst_gravityfield_compose.qml
        tst_gravityfield_directional.qml
        tst_gravityfield_lifetime.qml
        tst_gravityfield_shapes.qml
        tst_gravityfield_sleeping.qml
        tst_gravityfield_tracking.qml
        tst_gravityfield_values.qml
        tst_gravityfield_wake.qml
        tst_gravityfield_walking.qml
    BUILTIN_TESTDATA
)

if(QT_BUILD_STANDALONE_TESTS)
    qt_import_qml_plugins(${PROJECT_NAME})
endif()
