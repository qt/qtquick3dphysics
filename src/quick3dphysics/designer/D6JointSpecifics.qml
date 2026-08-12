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
        caption: qsTr("D6 Joint")

        SectionLayout {
            // X Motion
            PropertyLabel {
                text: qsTr("X Motion")
                tooltip: qsTr("The motion constraint along the X axis.")
            }
            SecondColumnLayout {
                ComboBox {
                    scope: "D6Joint"
                    model: [qsTr("Locked"), qsTr("Limited"), qsTr("Free")]
                    backendValue: backendValues.xMotion
                    Layout.fillWidth: true
                }
                ExpandingSpacer {}
            }

            // Y Motion
            PropertyLabel {
                text: qsTr("Y Motion")
                tooltip: qsTr("The motion constraint along the Y axis.")
            }
            SecondColumnLayout {
                ComboBox {
                    scope: "D6Joint"
                    model: [qsTr("Locked"), qsTr("Limited"), qsTr("Free")]
                    backendValue: backendValues.yMotion
                    Layout.fillWidth: true
                }
                ExpandingSpacer {}
            }

            // Z Motion
            PropertyLabel {
                text: qsTr("Z Motion")
                tooltip: qsTr("The motion constraint along the Z axis.")
            }
            SecondColumnLayout {
                ComboBox {
                    scope: "D6Joint"
                    model: [qsTr("Locked"), qsTr("Limited"), qsTr("Free")]
                    backendValue: backendValues.zMotion
                    Layout.fillWidth: true
                }
                ExpandingSpacer {}
            }

            // Twist Motion
            PropertyLabel {
                text: qsTr("Twist Motion")
                tooltip: qsTr("The rotational constraint around the X axis.")
            }
            SecondColumnLayout {
                ComboBox {
                    scope: "D6Joint"
                    model: [qsTr("Locked"), qsTr("Limited"), qsTr("Free")]
                    backendValue: backendValues.twistMotion
                    Layout.fillWidth: true
                }
                ExpandingSpacer {}
            }

            // Swing Y Motion
            PropertyLabel {
                text: qsTr("Swing Motion Y")
                tooltip: qsTr("The rotational constraint around the Y axis.")
            }
            SecondColumnLayout {
                ComboBox {
                    scope: "D6Joint"
                    model: [qsTr("Locked"), qsTr("Limited"), qsTr("Free")]
                    backendValue: backendValues.swingMotionY
                    Layout.fillWidth: true
                }
                ExpandingSpacer {}
            }

            // Swing Z Motion
            PropertyLabel {
                text: qsTr("Swing Motion Z")
                tooltip: qsTr("The rotational constraint around the Z axis.")
            }
            SecondColumnLayout {
                ComboBox {
                    scope: "D6Joint"
                    model: [qsTr("Locked"), qsTr("Limited"), qsTr("Free")]
                    backendValue: backendValues.swingMotionZ
                    Layout.fillWidth: true
                }
                ExpandingSpacer {}
            }

            // Linear Limit X
            PropertyLabel {
                text: qsTr("Linear Limit X")
                tooltip: qsTr("The lower and upper limits of movement along the X axis.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.linearLimitXLower
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.linearLimitXUpper
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                ExpandingSpacer {}
            }

            // Linear Limit Y
            PropertyLabel {
                text: qsTr("Linear Limit Y")
                tooltip: qsTr("The lower and upper limits of movement along the Y axis.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.linearLimitYLower
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.linearLimitYUpper
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                ExpandingSpacer {}
            }

            // Linear Limit Z
            PropertyLabel {
                text: qsTr("Linear Limit Z")
                tooltip: qsTr("The lower and upper limits of movement along the Z axis.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.linearLimitZLower
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                SpinBox {
                    minimumValue: -9999999
                    maximumValue: 9999999
                    decimals: 5
                    backendValue: backendValues.linearLimitZUpper
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                ExpandingSpacer {}
            }

            // Twist Limit
            PropertyLabel {
                text: qsTr("Twist Limit")
                tooltip: qsTr("The lower and upper angular limits around the X axis.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: -6.28319
                    maximumValue: 6.28319
                    decimals: 5
                    backendValue: backendValues.twistLimitLower
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                // Upper limit spinbox
                SpinBox {
                    minimumValue: -6.28319
                    maximumValue: 6.28319
                    decimals: 5
                    backendValue: backendValues.twistLimitUpper
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                }
                ExpandingSpacer {}
            }

            // Swing Y Limit Angle
            PropertyLabel {
                text: qsTr("Swing Y Limit Angle")
                tooltip: qsTr("The maximum swing angle limit around the Y axis.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 3.14159
                    decimals: 5
                    backendValue: backendValues.swingLimitAngleY
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            // Swing Z Limit Angle
            PropertyLabel {
                text: qsTr("Swing Z Limit Angle")
                tooltip: qsTr("The maximum swing angle limit around the Z axis.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 3.14159
                    decimals: 5
                    backendValue: backendValues.swingLimitAngleZ
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            // Linear Stiffness
            PropertyLabel {
                text: qsTr("Linear Stiffness")
                tooltip: qsTr("The spring stiffness for linear motion constraints.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.linearStiffness
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            // Linear Damping
            PropertyLabel {
                text: qsTr("Linear Damping")
                tooltip: qsTr("The spring damping for linear motion constraints.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.linearDamping
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            // Angular Stiffness
            PropertyLabel {
                text: qsTr("Angular Stiffness")
                tooltip: qsTr("The spring stiffness for angular motion constraints.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.angularStiffness
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }

            // Angular Damping
            PropertyLabel {
                text: qsTr("Angular Damping")
                tooltip: qsTr("The spring damping for angular motion constraints.")
            }
            SecondColumnLayout {
                SpinBox {
                    minimumValue: 0.00000
                    maximumValue: 9999999
                    decimals: 2
                    backendValue: backendValues.angularDamping
                    implicitWidth: StudioTheme.Values.singleControlColumnWidth
                                    + StudioTheme.Values.actionIndicatorWidth
                }
                ExpandingSpacer {}
            }
        }
    }

}
