// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtQuickTest/quicktest.h>
#include "../shared/util.h"
class tst_query_structure : public QObject
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
        tst_query_structure skip;
        return QTest::qExec(&skip, argc, argv);
    }
    registerTestUtilsTypes();
    QTEST_SET_MAIN_SOURCE_PATH
    return quick_test_main(argc, argv, "tst_query_structure", QUICK_TEST_SOURCE_DIR);
}
#include "tst_query_structure.moc"
