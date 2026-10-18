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

// "Chapters": the chapters of what plays, to jump to one
Widgets.SvgToolButton {
    id: root

    signal requestLockUnlockAutoHide(bool lock)

    iconName: "chapters"
    description: qsTr("Chapters")
    enabled: !paintOnly && (Player.hasChapters)
    checked: menu.visible || (false)

    onClicked: {
        menu.model = root.entries()
        menu.popupFrom(root)
    }

    function entries() {
        return PlayerTweaks.modelEntries(Player.chapters).map((e, index) => ({
            text: e.text !== "" ? e.text : qsTr("Chapter %1").arg(index + 1),
            checked: e.checked,
            action: () => Player.chapters.selectChapter(index)
        }))
    }

    function forceUnlock() {
        if (menu)
            menu.close()
    }

    Widgets.PanelMenu {
        id: menu
        menuWidth: VLCStyle.dp(240, VLCStyle.scale)
        onOpened: root.requestLockUnlockAutoHide(true)
        onClosed: root.requestLockUnlockAutoHide(false)
    }
}
