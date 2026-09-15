// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtQuickTest/quicktest.h>

#include "../shared/util.h"

class tst_raycaster : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void skiptest() { QSKIP("This test will fail, skipping."); }
};

// Deletes an object on the spot. QML's destroy() is deferred to the event loop, which does not
// run in the middle of a physics frame.
class ImmediateDeleter : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE void deleteObject(QObject *object) { delete object; }
};

int main(int argc, char **argv)
{
    const QString message = needSkip();
    if (!message.isEmpty()) {
        qWarning() << message;
        tst_raycaster skip;
        return QTest::qExec(&skip, argc, argv);
    }
    QTEST_SET_MAIN_SOURCE_PATH
    registerTestUtilsTypes();
    qmlRegisterSingletonType<ImmediateDeleter>(
            "RaycasterTest", 1, 0, "ImmediateDeleter",
            [](QQmlEngine *, QJSEngine *) -> QObject * { return new ImmediateDeleter; });
    return quick_test_main(argc, argv, "tst_raycaster", QUICK_TEST_SOURCE_DIR);
}

#include "tst_raycaster.moc"
