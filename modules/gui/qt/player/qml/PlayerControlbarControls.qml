/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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

pragma Singleton

import QtQml


import VLC.MainInterface
import VLC.PlayerControls
import VLC.Widgets as Widgets
import VLC.Style

QtObject {
    readonly property string controlPath : "qrc:///qt/qml/VLC/PlayerControls/"

    readonly property var controlList: [
        { id: ControlListModel.PLAY_BUTTON, file: "PlayButton.qml", label: VLCIcons.play_filled, text: qsTr("Play") },
        { id: ControlListModel.STOP_BUTTON, file: "StopButton.qml", label: VLCIcons.stop, text: qsTr("Stop") },
        { id: ControlListModel.OPEN_BUTTON, file: "OpenButton.qml", label: VLCIcons.eject, text: qsTr("Open") },
        { id: ControlListModel.PREVIOUS_BUTTON, file: "PreviousButton.qml", label: VLCIcons.previous, text: qsTr("Previous") },
        { id: ControlListModel.NEXT_BUTTON, file: "NextButton.qml", label: VLCIcons.next, text: qsTr("Next") },
        { id: ControlListModel.SLOWER_BUTTON, file: "SlowerButton.qml", label: VLCIcons.slower, text: qsTr("Slower") },
        { id: ControlListModel.FASTER_BUTTON, file: "FasterButton.qml", label: VLCIcons.faster, text: qsTr("Faster") },
        { id: ControlListModel.FULLSCREEN_BUTTON, file: "FullscreenButton.qml", label: VLCIcons.fullscreen, text: qsTr("Fullscreen") },
        { id: ControlListModel.EXTENDED_BUTTON, file: "ExtendedSettingsButton.qml", label: VLCIcons.effect_filter, text: qsTr("Extended panel") },
        { id: ControlListModel.PLAYLIST_BUTTON, file: "PlaylistButton.qml", label: VLCIcons.playlist, text: qsTr("Play Queue") },
        { id: ControlListModel.SNAPSHOT_BUTTON, file: "SnapshotButton.qml", label: VLCIcons.snapshot, text: qsTr("Snapshot") },
        { id: ControlListModel.RECORD_BUTTON, file: "RecordButton.qml", label: VLCIcons.record, text: qsTr("Record") },
        { id: ControlListModel.ATOB_BUTTON, file: "AtoBButton.qml", label: VLCIcons.atob, text: qsTr("A-B Loop") },
        { id: ControlListModel.FRAME_PREV_BUTTON, file: "FrameNextButton.qml", label: VLCIcons.next_frame, text: qsTr("Next Frame") },
        { id: ControlListModel.FRAME_NEXT_BUTTON, file: "FramePrevButton.qml", label: VLCIcons.previous_frame, text: qsTr("Previous Frame") },
        { id: ControlListModel.REVERSE_BUTTON, file: "ReverseButton.qml", label: VLCIcons.play_reverse, text: qsTr("Trickplay Reverse") },
        { id: ControlListModel.SKIP_BACK_BUTTON, file: "SkipBackButton.qml", label: VLCIcons.skip_back, text: qsTr("Step backward") },
        { id: ControlListModel.SKIP_FW_BUTTON, file: "SkipForwardButton.qml", label: VLCIcons.skip_for, text: qsTr("Step forward") },
        { id: ControlListModel.QUIT_BUTTON, file: "QuitButton.qml", label: VLCIcons.clear, text: qsTr("Quit") },
        { id: ControlListModel.RANDOM_BUTTON, file: "RandomButton.qml", label: VLCIcons.shuffle, text: qsTr("Random") },
        { id: ControlListModel.LOOP_BUTTON, file: "LoopButton.qml", label: VLCIcons.repeat_all, text: qsTr("Loop") },
        { id: ControlListModel.INFO_BUTTON, file: "InfoButton.qml", label: VLCIcons.info, text: qsTr("Information") },
        { id: ControlListModel.LANG_BUTTON, file: "LangButton.qml", label: VLCIcons.audiosub, text: qsTr("Open subtitles") },
        { id: ControlListModel.SUBTITLE_BUTTON, file: "SubtitleButton.qml", label: VLCIcons.audiosub, text: qsTr("Subtitles") },
        { id: ControlListModel.AUDIO_TRACK_BUTTON, file: "AudioTrackButton.qml", label: VLCIcons.topbar_music, text: qsTr("Audio tracks and output") },
        { id: ControlListModel.BOOKMARK_BUTTON, file: "BookmarkButton.qml", label: VLCIcons.bookmark, text: qsTr("Bookmark Button") },
        { id: ControlListModel.CHAPTER_PREVIOUS_BUTTON, file: "ChapterPreviousButton.qml", label: VLCIcons.dvd_prev, text: qsTr("Previous chapter") },
        { id: ControlListModel.CHAPTER_NEXT_BUTTON, file: "ChapterNextButton.qml", label: VLCIcons.dvd_next, text: qsTr("Next chapter") },
        { id: ControlListModel.VOLUME, file: "VolumeWidget.qml", label: VLCIcons.volume_high, text: qsTr("Volume Widget") },
        { id: ControlListModel.NAVIGATION_BOX, file: "NavigationBoxButton.qml", label: VLCIcons.ic_fluent_arrow_move, text: qsTr("Navigation Box") },
        { id: ControlListModel.NAVIGATION_BUTTONS, file: "NavigationWidget.qml", label: VLCIcons.dvd_menu, text: qsTr("Navigation") },
        { id: ControlListModel.DVD_MENUS_BUTTON, file: "DvdMenuButton.qml", label: VLCIcons.dvd_menu, text: qsTr("DVD menus") },
        { id: ControlListModel.PROGRAM_BUTTON, file: "ProgramButton.qml", label: VLCIcons.tv, text: qsTr("Program Button") },
        { id: ControlListModel.TELETEXT_BUTTONS, file: "TeletextButton.qml", label: VLCIcons.tvtelx, text: qsTr("Teletext") },
        { id: ControlListModel.RENDERER_BUTTON, file: "RendererButton.qml", label: VLCIcons.renderer, text: qsTr("Renderer Button") },
        { id: ControlListModel.ASPECT_RATIO_COMBOBOX, file: "AspectRatioWidget.qml", label: VLCIcons.aspect_ratio, text: qsTr("Aspect Ratio") },
        { id: ControlListModel.WIDGET_SPACER, file: "SpacerWidget.qml", label: VLCIcons.space, text: qsTr("Spacer") },
        { id: ControlListModel.WIDGET_SPACER_EXTEND, file: "ExpandingSpacerWidget.qml", label: VLCIcons.space, text: qsTr("Expanding Spacer") },
        { id: ControlListModel.PLAYER_SWITCH_BUTTON, file: "PlayerSwitchButton.qml", label: VLCIcons.fullscreen, text: qsTr("Switch Player") },
        { id: ControlListModel.ARTWORK_INFO, file: "ArtworkInfoWidget.qml", label: VLCIcons.info, text: qsTr("Artwork Info") },
        { id: ControlListModel.PLAYBACK_SPEED_BUTTON, file: "PlaybackSpeedButton.qml", label: "1x", text: qsTr("Playback Speed") },
        { id: ControlListModel.HIGH_RESOLUTION_TIME_WIDGET, file: "HighResolutionTimeWidget.qml", label: VLCIcons.time, text: qsTr("High Resolution Time") },
        { id: ControlListModel.DIVIDER_WIDGET, file: "DividerWidget.qml", label: VLCIcons.space, text: qsTr("Divider") },
        { id: ControlListModel.FORWARD_10_BUTTON, file: "Forward10Button.qml", label: VLCIcons.skip_for, text: qsTr("Forward 10s") },
        { id: ControlListModel.BACKWARD_10_BUTTON, file: "Backward10Button.qml", label: VLCIcons.skip_back, text: qsTr("Backward 10s") },
        { id: ControlListModel.FORWARD_15_BUTTON, file: "Forward15Button.qml", label: VLCIcons.skip_for, text: qsTr("Forward 15s") },
        { id: ControlListModel.BACKWARD_15_BUTTON, file: "Backward15Button.qml", label: VLCIcons.skip_back, text: qsTr("Backward 15s") },
        { id: ControlListModel.PIP_BUTTON, file: "PipButton.qml", label: VLCIcons.fullscreen, text: qsTr("Picture in Picture") },
        { id: ControlListModel.HDR_BUTTON, file: "HdrButton.qml", label: VLCIcons.tv, text: qsTr("HDR") },
        { id: ControlListModel.ZOOM_BUTTON, file: "ZoomButton.qml", label: VLCIcons.aspect_ratio, text: qsTr("Zoom") },
        { id: ControlListModel.SIDEBAR_BUTTON, file: "SidebarButton.qml", label: VLCIcons.effect_filter, text: qsTr("Right Sidebar") },
        { id: ControlListModel.SETTINGS_BUTTON, file: "SettingsButton.qml", label: VLCIcons.effect_filter, text: qsTr("VLC Settings") },
        { id: ControlListModel.HOME_BUTTON, file: "HomeButton.qml", label: VLCIcons.home, text: qsTr("Go Home") },
        { id: ControlListModel.THUMBNAIL_WIDGET, file: "ThumbnailWidget.qml", label: VLCIcons.info, text: qsTr("Thumbnail") },
        { id: ControlListModel.FILE_NAME_WIDGET, file: "FileNameWidget.qml", label: VLCIcons.info, text: qsTr("File Name") },
        { id: ControlListModel.ARTIST_NAME_WIDGET, file: "ArtistNameWidget.qml", label: VLCIcons.info, text: qsTr("Artist Name") },
        { id: ControlListModel.FOLDER_NAME_WIDGET, file: "FolderNameWidget.qml", label: VLCIcons.info, text: qsTr("Folder Name") },
        { id: ControlListModel.PLAYLIST_NAME_WIDGET, file: "PlaylistNameWidget.qml", label: VLCIcons.info, text: qsTr("Playlist Name") },
        { id: ControlListModel.REPLAY_BUTTON, file: "ReplayButton.qml", label: VLCIcons.repeat_one, text: qsTr("Replay") },
        { id: ControlListModel.CHAPTERS_BUTTON, file: "ChaptersButton.qml", label: VLCIcons.dvd_next, text: qsTr("Chapters") },
        { id: ControlListModel.FAVORITE_BUTTON, file: "FavoriteButton.qml", label: VLCIcons.info, text: qsTr("Favorite") },
        { id: ControlListModel.ADD_BOOKMARK_BUTTON, file: "AddBookmarkButton.qml", label: VLCIcons.bookmark, text: qsTr("Bookmark") },
        { id: ControlListModel.PLAYLISTS_BUTTON, file: "PlaylistsButton.qml", label: VLCIcons.playlist, text: qsTr("Playlists") },
        { id: ControlListModel.APP_MENU_BUTTON, file: "AppMenuButton.qml", label: VLCIcons.more, text: qsTr("Menu") },
        { id: ControlListModel.LIBRARY_BUTTON, file: "LibraryButton.qml", label: VLCIcons.playlist, text: qsTr("Library") }
    ]

    function control(id) {
        const entry = controlList.find( function(e) { return ( e.id === id ) } )

        if (entry === undefined) {
            console.warn("control delegate id " + id +  " doesn't exist")
            return { source: controlPath + "Fallback.qml" }
        }

        entry.source = controlPath + entry.file

        return entry
    }

    // the controls offered by "Customize Player", in its order, with the
    // names and icons of the redesign: the items of the design, then those
    // of the default bars (listed once taken out of them)
    readonly property var customizeList: [
        { id: ControlListModel.WIDGET_SPACER_EXTEND, text: qsTr("Spacer"), icon: "" },
        { id: ControlListModel.DIVIDER_WIDGET, text: qsTr("Divider"), icon: "" },
        { id: ControlListModel.PLAYBACK_SPEED_BUTTON, text: qsTr("Playback Speed"), icon: "speed" },
        { id: ControlListModel.FORWARD_10_BUTTON, text: qsTr("Forward 10s"), icon: "forward_10" },
        { id: ControlListModel.BACKWARD_10_BUTTON, text: qsTr("Backward 10s"), icon: "backward_10" },
        { id: ControlListModel.FORWARD_15_BUTTON, text: qsTr("Forward 15s"), icon: "forward_15" },
        { id: ControlListModel.BACKWARD_15_BUTTON, text: qsTr("Backward 15s"), icon: "backward_15" },
        { id: ControlListModel.STOP_BUTTON, text: qsTr("Stop"), icon: "stop" },
        { id: ControlListModel.LOOP_BUTTON, text: qsTr("Repeat"), icon: "repeat" },
        { id: ControlListModel.RANDOM_BUTTON, text: qsTr("Shuffle"), icon: "shuffle" },
        { id: ControlListModel.RECORD_BUTTON, text: qsTr("Record"), icon: "record" },
        { id: ControlListModel.SNAPSHOT_BUTTON, text: qsTr("Snapshot"), icon: "snapshot" },
        { id: ControlListModel.PIP_BUTTON, text: qsTr("Picture in Picture"), icon: "pip" },
        { id: ControlListModel.HDR_BUTTON, text: qsTr("HDR"), icon: "hdr" },
        { id: ControlListModel.ZOOM_BUTTON, text: qsTr("Zoom"), icon: "zoom" },
        { id: ControlListModel.SIDEBAR_BUTTON, text: qsTr("Right Sidebar"), icon: "sidebar_right" },
        { id: ControlListModel.QUIT_BUTTON, text: qsTr("Quit VLC"), icon: "quit" },
        { id: ControlListModel.SETTINGS_BUTTON, text: qsTr("VLC Settings"), icon: "preferences" },
        { id: ControlListModel.HOME_BUTTON, text: qsTr("Go Home"), icon: "home" },
        { id: ControlListModel.THUMBNAIL_WIDGET, text: qsTr("Thumbnail"), icon: "" },
        { id: ControlListModel.FILE_NAME_WIDGET, text: qsTr("File Name"), icon: "info" },
        { id: ControlListModel.ARTIST_NAME_WIDGET, text: qsTr("Artist Name"), icon: "info" },
        { id: ControlListModel.FOLDER_NAME_WIDGET, text: qsTr("Folder Name"), icon: "info" },
        { id: ControlListModel.PLAYLIST_NAME_WIDGET, text: qsTr("Playlist Name"), icon: "info" },
        { id: ControlListModel.INFO_BUTTON, text: qsTr("Properties"), icon: "info" },
        { id: ControlListModel.REPLAY_BUTTON, text: qsTr("Replay"), icon: "replay" },
        { id: ControlListModel.CHAPTERS_BUTTON, text: qsTr("Chapters"), icon: "chapters" },
        { id: ControlListModel.FAVORITE_BUTTON, text: qsTr("Favorite"), icon: "heart" },
        { id: ControlListModel.ADD_BOOKMARK_BUTTON, text: qsTr("Bookmark"), icon: "bookmark_add" },
        { id: ControlListModel.BOOKMARK_BUTTON, text: qsTr("Bookmarks"), icon: "bookmark" },
        { id: ControlListModel.PLAYLISTS_BUTTON, text: qsTr("Playlists"), icon: "playlists" },

        { id: ControlListModel.PREVIOUS_BUTTON, text: qsTr("Previous"), icon: "previous" },
        { id: ControlListModel.PLAY_BUTTON, text: qsTr("Play"), icon: "play_filled" },
        { id: ControlListModel.NEXT_BUTTON, text: qsTr("Next"), icon: "next" },
        { id: ControlListModel.VOLUME, text: qsTr("Volume"), icon: "volume" },
        { id: ControlListModel.AUDIO_TRACK_BUTTON, text: qsTr("Audio"), icon: "visualizer" },
        { id: ControlListModel.SUBTITLE_BUTTON, text: qsTr("Subtitles"), icon: "subtitles" },
        { id: ControlListModel.EXTENDED_BUTTON, text: qsTr("Player Settings"), icon: "settings" },
        { id: ControlListModel.PLAYLIST_BUTTON, text: qsTr("Queue"), icon: "queue" },
        { id: ControlListModel.APP_MENU_BUTTON, text: qsTr("Menu"), icon: "more" },
        { id: ControlListModel.LIBRARY_BUTTON, text: qsTr("Library"), icon: "sidebar" },
        { id: ControlListModel.FULLSCREEN_BUTTON, text: qsTr("Fullscreen"), icon: "fullscreen" }
    ]

    // listed even when in a bar: they can be placed several times
    readonly property var customizeRepeatable: [
        ControlListModel.WIDGET_SPACER_EXTEND,
        ControlListModel.DIVIDER_WIDGET,
        ControlListModel.THUMBNAIL_WIDGET,
        ControlListModel.FILE_NAME_WIDGET,
        ControlListModel.ARTIST_NAME_WIDGET,
        ControlListModel.FOLDER_NAME_WIDGET,
        ControlListModel.PLAYLIST_NAME_WIDGET
    ]

    function customizeInfo(id) {
        return customizeList.find((e) => e.id === id) ?? { id: id, text: control(id).text ?? "", icon: "" }
    }
}
