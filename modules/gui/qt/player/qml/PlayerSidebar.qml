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
import QtQuick.Controls as QQC2

import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets

// Settings of what is playing, next to the video: one tab for the playback,
// the video, the audio and the subtitles, each with the defaults first and
// the rarely used settings folded.
FocusScope {
    id: root

    enum Page {
        Playback,
        Video,
        Audio,
        Subtitles
    }

    implicitWidth: VLCStyle.dp(362, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    // the tabs sit on the darkest surface, the page a step lighter
    Rectangle {
        anchors.fill: parent
        color: root._c.field
        radius: VLCStyle.dp(8, VLCStyle.scale)
        border.width: VLCStyle.border
        border.color: root._c.separator
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: VLCStyle.border
        spacing: 0

        Widgets.PanelTabBar {
            id: tabs

            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)

            focus: true

            model: [
                { text: qsTr("Playback"), icon: "playback" },
                { text: qsTr("Video"), icon: "video" },
                { text: qsTr("Audio"), icon: "audio" },
                { text: qsTr("Subtitles"), icon: "subtitles" }
            ]

            currentIndex: PlayerTweaks.sidebarPage
            onActivated: (index) => PlayerTweaks.sidebarPage = index

            Keys.onEscapePressed: PlayerTweaks.sidebarVisible = false
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: root._c.panel
            radius: VLCStyle.dp(8, VLCStyle.scale)

            Loader {
                id: page

                anchors.fill: parent
                anchors.bottomMargin: VLCStyle.dp(6, VLCStyle.scale)

                sourceComponent: {
                    switch (PlayerTweaks.sidebarPage) {
                    case PlayerSidebar.Page.Video:
                        return videoPage
                    case PlayerSidebar.Page.Audio:
                        return audioPage
                    case PlayerSidebar.Page.Subtitles:
                        return subtitlesPage
                    default:
                        return playbackPage
                    }
                }
            }
        }
    }

    Component { id: playbackPage; SidebarPlayback { } }
    Component { id: videoPage; SidebarVideo { } }
    Component { id: audioPage; SidebarAudio { } }
    Component { id: subtitlesPage; SidebarSubtitles { } }
}
