// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick 2.15
import QtQuick.Layouts 1.15
import HelperWidgets 2.0
import StudioTheme 1.0 as StudioTheme

Column {
    width: parent.width

    Section {
        width: parent.width
        caption: qsTr("Flexible Joint")

        SectionLayout {
            PropertyLabel {
                text: "Stiffness"
                tooltip: "The spring stiffness for joint limits."
            }

            SecondColumnLayout {

                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: 0
                    maximumValue: 9999999
                    decimals: 1
                    backendValue: backendValues.stiffness
                }

                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

                ControlLabel {
                    text: "Stiffness"
                    color: StudioTheme.Values.theme3DAxisYColor
                }

                ExpandingSpacer {}
            }

            PropertyLabel {
                text: "Damping"
                tooltip: "The spring damping for joint limits."
            }

            SecondColumnLayout {

                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: 0
                    maximumValue: 9999999
                    decimals: 1
                    backendValue: backendValues.damping
                }

                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

                ControlLabel {
                    text: "Damping"
                    color: StudioTheme.Values.theme3DAxisYColor
                }

                ExpandingSpacer {}
            }
        }
    }
}
