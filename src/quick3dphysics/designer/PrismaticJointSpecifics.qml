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

    Section {
        width: parent.width
        caption: qsTr("Prismatic Joint")

        SectionLayout {
            PropertyLabel {
                text: qsTr("Lower Limit")
                tooltip: qsTr("The lower limit of the constraint, i.e. how far along the negative x-axis the joint can extend.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: -1000000
                    maximumValue: 1000000
                    decimals: 5
                    backendValue: backendValues.lowerLimit
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            PropertyLabel {
                text: qsTr("Upper Limit")
                tooltip: qsTr("The upper limit of the constraint, i.e. how far along the positive x-axis the joint can extend.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: -1000000
                    maximumValue: 1000000
                    decimals: 5
                    backendValue: backendValues.upperLimit
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }
        }
    }
}
