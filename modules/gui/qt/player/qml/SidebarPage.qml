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
import QtQuick.Templates as T

import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets

// Scrolling content of a tab of the player sidebar.
Flickable {
    id: root

    default property alias content: column.data

    // incremented whenever a setting may have changed: bindings that read a
    // setting through a function refer to it so that they are refreshed
    readonly property int rev: PlayerTweaks.revision

    // an on/off setting of the interface
    function uiFlag(name, defaultValue = false) {
        root.rev
        return String(PlayerTweaks.uiOption(name, defaultValue)) === "true"
    }

    // a setting read through a function of PlayerTweaks, refreshed with "rev"
    function read(getter, name) {
        root.rev
        return getter(name)
    }

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + VLCStyle.dp(12, VLCStyle.scale)
    boundsBehavior: Flickable.StopAtBounds

    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

    ColumnLayout {
        id: column

        width: root.width
        spacing: 0
    }
}
