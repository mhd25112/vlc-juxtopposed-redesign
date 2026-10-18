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

// "HDR": how HDR videos are shown (Direct3D 11 output)
Widgets.SvgToolButton {
    id: root

    signal requestLockUnlockAutoHide(bool lock)

    iconName: "hdr"
    description: qsTr("HDR")
    enabled: !paintOnly && (PlayerTweaks.optionExists("d3d11-hdr-mode"))
    checked: menu.visible || (false)

    onClicked: {
        menu.model = root.entries()
        menu.popupFrom(root)
    }

    function entries() {
        const current = PlayerTweaks.option("d3d11-hdr-mode")
        return PlayerTweaks.optionChoices("d3d11-hdr-mode").map((c) => ({
            text: c.text,
            checked: c.value === current,
            action: () => PlayerTweaks.setOption("d3d11-hdr-mode", c.value)
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
