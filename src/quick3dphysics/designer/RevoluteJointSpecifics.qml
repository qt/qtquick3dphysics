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
        caption: qsTr("Revolute Joint")

        SectionLayout {
            PropertyLabel {
                text: qsTr("Lower Angular Limit")
                tooltip: qsTr("The lower angular limit (in radians) of the joint constraint.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.angularLimitLower
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            PropertyLabel {
                text: qsTr("Upper Angular Limit")
                tooltip: qsTr("The upper angular limit (in radians) of the joint constraint.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.angularLimitUpper
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            PropertyLabel {
                text: qsTr("Enable Angular Limit")
                tooltip: qsTr("Enable the angular limit constraint for the joint.")
            }

            SecondColumnLayout {
                CheckBox {
                    text: backendValues.enableAngularLimit.valueToString
                    backendValue: backendValues.enableAngularLimit
                    implicitWidth: StudioTheme.Values.twoControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }

                ExpandingSpacer {}
            }
        }
    }
}
