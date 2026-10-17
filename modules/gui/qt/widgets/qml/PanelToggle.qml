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

// On/off switch of the redesigned panels: a square knob next to its state.
T.AbstractButton {
    id: control

    // "checked" stays bound to the setting, clicks only ask for a change
    signal switched(bool on)

    onClicked: switched(!checked)

    implicitWidth: VLCStyle.dp(62, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

    focusPolicy: Qt.StrongFocus

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    background: Rectangle {
        radius: VLCStyle.dp(5, VLCStyle.scale)
        color: control.checked ? PanelStyle.accentFill(theme.accent, (theme.palette?.isDark ?? true)) : control._c.field
        border.width: VLCStyle.border
        border.color: control.visualFocus ? theme.accent : control._c.fieldBorder
    }

    contentItem: Item {
        Rectangle {
            id: knob

            readonly property real inset: VLCStyle.dp(3, VLCStyle.scale)

            width: height
            height: parent.height - inset * 2
            y: inset
            x: control.checked ? parent.width - width - inset : inset
            radius: VLCStyle.dp(3, VLCStyle.scale)

            color: control.checked ? theme.accent : (control.hovered ? Qt.lighter(control._c.knob, 1.2) : control._c.knob)

            Behavior on x {
                NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.OutSine }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: control.checked ? knob.inset * 2 : knob.x + knob.width
            width: parent.width - knob.width - knob.inset * 2

            horizontalAlignment: Text.AlignHCenter
            text: control.checked ? qsTr("ON") : qsTr("OFF")
            font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
            font.weight: Font.Medium
            color: control.checked ? theme.accent : control._c.label
        }
    }

    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
}
