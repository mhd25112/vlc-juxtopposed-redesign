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

import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets

// "Chapters" tab of the queue panel: numbered chapters with their start
// time, the current one in the accent color.
ListView {
    id: root

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    topMargin: VLCStyle.dp(8, VLCStyle.scale)
    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    model: Player.chapters

    delegate: T.AbstractButton {
        id: entry

        required property int index
        required property string display
        required property var time
        required property bool checked

        width: root.width
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

        onClicked: Player.chapters.selectChapter(index)

        background: Rectangle {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: entry.hovered ? root._c.hover : "transparent"
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(14, VLCStyle.scale)

            Text {
                Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
                Layout.preferredWidth: VLCStyle.dp(20, VLCStyle.scale)
                text: entry.index + 1
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: theme.accent
            }

            Text {
                Layout.fillWidth: true
                text: entry.display !== "" ? entry.display : qsTr("Chapter %1").arg(entry.index + 1)
                elide: Text.ElideRight
                font.pixelSize: VLCStyle.dp(13.5, VLCStyle.scale)
                color: entry.checked ? theme.accent : root._c.text
            }

            Text {
                Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
                text: entry.time?.formatHMS?.() ?? ""
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: root._c.dim
            }
        }

        Accessible.name: display
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - VLCStyle.dp(40, VLCStyle.scale)
        visible: root.count === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: qsTr("This media has no chapters.")
        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        color: root._c.dim
    }
}
