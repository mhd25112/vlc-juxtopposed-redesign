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

import VLC.Style

// Black input field of the redesigned panels.
//
// With "numeric" set, it edits "value": the field shows the value with its
// unit ("2.000 s", "18px") and accepts a plain number, the arrow keys and
// the mouse wheel step it.
T.TextField {
    id: control

    property bool numeric: false
    property real value: 0
    property real from: -1e9
    property real to: 1e9
    property real stepSize: 1
    property int decimals: 0
    property string unit: ""

    // emitted when the user changes a numeric value
    signal valueModified(real value)

    implicitWidth: VLCStyle.dp(128, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(30, VLCStyle.scale)

    leftPadding: VLCStyle.dp(10, VLCStyle.scale)
    rightPadding: VLCStyle.dp(10, VLCStyle.scale)
    verticalAlignment: TextInput.AlignVCenter

    selectByMouse: true

    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    color: _c.text
    selectionColor: theme.accent
    selectedTextColor: "white"
    placeholderTextColor: _c.dim

    background: Rectangle {
        radius: VLCStyle.dp(5, VLCStyle.scale)
        color: control._c.field
        border.width: VLCStyle.border
        border.color: control.activeFocus ? theme.accent : control._c.fieldBorder
    }

    // the template does not draw it
    Text {
        x: control.leftPadding
        y: control.topPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.height - control.topPadding - control.bottomPadding
        verticalAlignment: control.verticalAlignment
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        elide: Text.ElideRight
        visible: control.length === 0 && control.preeditText === ""
    }

    function _format(v) {
        return v.toFixed(control.decimals) + control.unit
    }

    function _commit(v) {
        v = Math.max(control.from, Math.min(control.to, v))
        if (isNaN(v))
            return
        if (v !== control.value)
            control.valueModified(v)
        control.text = control._format(control.value)
    }

    Binding on text {
        when: control.numeric && !control.activeFocus
        value: control._format(control.value)
    }

    onActiveFocusChanged: {
        if (numeric && activeFocus) {
            text = value.toFixed(decimals)
            selectAll()
        }
    }

    onEditingFinished: {
        if (numeric)
            _commit(parseFloat(text.replace(",", ".")))
    }

    Keys.onUpPressed: (event) => {
        if (!numeric) { event.accepted = false; return }
        _commit(value + stepSize)
        text = value.toFixed(decimals)
    }

    Keys.onDownPressed: (event) => {
        if (!numeric) { event.accepted = false; return }
        _commit(value - stepSize)
        text = value.toFixed(decimals)
    }

    WheelHandler {
        enabled: control.numeric && control.hovered
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            control._commit(control.value + (event.angleDelta.y > 0 ? control.stepSize : -control.stepSize))
        }
    }
}
