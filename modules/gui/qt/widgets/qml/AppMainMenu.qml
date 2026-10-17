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
import VLC.MediaLibrary
import VLC.Dialogs
import VLC.Style

// The "..." menu of the title bar: everything to open, the player profiles,
// the keyboard shortcuts, customizing the player and the settings, with
// their shortcuts.
PanelMenu {
    id: root

    menuWidth: VLCStyle.dp(375, VLCStyle.scale)

    function show(item) {
        model = _build()
        popupNextTo(item, false)
    }

    MLRecentMediaModel {
        id: recentModel

        ml: MainCtx.mediaLibraryAvailable ? MediaLib : null
        limit: 10
    }

    function _recent() {
        const entries = []
        if (!MainCtx.mediaLibraryAvailable)
            return entries
        const count = Math.min(10, recentModel.rowCount())
        for (let i = 0; i < count; ++i) {
            const index = recentModel.index(i, 0)
            const title = recentModel.data(index, MLMediaModel.MEDIA_TITLE)
            const id = recentModel.data(index, MLMediaModel.MEDIA_ID)
            entries.push({ text: title, icon: recentModel.data(index, MLMediaModel.MEDIA_IS_VIDEO) ? "video" : "music",
                           action: () => { MediaLib.addAndPlay(id); MainCtx.playerView = true } })
        }
        if (entries.length === 0)
            entries.push({ text: qsTr("Nothing played yet"), enabled: false })
        return entries
    }

    function _profiles() {
        const entries = []
        const profiles = MainCtx.controlbarProfileModel
        for (let i = 0; i < profiles.count; ++i) {
            const index = i
            entries.push({ text: profiles.getProfile(i).name,
                           checked: profiles.selectedProfile === i,
                           action: () => { profiles.selectedProfile = index } })
        }
        entries.push({ separator: true })
        // a copy of the current one, then arranged
        entries.push({ text: qsTr("New"), icon: "add", action: () => {
            profiles.cloneSelectedProfile(qsTr("Profile %1").arg(profiles.count + 1))
            profiles.selectedProfile = profiles.count - 1
            PlayerTweaks.requestDialog("customize")
        } })
        return entries
    }

    function _build() {
        const profiles = MainCtx.controlbarProfileModel
        const current = profiles.getProfile(profiles.selectedProfile)
        return [
            { text: qsTr("Open File(s)"), icon: "file", shortcut: "Ctrl + O", action: () => DialogsProvider.simpleOpenDialog() },
            { text: qsTr("Open Folder"), icon: "folder", shortcut: "Ctrl + F", action: () => DialogsProvider.PLOpenDir() },
            { text: qsTr("Open Network Stream"), icon: "link", shortcut: "Ctrl + N", action: () => PlayerTweaks.requestDialog("network") },
            { text: qsTr("Open Disc"), icon: "disc", shortcut: "Ctrl + D", action: () => DialogsProvider.openDiscDialog() },
            { text: qsTr("Open Capture Device"), icon: "capture", shortcut: "Ctrl + C", action: () => DialogsProvider.openCaptureDialog() },
            { text: qsTr("Convert"), icon: "convert", shortcut: "Ctrl + R", action: () => DialogsProvider.openAndTranscodingDialogs() },
            { separator: true },
            { text: qsTr("Open Recent"), icon: "recent", submenu: _recent() },
            { text: current ? qsTr("Profile (%1)").arg(current.name) : qsTr("Profile"), icon: "profile", submenu: _profiles() },
            { text: qsTr("Keyboard Shortcuts"), icon: "keyboard", action: () => PlayerTweaks.requestDialog("shortcuts") },
            { text: qsTr("Customize Player"), icon: "layout", action: () => PlayerTweaks.requestDialog("customize") },
            { separator: true },
            { text: qsTr("Settings"), icon: "preferences", shortcut: "Ctrl + P", action: () => PlayerTweaks.requestDialog("settings") },
            { text: qsTr("About VLC"), icon: "info", shortcut: "Shift + F1", action: () => DialogsProvider.aboutDialog() },
            { text: qsTr("Quit VLC"), icon: "quit", shortcut: "Ctrl + Q", action: () => DialogsProvider.quit() }
        ]
    }
}
