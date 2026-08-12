// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick 2.15
import QtQuick.Layouts 1.15
import HelperWidgets 2.0

Column {
    width: parent.width

    JointSection {
        width: parent.width
    }

    FlexibleJointSection {
        width: parent.width
    }

    Section {
        width: parent.width
        caption: qsTr("Distance Joint")

        SectionLayout {
            PropertyLabel {
                text: qsTr("Min. Distance")
                tooltip: qsTr("The minimum distance of the joint constraint.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.minDistance
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            PropertyLabel {
                text: qsTr("Max. Distance")
                tooltip: qsTr("The maximum distance of the joint constraint.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.maxDistance
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }
        }
    }
}
