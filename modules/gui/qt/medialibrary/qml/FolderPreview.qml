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
import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets

// The card of a folder: pictures of the videos in it (four in a mosaic, or
// the first one), a chip with the folder and how many videos it holds; the
// folder icon alone when it has no pictures yet.
Rectangle {
    id: root

    property url folder
    property bool hovered: false
    property real iconSize: VLCStyle.dp(40, VLCStyle.scale)

    property var _thumbnails: []
    property int _count: 0

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)
    readonly property color _rest: (theme.palette?.isDark ?? true) ? "#1e1e1e" : PanelStyle.light.card

    radius: VLCStyle.gridCover_radius
    color: hovered ? Qt.lighter(_rest, 1.3) : _rest
    clip: true
    Behavior on color { ColorAnimation { duration: 120 } }

    function _request() {
        if (String(folder) !== "")
            PlayerTweaks.requestFolderPreview(folder)
    }

    onFolderChanged: _request()
    Component.onCompleted: _request()

    Connections {
        target: PlayerTweaks
        function onFolderPreviewReady(folder, thumbnails, count) {
            if (decodeURIComponent(String(folder)) !== decodeURIComponent(String(root.folder)))
                return
            root._thumbnails = thumbnails
            root._count = count
        }
    }

    // the pictures: a mosaic of four, or one
    Grid {
        id: mosaic

        anchors.fill: parent
        visible: root._thumbnails.length > 0
        columns: root._thumbnails.length >= 4 ? 2 : 1
        spacing: root._thumbnails.length >= 4 ? VLCStyle.dp(2, VLCStyle.scale) : 0

        Repeater {
            model: root._thumbnails.length >= 4 ? root._thumbnails.slice(0, 4) : root._thumbnails.slice(0, 1)

            Image {
                required property var modelData

                width: mosaic.columns === 2 ? (mosaic.width - mosaic.spacing) / 2 : mosaic.width
                height: mosaic.columns === 2 ? (mosaic.height - mosaic.spacing) / 2 : mosaic.height
                source: modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 360
                opacity: root.hovered ? 1 : 0.92
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    // without pictures: the folder icon
    Widgets.PanelIcon {
        anchors.centerIn: parent
        visible: !mosaic.visible
        name: "folder"
        size: root.iconSize
        color: root.hovered ? root._c.bright : root._c.label
    }

    // with pictures: a chip with the folder and the count
    Rectangle {
        visible: mosaic.visible
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
        height: VLCStyle.dp(24, VLCStyle.scale)
        width: chipRow.implicitWidth + VLCStyle.dp(14, VLCStyle.scale)
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.62)

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: VLCStyle.dp(5, VLCStyle.scale)

            Widgets.PanelIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "folder"
                size: VLCStyle.dp(14, VLCStyle.scale)
                color: "#eaeaea"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root._count > 0
                text: root._count
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                color: "#eaeaea"
            }
        }
    }
}
