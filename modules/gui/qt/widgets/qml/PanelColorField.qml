/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.Style

// Color setting: its hexadecimal code, editable, and a swatch that opens a
// palette of common colors.
PanelTextField {
    id: root

    // "#RRGGBB"
    property string colorValue: "#ffffff"

    signal colorModified(string colorValue)

    property var swatches: [
        "#ffffff", "#e0e0e0", "#b8b8b8", "#808080", "#404040", "#0c0c0c", "#000000",
        "#ffeb3b", "#ffc107", "#ff8800", "#f44336", "#e91e63", "#9c27b0", "#3f51b5",
        "#2196f3", "#00bcd4", "#009688", "#4caf50", "#8bc34a", "#795548", "#607d8b"
    ]

    rightPadding: swatch.width + VLCStyle.dp(14, VLCStyle.scale)
    font.capitalization: Font.AllUppercase

    validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }

    Binding on text {
        when: !root.activeFocus
        value: root.colorValue.toUpperCase()
    }

    function _apply(value) {
        let v = value.trim()
        if (!v.startsWith("#"))
            v = "#" + v
        if (v.length === 4)  // #RGB
            v = "#" + v[1] + v[1] + v[2] + v[2] + v[3] + v[3]
        if (/^#[0-9a-fA-F]{6}$/.test(v) && v.toLowerCase() !== root.colorValue.toLowerCase())
            root.colorModified(v.toLowerCase())
    }

    onEditingFinished: _apply(text)

    T.AbstractButton {
        id: swatch

        anchors.right: parent.right
        anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)
        anchors.verticalCenter: parent.verticalCenter

        width: VLCStyle.dp(20, VLCStyle.scale)
        height: width

        focusPolicy: Qt.StrongFocus
        onClicked: palettePopup.open()

        background: Rectangle {
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: root.colorValue
            border.width: VLCStyle.border
            border.color: swatch.visualFocus ? root.colorContext.accent : root._c.controlBorder
        }

        Accessible.name: qsTr("Choose a color")
    }

    T.Popup {
        id: palettePopup

        x: root.width - width
        y: root.height + VLCStyle.dp(4, VLCStyle.scale)

        implicitWidth: implicitContentWidth + leftPadding + rightPadding
        implicitHeight: implicitContentHeight + topPadding + bottomPadding

        padding: VLCStyle.dp(8, VLCStyle.scale)

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: root._c.popup
            border.width: VLCStyle.border
            border.color: root._c.controlBorder
        }

        contentItem: GridLayout {
            columns: 7
            rowSpacing: VLCStyle.dp(6, VLCStyle.scale)
            columnSpacing: VLCStyle.dp(6, VLCStyle.scale)

            Repeater {
                model: root.swatches

                delegate: T.AbstractButton {
                    id: entry

                    required property string modelData

                    implicitWidth: VLCStyle.dp(22, VLCStyle.scale)
                    implicitHeight: implicitWidth

                    onClicked: {
                        root.colorModified(modelData)
                        palettePopup.close()
                    }

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: entry.modelData
                        border.width: entry.hovered || entry.modelData === root.colorValue.toLowerCase()
                                      ? VLCStyle.dp(2, VLCStyle.scale) : VLCStyle.border
                        border.color: entry.hovered || entry.modelData === root.colorValue.toLowerCase()
                                      ? root.colorContext.accent : root._c.controlBorder
                    }
                }
            }
        }
    }
}
