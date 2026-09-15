// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

import QtQuick 2.15
import QtQuick.Layouts 1.15
import HelperWidgets 2.0
import StudioTheme 1.0 as StudioTheme

Section {
    caption: qsTr("Raycaster")
    width: parent.width

    SectionLayout {
        PropertyLabel {
            text: qsTr("Enabled")
            tooltip: qsTr("Whether the ray is cast on each physics frame.")
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.enabled.valueToString
                backendValue: backendValues.enabled
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                               + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: qsTr("Direction")
            tooltip: qsTr("The direction of the ray in local coordinates.")
        }

        SecondColumnLayout {
            SpinBox {
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
                minimumValue: -9999999
                maximumValue: 9999999
                decimals: 3
                backendValue: backendValues.direction_x
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
                decimals: 3
                backendValue: backendValues.direction_y
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
                decimals: 3
                backendValue: backendValues.direction_z
            }

            Spacer { implicitWidth: StudioTheme.Values.controlLabelGap }

            ControlLabel {
                text: "Z"
                color: StudioTheme.Values.theme3DAxisZColor
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: qsTr("Max Distance")
            tooltip: qsTr("The maximum distance of the ray in scene units.")
        }

        SecondColumnLayout {
            SpinBox {
                minimumValue: 0
                maximumValue: 9999999
                decimals: 3
                backendValue: backendValues.maxDistance
                implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: qsTr("Exclude Parent Body")
            tooltip: qsTr("Whether the physics bodies the ray is placed in are left out of the result.")
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.excludeParentBody.valueToString
                backendValue: backendValues.excludeParentBody
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                               + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: qsTr("Excluded Bodies")
            tooltip: qsTr("Bodies the ray never reports.")
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 5
        }

        SecondColumnLayout {
            EditableListView {
                backendValue: backendValues.excludedBodies
                model: backendValues.excludedBodies.expressionAsList
                Layout.fillWidth: true
                typeFilter: "QtQuick3D.Physics.PhysicsNode"

                onAdd: function(value) { backendValues.excludedBodies.idListAdd(value) }
                onRemove: function(idx) { backendValues.excludedBodies.idListRemove(idx) }
                onReplace: function (idx, value) { backendValues.excludedBodies.idListReplace(idx, value) }
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: qsTr("Include Static")
            tooltip: qsTr("Whether static physics bodies are included in the query.")
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.includeStatic.valueToString
                backendValue: backendValues.includeStatic
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                               + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }

        PropertyLabel {
            text: qsTr("Include Dynamic")
            tooltip: qsTr("Whether dynamic physics bodies are included in the query.")
        }

        SecondColumnLayout {
            CheckBox {
                text: backendValues.includeDynamic.valueToString
                backendValue: backendValues.includeDynamic
                implicitWidth: StudioTheme.Values.twoControlColumnWidth
                               + StudioTheme.Values.actionIndicatorWidth
            }

            ExpandingSpacer {}
        }
    }
}
