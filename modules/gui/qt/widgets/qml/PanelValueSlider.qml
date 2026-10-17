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
import QtQuick.Layouts

import VLC.Style

// A named value with a slider under it: "Attack        25.0 ms".
// With "editable", the value is an input field instead of a text.
ColumnLayout {
    id: root

    property string text
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property int decimals: 1
    property string unit: ""
    property bool editable: false
    property real origin: from

    signal moved(real value)

    Layout.fillWidth: true
    spacing: VLCStyle.dp(6, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.dp(4, VLCStyle.scale)

        Text {
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root._c.label
            elide: Text.ElideRight
        }

        Text {
            visible: !root.editable
            text: (slider.pressed ? slider.value : root.value).toFixed(root.decimals) + root.unit
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root._c.label
        }

        PanelTextField {
            visible: root.editable
            implicitWidth: VLCStyle.dp(110, VLCStyle.scale)
            numeric: true
            value: root.value
            from: root.from
            to: root.to
            stepSize: root.stepSize
            decimals: root.decimals
            unit: root.unit
            onValueModified: (value) => root.moved(value)
        }
    }

    PanelSlider {
        id: slider

        Layout.fillWidth: true

        from: root.from
        to: root.to
        stepSize: root.stepSize
        origin: root.origin
        boundValue: root.value

        onMoved: root.moved(Number(value.toFixed(root.decimals)))
    }
}
