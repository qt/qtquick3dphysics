// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QUICK3D_PHYSICS_TEST_UTIL_H
#define QUICK3D_PHYSICS_TEST_UTIL_H

#include <QtGlobal>
#include <QtCore/qbytearray.h>
#include <QtCore/qstring.h>
#include <QtCore/qurl.h>
#include <QtQml/qqml.h>

using namespace Qt::StringLiterals;

// A TestCase that fails with a clear message if "goalReached" hasn't become true
// within "timeoutSecs" (default 30 seconds), instead of hanging until the test
// binary is killed externally.
static const char kPhysicsTestCaseQml[] = R"QML(
import QtQuick
import QtTest

TestCase {
    id: root

    property bool goalReached: false
    property real timeoutSecs: 30
    property bool qtest_timedOut: false

    when: goalReached || qtest_timedOut

    Timer {
        interval: root.timeoutSecs * 1000
        running: !root.goalReached
        onTriggered: root.qtest_timedOut = true
    }

    function verifyGoalReached() {
        verify(root.goalReached, "Timed out after " + root.timeoutSecs + " s waiting for goal condition to become true")
    }

    function test_timeoutGuard() {
        verifyGoalReached()
    }
}
)QML";

// Registers the QtQuick3D.Physics.TestUtils types from inline QML source (via a
// "data:" URL) so "import QtQuick3D.Physics.TestUtils" resolves without a real QML
// module/qmldir, a shared resource file, or any per-test TESTDATA/CMake wiring.
void registerTestUtilsTypes() {
    const QByteArray qml(kPhysicsTestCaseQml);
    const QUrl url(u"data:text/plain;base64,"_s + QString::fromLatin1(qml.toBase64()));
    qmlRegisterType(url, "QtQuick3D.Physics.TestUtils", 1, 0, "PhysicsTestCase");
}

QString needSkip() {
    if (!qEnvironmentVariableIsEmpty("QEMU_LD_PREFIX"))
        return "This test is unstable on QEMU, so it will be skipped."_L1;

    auto platform = qEnvironmentVariable("QT_QPA_PLATFORM");
    if (platform == "offscreen"_L1 || platform == "minimal"_L1)
        return "This test doesn't work on offscreen or minimal, so it will be skipped."_L1;

    return ""_L1;
}

#endif
