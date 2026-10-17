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

import VLC.MainInterface
import VLC.Style

// One of the accent colors: "default" (VLC orange) or "#RRGGBB". Picking it
// recolors the whole interface right away.
T.AbstractButton {
    id: root

    property string value: "default"

    readonly property bool current: MainCtx.accentColor.toLowerCase() === value.toLowerCase()
    readonly property color swatch: value === "default" ? "#D37918" : value

    implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
    implicitHeight: implicitWidth

    focusPolicy: Qt.StrongFocus

    onClicked: MainCtx.accentColor = value

    background: Rectangle {
        radius: VLCStyle.dp(8, VLCStyle.scale)
        color: "transparent"
        border.width: root.current || root.visualFocus ? VLCStyle.dp(2, VLCStyle.scale)
                                                       : (root.hovered ? VLCStyle.border : 0)
        border.color: root.current ? root.swatch : PanelStyle.dark.separatorBright

        Rectangle {
            anchors.fill: parent
            anchors.margins: VLCStyle.dp(5, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: root.swatch
        }
    }

    Accessible.name: value === "default" ? qsTr("VLC orange") : value
    Accessible.checked: current
}
