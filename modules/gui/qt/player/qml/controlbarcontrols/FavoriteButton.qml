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

// "Favorite": marks what plays as a favorite of the library
Widgets.SvgToolButton {
    enabled: Player.isStarted && MainCtx.mediaLibraryAvailable
    iconName: PlayerTweaks.favorite ? "heart_filled" : "heart"
    checked: PlayerTweaks.favorite
    description: PlayerTweaks.favorite ? qsTr("Remove from Favorites") : qsTr("Favorite")
    onClicked: PlayerTweaks.toggleFavorite()
}
