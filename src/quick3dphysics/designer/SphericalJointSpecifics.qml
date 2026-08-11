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
        caption: qsTr("Spherical Joint")

        SectionLayout {
            PropertyLabel {
                text: qsTr("Cone Limit Y")
                tooltip: qsTr("The y limit (in radians) of the joint's cone constraint.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0
                    maximumValue: 3.14159
                    decimals: 5
                    backendValue: backendValues.coneLimitY
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            PropertyLabel {
                text: qsTr("Cone Limit Z")
                tooltip: qsTr("The z limit (in radians) of the joint's cone constraint.")
            }

            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0
                    maximumValue: 3.14159
                    decimals: 5
                    backendValue: backendValues.coneLimitZ
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            PropertyLabel {
                text: qsTr("Enable Cone Limit")
                tooltip: qsTr("Enable the cone limit constraint for the joint.")
            }

            SecondColumnLayout {
                CheckBox {
                    text: backendValues.enableConeLimit.valueToString
                    backendValue: backendValues.enableConeLimit
                    implicitWidth: StudioTheme.Values.twoControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }

                ExpandingSpacer {}
            }
        }
    }
}
