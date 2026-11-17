// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtQuickTest/quicktest.h>
#include <QtQuick3DPhysics/private/qabstracttriggerregion_p.h>
#include "../shared/util.h"

// A field exposes no count of what it tracks, so tests read it here.
class RegionProbe : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE int trackedCount(QObject *field) const
    {
        auto *region = qobject_cast<QAbstractTriggerRegion *>(field);
        return region ? region->collisionCount() : -1;
    }
};

class tst_gravityfield : public QObject
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
        tst_gravityfield skip;
        return QTest::qExec(&skip, argc, argv);
    }
    QTEST_SET_MAIN_SOURCE_PATH
    registerTestUtilsTypes();
    qmlRegisterType<RegionProbe>("QtQuick3D.Physics.TestUtils", 1, 0, "RegionProbe");
    return quick_test_main(argc, argv, "tst_gravityfield", QUICK_TEST_SOURCE_DIR);
}
#include "tst_gravityfield.moc"
