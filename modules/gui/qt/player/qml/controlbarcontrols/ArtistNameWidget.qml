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

import VLC.MainInterface
import VLC.Player
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util
import QtQuick.Layouts

// "Artist Name": the artist of what plays
Item {
    id: root

    property bool paintOnly: false
    property int focusReason: Qt.OtherFocusReason

    readonly property string _text: Player.artist
    readonly property string _shown: _text !== "" ? _text : (paintOnly ? qsTr("Artist Name") : "")

    // shrinks with the window: the name is cut
    Layout.minimumWidth: _shown !== "" ? VLCStyle.dp(48, VLCStyle.scale) : 0

    // the icon and the whole name (not the row: its width comes from ours)
    readonly property real _contentWidth: VLCStyle.dp(26, VLCStyle.scale) + label.implicitWidth

    implicitWidth: _shown !== "" ? Math.min(_contentWidth + VLCStyle.dp(16, VLCStyle.scale), VLCStyle.dp(420, VLCStyle.scale)) : 0
    implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
    visible: _shown !== ""

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    Row {
        id: row

        anchors.centerIn: parent
        width: Math.max(0, Math.min(root._contentWidth, root.width - VLCStyle.dp(16, VLCStyle.scale)))
        spacing: VLCStyle.dp(8, VLCStyle.scale)

            Widgets.PanelIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "artist"
                size: VLCStyle.dp(18, VLCStyle.scale)
                color: root._c.label
            }

        Text {
            id: label

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(implicitWidth, row.width - VLCStyle.dp(26, VLCStyle.scale)))
            text: root._shown
            elide: Text.ElideRight
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root._c.text
        }
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: _shown
}
