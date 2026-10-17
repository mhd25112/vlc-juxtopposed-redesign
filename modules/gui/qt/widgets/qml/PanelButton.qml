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

// Button of the redesigned panels.
//  - default: a grey button
//  - accent: accent text on a dark accent background ("Test", "Save")
//  - flat: text and icon only ("Open Advanced Settings")
T.AbstractButton {
    id: control

    property string iconName
    property bool accent: false
    property bool flat: false

    implicitWidth: content.implicitWidth + leftPadding + rightPadding
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

    leftPadding: flat ? VLCStyle.dp(6, VLCStyle.scale) : VLCStyle.dp(14, VLCStyle.scale)
    rightPadding: leftPadding

    focusPolicy: Qt.StrongFocus

    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    readonly property color _fg: {
        if (!control.enabled)
            return _c.dim
        if (control.accent)
            return theme.accent
        if (control.flat)
            return control.hovered ? _c.text : _c.label
        return _c.text
    }

    background: Rectangle {
        radius: VLCStyle.dp(5, VLCStyle.scale)
        visible: !control.flat || control.visualFocus
        color: {
            if (control.flat)
                return "transparent"
            if (control.accent)
                return control.hovered ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4)
                                       : PanelStyle.accentFill(theme.accent, (theme.palette?.isDark ?? true))
            return control.hovered ? control._c.hover : control._c.control
        }
        border.width: control.visualFocus || (!control.flat && !control.accent) ? VLCStyle.border : 0
        border.color: control.visualFocus ? theme.accent : control._c.controlBorder
    }

    contentItem: Item {
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        RowLayout {
            id: content

            anchors.centerIn: parent
            spacing: VLCStyle.dp(8, VLCStyle.scale)

            PanelIcon {
                visible: control.iconName !== ""
                name: control.iconName
                size: VLCStyle.dp(16, VLCStyle.scale)
                color: control._fg
            }

            Text {
                visible: control.text !== ""
                text: control.text
                font: control.font
                color: control._fg
            }
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: text
}
