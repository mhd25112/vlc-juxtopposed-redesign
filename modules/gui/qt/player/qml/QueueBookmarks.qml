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
import VLC.MediaLibrary
import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets

// "Bookmarks" tab of the queue panel: the bookmarks of what plays, with
// their time; + adds one where the video is (also Ctrl+B), - removes the
// selected one, a click jumps there.
ColumnLayout {
    id: root

    spacing: 0

    property int _selected: -1

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(44, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)

        Text {
            Layout.fillWidth: true
            text: list.count === 1 ? qsTr("1 Bookmark") : qsTr("%1 Bookmarks").arg(list.count)
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root._c.label
        }

        Widgets.SvgToolButton {
            iconName: "minus"
            description: qsTr("Remove the bookmark")
            enabled: root._selected >= 0 && root._selected < list.count
            onClicked: {
                bookmarks.removeAt(root._selected)
                root._selected = -1
            }
        }

        Widgets.SvgToolButton {
            iconName: "add"
            description: qsTr("Add a bookmark here (Ctrl+B)")
            enabled: Player.playingState === Player.PLAYING_STATE_PLAYING || Player.playingState === Player.PLAYING_STATE_PAUSED
            onClicked: bookmarks.add()
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        model: MLBookmarkModel {
            id: bookmarks

            player: Player
            ml: MediaLib
        }

        delegate: T.AbstractButton {
            id: entry

            required property int index
            required property string name
            required property var time

            width: list.width
            implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

            onClicked: {
                root._selected = index
                bookmarks.select(bookmarks.index(index, 0))
            }

            background: Rectangle {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: root._selected === entry.index ? PanelStyle.accentFill(theme.accent, theme.palette?.isDark ?? true)
                                                     : (entry.hovered ? root._c.hover : "transparent")
            }

            contentItem: RowLayout {
                anchors.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(16, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
                    text: entry.name
                    elide: Text.ElideRight
                    font.pixelSize: VLCStyle.dp(13.5, VLCStyle.scale)
                    color: root._c.text
                }

                Text {
                    Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
                    text: String(entry.time)
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                    color: root._c.dim
                }
            }

            Accessible.name: name
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - VLCStyle.dp(40, VLCStyle.scale)
            visible: list.count === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("No bookmarks yet. Press Ctrl+B to mark the moment that plays.")
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root._c.dim
        }
    }
}
