// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick 2.15
import QtQuick.Layouts 1.15
import HelperWidgets 2.0
import StudioTheme 1.0 as StudioTheme

Section {
    caption: qsTr("Character Controller")
    width: parent.width

    SectionLayout {
        PropertyLabel {
            text: "Gravity"
            tooltip: "The gravitational acceleration that applies to the character."
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.gravity_x
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "X"
                color: StudioTheme.Values.theme3DAxisXColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.gravity_y
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "Y"
                color: StudioTheme.Values.theme3DAxisYColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.gravity_z
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "Z"
                color: StudioTheme.Values.theme3DAxisZColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Movement"
            tooltip: "The controlled motion of the character."
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.movement_x
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "X"
                color: StudioTheme.Values.theme3DAxisXColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.movement_y
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "Y"
                color: StudioTheme.Values.theme3DAxisYColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.movement_z
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "Z"
                color: StudioTheme.Values.theme3DAxisZColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Movement Mode"
            tooltip: "Defines how character movement vector is processed."
        }

        SecondColumnLayout {
            ComboBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                scope: "CharacterController"
                model: ["ForwardBased", "Free"]
                backendValue: backendValues.movementMode
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Maximum Step Height"
            tooltip: "The maximum height the character can step up without jumping."
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -1
                maximumValue: 9999999
                decimals: 2
                backendValue: backendValues.maximumStepHeight
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Slope Limit"
            tooltip: "The steepest slope, in degrees, that the character can climb."
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: 0
                maximumValue: 90
                stepSize: 1
                decimals: 1
                backendValue: backendValues.slopeLimit
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Slide On Steep Slopes"
            tooltip: "Makes the character slide down slopes steeper than the slope limit."
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.slideOnSteepSlopes.valueToString
                backendValue: backendValues.slideOnSteepSlopes
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Mid Air Control"
            tooltip: "Enables movement property to have an effect when the character is in free fall."
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.midAirControl.valueToString
                backendValue: backendValues.midAirControl
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: "Enable ShapeHit Callback"
            tooltip: "Enables the shapeHit callback for this character controller."
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.enableShapeHitCallback.valueToString
                backendValue: backendValues.enableShapeHitCallback
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }
    }
}
