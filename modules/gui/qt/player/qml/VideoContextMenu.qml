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
import VLC.Dialogs
import VLC.Style
import VLC.Widgets as Widgets

// Right click on the video: the usual actions with their keys first, then
// the settings by kind, in the menu style of the redesign.
Widgets.PanelMenu {
    id: root

    menuWidth: VLCStyle.dp(292, VLCStyle.scale)

    function show() {
        model = _build()
        popup(MainCtx.cursorPosition())
    }

    // entries of a model with a check state, selecting one on click
    function _choices(listModel, empty) {
        const entries = PlayerTweaks.modelEntries(listModel)
        if (entries.length === 0)
            return [{ text: empty ?? qsTr("Nothing to choose"), enabled: false }]
        return entries.map((e, i) => ({ text: e.text, checked: e.checked,
                                       action: () => PlayerTweaks.checkModelEntry(listModel, i) }))
    }

    function _speeds() {
        return [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map((rate) => ({
            text: rate === 1 ? qsTr("Normal") : rate + "x",
            checked: Math.abs(Player.rate - rate) < 0.01,
            action: () => { Player.rate = rate }
        }))
    }

    function _key(option) {
        const key = String(PlayerTweaks.option(option) ?? "")
        return key.split("+").map((part) => part.length === 1 ? part.toUpperCase() : part).join(" + ")
    }

    function _build() {
        const playing = Player.playingState === Player.PLAYING_STATE_PLAYING
        return [
            { text: playing ? qsTr("Pause") : qsTr("Play"), icon: playing ? "pause" : "play_filled",
              shortcut: _key("key-play-pause"), action: () => MainPlaylistController.togglePlayPause() },
            { text: qsTr("Stop"), icon: "stop", shortcut: _key("key-stop"), action: () => MainPlaylistController.stop() },
            { text: qsTr("Previous Item"), icon: "previous", shortcut: _key("key-prev"), action: () => MainPlaylistController.prev() },
            { text: qsTr("Next Item"), icon: "next", shortcut: _key("key-next"), action: () => MainPlaylistController.next() },
            { text: Player.recording ? qsTr("Stop Recording") : qsTr("Record"), icon: "record",
              shortcut: _key("key-record"), action: () => Player.toggleRecord() },
            { text: qsTr("Hide UI"), icon: "eye_off", shortcut: "Ctrl + H", action: () => { MainCtx.minimalView = !MainCtx.minimalView } },
            { separator: true },
            { text: qsTr("Playback"), icon: "playback", submenu: [
                { text: qsTr("Speed"), icon: "speed", submenu: _speeds() },
                { text: qsTr("Jump Forward"), icon: PanelStyle.skipIcon(true, PlayerTweaks.option("short-jump-size")), action: () => Player.jumpFwd() },
                { text: qsTr("Jump Backward"), icon: PanelStyle.skipIcon(false, PlayerTweaks.option("short-jump-size")), action: () => Player.jumpBwd() },
                { text: qsTr("Jump to Specific Time"), icon: "timer", shortcut: "Ctrl + T", action: () => DialogsProvider.gotoTimeDialog() },
                { text: qsTr("A to B Loop"), icon: "repeat", action: () => Player.toggleABloopState() },
                { text: qsTr("Add a Bookmark"), icon: "bookmark", shortcut: "Ctrl + B", action: () => PlayerTweaks.requestDialog("bookmark") },
                { text: qsTr("Chapter"), icon: "chapters", submenu: _choices(Player.chapters, qsTr("No chapters")) },
                { text: qsTr("Program"), icon: "stream", submenu: _choices(Player.programs, qsTr("No programs")) } ] },
            { text: qsTr("Video"), icon: "video", submenu: [
                { text: qsTr("Fullscreen"), icon: "fullscreen", checked: Player.fullscreen, shortcut: _key("key-toggle-fullscreen"),
                  action: () => { Player.fullscreen = !Player.fullscreen } },
                { text: qsTr("Video Track"), icon: "video", submenu: _choices(Player.videoTracks) },
                { text: qsTr("Aspect Ratio"), icon: "layout", submenu: _choices(Player.aspectRatio) },
                { text: qsTr("Crop"), icon: "layout", submenu: _choices(Player.crop) },
                { text: qsTr("Zoom"), icon: "search", submenu: _choices(Player.zoom) },
                { text: qsTr("Deinterlace"), icon: "sliders", submenu: _choices(Player.deinterlace) },
                { text: qsTr("Take a Snapshot"), icon: "capture", shortcut: _key("key-snapshot"), action: () => Player.snapshot() } ] },
            { text: qsTr("Audio"), icon: "audio", submenu: [
                { text: qsTr("Audio Track"), icon: "audio", submenu: _choices(Player.audioTracks) },
                { text: qsTr("Output Device"), icon: "volume", submenu: _choices(Player.audioDevices) },
                { text: qsTr("Stereo Mode"), icon: "audio", submenu: _choices(Player.audioStereoMode) },
                { text: qsTr("Visualization"), icon: "visualizer", submenu: _choices(Player.audioVisualization) },
                { text: Player.muted ? qsTr("Unmute") : qsTr("Mute"), icon: "volume_muted", shortcut: _key("key-vol-mute"),
                  action: () => Player.toggleMuted() } ] },
            { text: qsTr("Subtitle"), icon: "subtitles", submenu: _choices(Player.subtitleTracks, qsTr("No subtitles")).concat([
                { separator: true },
                { text: qsTr("Add Subtitles..."), icon: "add", action: () => PlayerTweaks.requestDialog("subtitles") },
                { text: qsTr("Subtitle Settings"), icon: "sliders", action: () => PlayerTweaks.toggleSidebar(3) } ]) },
            { text: qsTr("More Settings"), icon: "settings", submenu: [
                { text: qsTr("Playback Settings"), icon: "playback", action: () => PlayerTweaks.toggleSidebar(0) },
                { text: qsTr("Video Settings"), icon: "video", action: () => PlayerTweaks.toggleSidebar(1) },
                { text: qsTr("Audio Settings"), icon: "audio", action: () => PlayerTweaks.toggleSidebar(2) },
                { text: qsTr("Subtitle Settings"), icon: "subtitles", action: () => PlayerTweaks.toggleSidebar(3) },
                { separator: true },
                { text: qsTr("Media Information"), icon: "info", shortcut: "Ctrl + I", action: () => DialogsProvider.mediaInfoDialog() },
                { text: qsTr("All Settings"), icon: "preferences", shortcut: "Ctrl + P", action: () => PlayerTweaks.requestDialog("settings") } ] },
            { text: qsTr("Playlist"), icon: "queue", submenu: [
                { text: qsTr("Show the Queue"), icon: "queue", checked: MainCtx.playqueuePanel.visible,
                  action: () => { MainCtx.playqueuePanel.visible = !MainCtx.playqueuePanel.visible } },
                { text: qsTr("Shuffle"), icon: "shuffle", checked: MainPlaylistController.random,
                  action: () => { MainPlaylistController.random = !MainPlaylistController.random } },
                { text: qsTr("Repeat All"), icon: "repeat", checked: MainPlaylistController.repeatMode === PlaylistController.PLAYBACK_REPEAT_ALL,
                  action: () => { MainPlaylistController.repeatMode = (MainPlaylistController.repeatMode === PlaylistController.PLAYBACK_REPEAT_ALL)
                                    ? PlaylistController.PLAYBACK_REPEAT_NONE : PlaylistController.PLAYBACK_REPEAT_ALL } },
                { text: qsTr("Repeat One"), icon: "repeat", checked: MainPlaylistController.repeatMode === PlaylistController.PLAYBACK_REPEAT_CURRENT,
                  action: () => { MainPlaylistController.repeatMode = (MainPlaylistController.repeatMode === PlaylistController.PLAYBACK_REPEAT_CURRENT)
                                    ? PlaylistController.PLAYBACK_REPEAT_NONE : PlaylistController.PLAYBACK_REPEAT_CURRENT } },
                { text: qsTr("Clear the Queue"), icon: "trash", action: () => MainPlaylistController.clear() } ] },
            { text: qsTr("Open Media"), icon: "folder_open", submenu: [
                { text: qsTr("Open File(s)"), icon: "file", shortcut: "Ctrl + O", action: () => DialogsProvider.simpleOpenDialog() },
                { text: qsTr("Open Folder"), icon: "folder", shortcut: "Ctrl + F", action: () => DialogsProvider.PLOpenDir() },
                { text: qsTr("Open Network Stream"), icon: "link", shortcut: "Ctrl + N", action: () => PlayerTweaks.requestDialog("network") },
                { text: qsTr("Open Disc"), icon: "disc", shortcut: "Ctrl + D", action: () => DialogsProvider.openDiscDialog() },
                { text: qsTr("Open Capture Device"), icon: "capture", action: () => DialogsProvider.openCaptureDialog() } ] },
            { separator: true },
            { text: qsTr("Quit VLC"), icon: "quit", shortcut: "Ctrl + Q", action: () => DialogsProvider.quit() }
        ]
    }
}
