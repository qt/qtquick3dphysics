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
        caption: qsTr("Joint")

        SectionLayout {
            PropertyLabel {
                text: qsTr("Body A")
                tooltip: qsTr("The first body this joint connects to.")
            }

            SecondColumnLayout {
                ItemFilterComboBox {
                    typeFilter: "QtQuick3D.Physics.PhysicsBody"
                    backendValue: backendValues.bodyA
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                }

                ExpandingSpacer {}
            }
        }

        SectionLayout {
            PropertyLabel {
                text: qsTr("Position A")
                tooltip: qsTr("The position of the joint relative to Body A.")
            }

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.positionA_x
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "X"
                    color: StudioTheme.Values.theme3DAxisXColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.positionA_y
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Y"
                    color: StudioTheme.Values.theme3DAxisYColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.positionA_z
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Z"
                    color: StudioTheme.Values.theme3DAxisZColor
                }
                ExpandingSpacer {}
            }
        }

        SectionLayout {
            PropertyLabel {
                text: qsTr("Orientation A")
                tooltip: qsTr("The orientation of the joint relative to Body A.")
            }

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationA_w
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "W"
                    color: StudioTheme.Values.theme3DAxisWColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationA_x
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "X"
                    color: StudioTheme.Values.theme3DAxisXColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationA_y
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Y"
                    color: StudioTheme.Values.theme3DAxisYColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationA_z
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Z"
                    color: StudioTheme.Values.theme3DAxisZColor
                }
                ExpandingSpacer {}
            }
        }

        SectionLayout {
            PropertyLabel {
                text: qsTr("Body B")
                tooltip: qsTr("The second body this joint connects to.")
            }

            SecondColumnLayout {
                ItemFilterComboBox {
                    typeFilter: "QtQuick3D.Physics.PhysicsBody"
                    backendValue: backendValues.bodyB
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                }

                ExpandingSpacer {}
            }
        }

        SectionLayout {
            PropertyLabel {
                text: qsTr("Position B")
                tooltip: qsTr("The position of the joint relative to Body B.")
            }

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.positionB_x
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "X"
                    color: StudioTheme.Values.theme3DAxisXColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.positionB_y
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Y"
                    color: StudioTheme.Values.theme3DAxisYColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.positionB_z
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Z"
                    color: StudioTheme.Values.theme3DAxisZColor
                }
                ExpandingSpacer {}
            }
        }

        SectionLayout {
            PropertyLabel {
                text: qsTr("Orientation B")
                tooltip: qsTr("The orientation of the joint relative to Body B.")
            }

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationB_w
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "W"
                    color: StudioTheme.Values.theme3DAxisWColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationB_x
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "X"
                    color: StudioTheme.Values.theme3DAxisXColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationB_y
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Y"
                    color: StudioTheme.Values.theme3DAxisYColor
                }
                ExpandingSpacer {}
            }

            PropertyLabel {}

            SecondColumnLayout {
                SpinBox {
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                   + StudioTheme.Values.actionIndicatorWidth
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.orientationB_z
                }
                Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }
                ControlLabel {
                    text: "Z"
                    color: StudioTheme.Values.theme3DAxisZColor
                }
                ExpandingSpacer {}
            }
        }
    }
}
