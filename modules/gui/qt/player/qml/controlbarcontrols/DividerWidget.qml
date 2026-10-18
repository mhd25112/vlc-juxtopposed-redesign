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

// "Divider" of "Customize Player": a thin line between controls
Item {
    id: root

    property bool paintOnly: false
    property int focusReason: Qt.OtherFocusReason

    enabled: false
    implicitWidth: VLCStyle.dp(9, VLCStyle.scale)
    implicitHeight: VLCStyle.icon_toolbar

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Rectangle {
        anchors.centerIn: parent
        width: VLCStyle.border
        height: VLCStyle.dp(18, VLCStyle.scale)
        color: PanelStyle.colors(theme.palette?.isDark ?? true).separatorBright
    }
}
