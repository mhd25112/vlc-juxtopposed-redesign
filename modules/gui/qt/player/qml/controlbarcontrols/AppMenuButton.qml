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

// the main menu of the redesign ("..."): open media, recent, profiles...
Widgets.SvgToolButton {
    id: root

    signal requestLockUnlockAutoHide(bool lock)

    iconName: "more"
    description: qsTr("Menu")
    checked: mainMenu.visible
    onClicked: mainMenu.show(root)

    function forceUnlock() {
        if (mainMenu)
            mainMenu.close()
    }

    Widgets.AppMainMenu {
        id: mainMenu
        onOpened: root.requestLockUnlockAutoHide(true)
        onClosed: root.requestLockUnlockAutoHide(false)
    }
}
