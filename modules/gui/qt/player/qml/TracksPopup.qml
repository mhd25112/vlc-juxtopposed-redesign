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
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Dialogs

// Compact track picker opened by the subtitle and audio buttons of the
// control bar. Unlike TracksMenu, it stays next to the button that opened
// it and shows one kind of track at a time, so picking a subtitle or an
// audio output is a single click. Timing and other settings are one click
// further, behind "Show Preferences".
T.Popup {
    id: root

    enum Page {
        Subtitles,
        Audio,
        Video
    }

    property int page: TracksPopup.Page.Subtitles

    // TrackListModel of the current page
    readonly property var _tracks: {
        switch (page) {
        case TracksPopup.Page.Audio:
            return Player.audioTracks
        case TracksPopup.Page.Video:
            return Player.videoTracks
        default:
            return Player.subtitleTracks
        }
    }

    readonly property real _listMaxHeight: VLCStyle.dp(180, VLCStyle.scale)

    function openPage(page) {
        root.page = page
        root.open()
    }

    // NOTE: Templates do not size popups after their content.
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    width: VLCStyle.dp(320, VLCStyle.scale)

    padding: VLCStyle.margin_small
    topPadding: 0

    focus: true

    readonly property ColorContext colorContext: ColorContext {
        id: popupTheme
        colorSet: ColorContext.Window
    }

    background: Rectangle {
        // NOTE: The opacity should be stronger on a light background for readability.
        color: popupTheme.bg.primary.alpha((popupTheme.palette?.isDark ?? true) ? 0.92 : 0.97)
        border.color: popupTheme.border
        border.width: VLCStyle.border
        radius: VLCStyle.dp(8, VLCStyle.scale)
    }

    contentItem: ColumnLayout {
        spacing: 0

        //popup content is not parented to the root, duplicate the context
        readonly property ColorContext colorContext: ColorContext {
            id: theme
            colorSet: popupTheme.colorSet
            palette: popupTheme.palette
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: VLCStyle.margin_xsmall

            spacing: 0

            Repeater {
                model: [
                    { page: TracksPopup.Page.Video, text: qsTr("Video") },
                    { page: TracksPopup.Page.Audio, text: qsTr("Audio") },
                    { page: TracksPopup.Page.Subtitles, text: qsTr("Subtitles") }
                ]

                delegate: Widgets.TextToolButton {
                    id: tabButton

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(40, VLCStyle.scale)

                    text: modelData.text
                    checked: root.page === modelData.page
                    font.weight: checked ? Font.DemiBold : Font.Normal
                    opacity: checked ? 1.0 : 0.7

                    onClicked: root.page = modelData.page

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        height: VLCStyle.dp(2, VLCStyle.scale)

                        color: tabButton.checked ? theme.accent : theme.border
                    }
                }
            }
        }

        SectionLabel {
            text: qsTr("Embedded Tracks")
            color: theme.fg.secondary
        }

        TrackRow {
            Layout.fillWidth: true

            colors: theme
            text: qsTr("None")
            selected: !(root._tracks?.hasSelection ?? false)

            onClicked: root._tracks?.unselectAll()
        }

        Widgets.ListViewExt {
            id: tracksList

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root._listMaxHeight)

            visible: count > 0
            clip: true

            model: root._tracks

            delegate: TrackRow {
                required property var model

                width: ListView.view.width

                colors: theme
                text: model.display
                selected: model.checked

                // NOTE: Picking the selected track again keeps it, use "None".
                onClicked: model.checked = true
            }

            Accessible.role: Accessible.List
            Accessible.name: qsTr("Track list")
        }

        // Subtitles that are not part of the media, such as a file next to it
        ColumnLayout {
            Layout.fillWidth: true

            visible: root.page === TracksPopup.Page.Subtitles

            spacing: 0

            Separator {
                color: theme.border
            }

            RowLayout {
                Layout.fillWidth: true

                SectionLabel {
                    text: qsTr("External Tracks")
                    color: theme.fg.secondary
                }

                Widgets.SvgToolButton {
                    iconName: "add"
                    description: qsTr("Add subtitles")

                    // to this file, its folder or the playlist
                    onClicked: {
                        root.close()
                        PlayerTweaks.requestDialog("subtitles")
                    }
                }
            }
        }

        // Audio output devices live next to the audio tracks so that switching
        // between headphones and speakers does not require leaving VLC.
        ColumnLayout {
            Layout.fillWidth: true

            visible: root.page === TracksPopup.Page.Audio && devicesList.count > 0

            spacing: 0

            Separator {
                color: theme.border
            }

            SectionLabel {
                text: qsTr("Output Device")
                color: theme.fg.secondary
            }

            Widgets.ListViewExt {
                id: devicesList

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, root._listMaxHeight)

                clip: true

                model: Player.audioDevices

                delegate: TrackRow {
                    required property var model

                    width: ListView.view.width

                    colors: theme
                    text: model.display
                    selected: model.checked

                    onClicked: model.checked = true
                }

                Accessible.role: Accessible.List
                Accessible.name: qsTr("Audio output devices")
            }
        }

        Widgets.ButtonExt {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.margin_small

            text: qsTr("Show Preferences")

            // the sidebar tab of the same kind of tracks
            onClicked: {
                root.close()
                switch (root.page) {
                case TracksPopup.Page.Audio:
                    PlayerTweaks.sidebarPage = PlayerSidebar.Page.Audio
                    break
                case TracksPopup.Page.Video:
                    PlayerTweaks.sidebarPage = PlayerSidebar.Page.Video
                    break
                default:
                    PlayerTweaks.sidebarPage = PlayerSidebar.Page.Subtitles
                    break
                }
                PlayerTweaks.sidebarVisible = true
            }
        }
    }

    // NOTE: Inline components do not see the ids of this file, colors are
    //       given by the users.

    component SectionLabel: Widgets.CaptionLabel {
        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.margin_xsmall
        Layout.topMargin: VLCStyle.margin_xsmall
        Layout.bottomMargin: VLCStyle.margin_xxsmall
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.margin_xsmall

        implicitHeight: VLCStyle.border
    }

    // A track: orange check mark when selected, highlighted when hovered
    component TrackRow: T.ItemDelegate {
        id: row

        required property ColorContext colors
        property bool selected: false

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

        leftPadding: VLCStyle.margin_xsmall
        rightPadding: VLCStyle.margin_xsmall

        font.pixelSize: VLCStyle.fontSize_normal

        Accessible.role: Accessible.RadioButton
        Accessible.checked: selected

        background: Rectangle {
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: (row.hovered || row.visualFocus) ? row.colors.bg.highlight : "transparent"
            border.color: row.visualFocus ? row.colors.visualFocus : "transparent"
        }

        contentItem: RowLayout {
            spacing: VLCStyle.margin_xsmall

            Widgets.IconLabel {
                Layout.preferredWidth: VLCStyle.icon_track

                text: VLCIcons.check
                color: row.colors.accent
                font.pixelSize: VLCStyle.icon_track
                opacity: row.selected ? 1.0 : 0.0
            }

            Widgets.MenuLabel {
                Layout.fillWidth: true

                text: row.text
                font: row.font
                color: row.colors.fg.primary
                opacity: row.selected ? 1.0 : 0.8
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
