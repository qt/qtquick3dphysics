// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtQuickTest/quicktest.h>
#include "../shared/util.h"
class tst_trigger_pairs: public QObject
{
    Q_OBJECT
private slots:
    void skiptest() { QSKIP("This test will fail, skipping."); };
};
int main(int argc, char **argv)
{
    QString message = needSkip();
    if (!message.isEmpty()) {
        qWarning() << message;
        tst_trigger_pairs skip;
        return QTest::qExec(&skip, argc, argv);
    }
    QTEST_SET_MAIN_SOURCE_PATH
    registerTestUtilsTypes();
    return quick_test_main(argc, argv, "tst_trigger_pairs", QUICK_TEST_SOURCE_DIR);
}
#include "tst_trigger_pairs.moc"
