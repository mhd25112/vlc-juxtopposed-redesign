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


import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Util

// Shared behavior of the subtitle and audio buttons: both open the compact
// TracksPopup above the control bar, right-aligned with the button.
Widgets.SvgToolButton {
    id: root

    // Proprerties

    required property int page

    readonly property var _parentItem: {
        if ((typeof rootPlayer !== 'undefined') && (rootPlayer !== null))
            return rootPlayer
        else
            return g_mainDisplay
    }

    // Signals

    signal requestLockUnlockAutoHide(bool lock)
    signal menuOpened(var menu)

    // Settings

    enabled: popupLoader.status === Loader.Ready

    checked: popupLoader.item?.visible ?? false

    // Events

    onClicked: {
        const popup = popupLoader.item

        // The button toggles its popup. NOTE: Pressing the button while the
        // popup is open may close it (press outside) right before this
        // click, don't reopen it then.
        if (popup.visible || (Date.now() - popup.closedAt) < 250) {
            popup.close()
            return
        }

        const pos = root.mapToItem(popup.parent, root.width, 0)
        popup.x = Helpers.clamp(pos.x - popup.width, 0, Math.max(0, popup.parent.width - popup.width))

        popup.openPage(root.page)
    }

    // Children

    Loader {
        id: popupLoader

        active: !root.paintOnly

        sourceComponent: TracksPopup {
            id: popup

            property double closedAt: 0

            parent: root._parentItem

            y: (parent.positionSliderY - height - VLCStyle.margin_xsmall)
            z: 1

            colorContext.palette: root.colorContext.palette

            onOpened: {
                root.requestLockUnlockAutoHide(true)
                root.menuOpened(popup)
            }

            onClosed: {
                closedAt = Date.now()
                root.requestLockUnlockAutoHide(false)
                root.forceActiveFocus()
                root.menuOpened(null)
            }
        }
    }

    function forceUnlock() {
        // NOTE: Can be called while the control is being destroyed.
        if (popupLoader && popupLoader.item)
            popupLoader.item.close()
    }
}
