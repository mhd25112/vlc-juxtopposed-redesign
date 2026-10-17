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
import VLC.Playlist
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Dialogs

// The library next to the video, in compact mode: a rail of the library
// pages and a list of the current one. It opens on the folder of what plays,
// so the next episode is a click away without leaving the video.
FocusScope {
    id: root

    // "folder", "videos", "music", "playlists", "recent"
    property string page: "folder"
    // folder shown by the "folder" page
    property url folder: PlayerTweaks.parentFolder(Player.url)

    signal fullLibraryRequested(var path)

    implicitWidth: VLCStyle.dp(427, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    // history of the folder page
    property var _back: []
    property var _forward: []

    function openFolder(url) {
        _back = _back.concat([folder])
        _forward = []
        folder = url
        page = "folder"
    }

    property string _search: ""

    readonly property var _folderItems: {
        PlayerTweaks.revision
        if (page !== "folder")
            return []
        const needle = _search.toLowerCase()
        return PlayerTweaks.folderItems(folder).filter((i) => needle === "" || i.name.toLowerCase().includes(needle))
    }

    // the pictures and progress of the files, from the library
    on_FolderItemsChanged: PlayerTweaks.requestMediaInfo(_folderItems.filter((i) => !i.isDir).map((i) => i.url))

    // path of the folder, its last parts
    readonly property var _crumbs: {
        const path = decodeURIComponent(String(folder)).replace(/^file:\/\/\/?/, "")
        const parts = path.split("/").filter((p) => p !== "")
        return parts.length > 2 ? ["...", parts[parts.length - 2], parts[parts.length - 1]] : parts
    }

    readonly property var _titles: ({
        "videos": qsTr("Videos"),
        "music": qsTr("Songs"),
        "playlists": qsTr("Playlists"),
        "recent": qsTr("Recent")
    })

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // rail
        Rectangle {
            Layout.preferredWidth: VLCStyle.dp(50, VLCStyle.scale)
            Layout.fillHeight: true
            color: root._c.raised

            Column {
                anchors.top: parent.top
                anchors.topMargin: VLCStyle.dp(10, VLCStyle.scale)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Repeater {
                    model: [
                        { page: "folder", icon: "home", text: qsTr("This folder") },
                        { page: "videos", icon: "videos", text: qsTr("Videos") },
                        { page: "music", icon: "music", text: qsTr("Music") },
                        { page: "network", icon: "network", text: qsTr("Network") },
                        { page: "playlists", icon: "playlists", text: qsTr("Playlists") },
                        { page: "recent", icon: "recent", text: qsTr("Recent") }
                    ]

                    delegate: T.AbstractButton {
                        id: railButton

                        required property var modelData

                        readonly property bool current: root.page === modelData.page

                        implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
                        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)

                        onClicked: {
                            if (modelData.page === "network") {
                                root.fullLibraryRequested(["network"])
                                return
                            }
                            root._search = ""
                            root.page = modelData.page
                        }

                        background: Rectangle {
                            radius: VLCStyle.dp(6, VLCStyle.scale)
                            color: railButton.hovered ? root._c.hover : "transparent"
                        }

                        contentItem: Widgets.PanelIcon {
                            name: railButton.current && ["home", "videos", "music"].includes(railButton.modelData.icon)
                                  ? railButton.modelData.icon + "_filled" : railButton.modelData.icon
                            size: VLCStyle.dp(22, VLCStyle.scale)
                            color: railButton.current ? theme.accent : root._c.label
                            secondaryColor: root._c.raised
                        }

                        T.ToolTip.visible: hovered
                        T.ToolTip.delay: VLCStyle.delayToolTipAppear
                        T.ToolTip.text: modelData.text
                        Accessible.name: modelData.text
                    }
                }

                T.AbstractButton {
                    id: addButton

                    implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
                    onClicked: addMenu.popupNextTo(addButton, true)

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: addButton.hovered ? root._c.hover : "transparent"
                    }
                    contentItem: Widgets.PanelIcon {
                        name: "add"
                        size: VLCStyle.dp(22, VLCStyle.scale)
                        color: root._c.label
                    }

                    Widgets.PanelMenu {
                        id: addMenu
                        model: [
                            { text: qsTr("Open File(s)"), icon: "file", action: () => DialogsProvider.simpleOpenDialog() },
                            { text: qsTr("Add a Folder to the Library"), icon: "folder", action: () => MainCtx.addLibraryFolder() },
                            { text: qsTr("Open Network Stream"), icon: "link", action: () => PlayerTweaks.requestDialog("network") }
                        ]
                    }

                    Accessible.name: qsTr("Add")
                }
            }
        }

        // list
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root._c.panel

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(14, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)
                spacing: 0

                // back, forward, path, menu and the full library
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(52, VLCStyle.scale)
                    spacing: VLCStyle.dp(2, VLCStyle.scale)

                    Widgets.SvgToolButton {
                        iconName: "arrow_left"
                        description: qsTr("Back")
                        enabled: root.page === "folder" && root._back.length > 0
                        width: VLCStyle.dp(32, VLCStyle.scale)
                        height: width
                        onClicked: {
                            root._forward = root._forward.concat([root.folder])
                            root.folder = root._back[root._back.length - 1]
                            root._back = root._back.slice(0, -1)
                        }
                    }

                    Widgets.SvgToolButton {
                        iconName: "arrow_right"
                        description: qsTr("Forward")
                        enabled: root.page === "folder" && root._forward.length > 0
                        width: VLCStyle.dp(32, VLCStyle.scale)
                        height: width
                        onClicked: {
                            root._back = root._back.concat([root.folder])
                            root.folder = root._forward[root._forward.length - 1]
                            root._forward = root._forward.slice(0, -1)
                        }
                    }

                    Row {
                        Layout.fillWidth: true
                        Layout.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                        clip: true
                        spacing: VLCStyle.dp(4, VLCStyle.scale)

                        Repeater {
                            model: root.page === "folder" ? root._crumbs : [root._titles[root.page]]

                            delegate: Row {
                                required property int index
                                required property string modelData

                                spacing: VLCStyle.dp(4, VLCStyle.scale)

                                Widgets.PanelIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: index > 0
                                    name: "caret_right"
                                    size: VLCStyle.dp(12, VLCStyle.scale)
                                    color: root._c.dim
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                                    color: root._c.text
                                }
                            }
                        }
                    }

                    Widgets.SvgToolButton {
                        iconName: "popout"
                        description: qsTr("Open the full library")
                        width: VLCStyle.dp(32, VLCStyle.scale)
                        height: width
                        onClicked: {
                            const paths = { "videos": ["video"], "music": ["music", "tracks"], "playlists": ["playlists"], "recent": ["recent"] }
                            root.fullLibraryRequested(paths[root.page] ?? ["video"])
                            // the folder's videos, once found in the library
                            if (root.page === "folder")
                                PlayerTweaks.locateFolder(root.folder, true)
                        }
                    }
                }

                // count, search
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(40, VLCStyle.scale)
                    spacing: VLCStyle.dp(8, VLCStyle.scale)

                    Text {
                        Layout.preferredWidth: implicitWidth
                        text: list.count === 1 ? qsTr("1 item") : qsTr("%1 items").arg(list.count)
                        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                        color: root._c.label
                    }

                    Widgets.PanelSearchField {
                        Layout.fillWidth: true
                        implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
                        onPatternChanged: root._search = pattern.trim()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.border
                    color: root._c.separator
                }

                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                    model: {
                        switch (root.page) {
                        case "videos": return videoModel
                        case "music": return audioModel
                        case "playlists": return playlistModel
                        case "recent": return recentModel
                        default: return root._folderItems
                        }
                    }

                    header: root.page === "playlists" ? createPlaylistRow : null

                    delegate: T.AbstractButton {
                        id: entry

                        required property var model
                        required property int index

                        // folder entries are plain objects, library entries have roles
                        readonly property var data: model.modelData ?? model
                        readonly property bool isDir: root.page === "folder" && data.isDir === true
                        readonly property string title: root.page === "folder" ? data.name
                                                        : (root.page === "playlists" ? (data.name ?? "") : (data.title ?? ""))
                        // what the library knows of a file of the folder
                        readonly property var info: root.page === "folder" ? (PlayerTweaks.mediaInfo[String(data.url)] ?? null) : null
                        readonly property string cover: data.thumbnail ?? data.small_cover ?? data.cover ?? info?.thumbnail ?? ""
                        readonly property real progress: info?.progress ?? data.progress ?? 0
                        readonly property bool watched: progress > 0 || (info?.playCount ?? 0) > 0
                        readonly property bool playing: root.page === "folder"
                                                        ? String(data.url) === String(Player.url)
                                                        : (data.mrl !== undefined && String(data.mrl) === String(Player.url))

                        width: list.width
                        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)

                        onClicked: {
                            if (root.page === "folder") {
                                if (isDir)
                                    root.openFolder(data.url)
                                else
                                    MediaLib.addAndPlay(data.url)
                            } else if (root.page === "playlists") {
                                MediaLib.addAndPlay(data.id)
                            } else {
                                MediaLib.addAndPlay(data.id)
                            }
                        }

                        background: Rectangle {
                            radius: VLCStyle.dp(6, VLCStyle.scale)
                            color: entry.hovered ? root._c.hover : "transparent"
                        }

                        contentItem: RowLayout {
                            spacing: VLCStyle.dp(10, VLCStyle.scale)

                            Rectangle {
                                Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)
                                implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
                                implicitHeight: implicitWidth
                                radius: VLCStyle.dp(4, VLCStyle.scale)
                                color: root._c.hover
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    visible: entry.cover !== ""
                                    source: entry.cover
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(64, 64)
                                    asynchronous: true
                                }

                                // what was watched
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    height: VLCStyle.dp(2, VLCStyle.scale)
                                    width: parent.width * Math.min(1, entry.progress)
                                    visible: entry.progress > 0 && !entry.playing
                                    color: theme.accent
                                }

                                Widgets.PanelIcon {
                                    anchors.centerIn: parent
                                    visible: entry.cover === "" || entry.playing
                                    name: entry.playing ? "play_filled"
                                                        : (entry.isDir ? "folder"
                                                                       : (root.page === "playlists" ? "playlists"
                                                                                                    : (root.page === "music" || entry.data.isVideo === false ? "music" : "video")))
                                    size: VLCStyle.dp(18, VLCStyle.scale)
                                    color: entry.playing ? theme.accent : root._c.label
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entry.title
                                elide: Text.ElideRight
                                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                                color: entry.playing ? theme.accent
                                                     : (entry.hovered ? root._c.bright : (entry.watched ? root._c.dim : root._c.text))
                            }
                        }

                        Accessible.name: title
                    }
                }
            }
        }
    }

    Component {
        id: createPlaylistRow

        T.AbstractButton {
            width: list.width
            implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
            onClicked: PlayerTweaks.requestDialog("playlist")

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: parent.hovered ? root._c.hover : "transparent"
            }
            contentItem: RowLayout {
                spacing: VLCStyle.dp(10, VLCStyle.scale)
                Widgets.PanelIcon {
                    Layout.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(4, VLCStyle.scale)
                    name: "add"
                    size: VLCStyle.dp(20, VLCStyle.scale)
                    color: root._c.label
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Create playlist")
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: root._c.label
                }
            }
        }
    }

    MLVideoModel {
        id: videoModel
        ml: MediaLib
        searchPattern: root._search
    }

    MLAudioModel {
        id: audioModel
        ml: MediaLib
        searchPattern: root._search
    }

    MLPlaylistListModel {
        id: playlistModel
        ml: MediaLib
        searchPattern: root._search
    }

    MLRecentMediaModel {
        id: recentModel
        ml: MediaLib
        searchPattern: root._search
    }
}
