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

// The library next to the video, as in the design: a rail of the pages of
// the library (Home, Videos, Music, Network, Playlists, Recent, Add) and a
// list of the current one. It opens on the folder of what plays, so the next
// episode is a click away without leaving the video. Videos and Songs are the
// folders on the disk ("... > The Wand > S01").
FocusScope {
    id: root

    signal fullLibraryRequested(var path)

    implicitWidth: VLCStyle.dp(427, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    // where it is: { page, url }; pages: "folder" (of what plays), "home",
    // "videos" and "songs" (folders), "music", "albums", "artists",
    // "genres", "network", "playlists", "recent"
    property var place: ({ page: PlayerTweaks.libraryPage === "playlists" ? "playlists" : "folder", url: "" })

    property var _back: []
    property var _forward: []

    function go(page, url) {
        const next = { page: page, url: url ?? "" }
        if (next.page === place.page && String(next.url) === String(place.url))
            return
        _back = _back.concat([place])
        _forward = []
        place = next
        _search = ""
        searchField.text = ""
        searching = false
    }

    function back() {
        if (_back.length === 0)
            return
        _forward = _forward.concat([place])
        place = _back[_back.length - 1]
        _back = _back.slice(0, -1)
    }

    function forward() {
        if (_forward.length === 0)
            return
        _back = _back.concat([place])
        place = _forward[_forward.length - 1]
        _forward = _forward.slice(0, -1)
    }

    // the controls of the player ask for a page ("Folder Name", "Playlists")
    Connections {
        target: PlayerTweaks
        function onLibraryChanged() {
            const wanted = PlayerTweaks.libraryPage
            if (wanted === "folder" && root.place.page !== "folder")
                root.go("folder", "")
            else if (wanted === "playlists" && root.place.page !== "playlists")
                root.go("playlists", "")
        }
    }

    onPlaceChanged: {
        if (place.page === "folder" || place.page === "playlists")
            PlayerTweaks.libraryPage = place.page
        else
            PlayerTweaks.libraryPage = "other"
        _requestFolder()
    }

    // ---------------------------------------------------------------------
    // what the list shows

    property string _search: ""
    property bool searching: false
    property bool _descending: false
    property bool showPictures: true

    // the folder of what plays, or the one browsed from it
    readonly property url _diskFolder: place.page === "folder"
                                       ? (String(place.url) !== "" ? place.url : PlayerTweaks.parentFolder(Player.url))
                                       : ""

    // folders of the library: the answer of PlayerTweaks.requestLibraryFolder()
    property var _libResult: null
    property string _libJson: ""

    function _requestFolder() {
        if (place.page === "videos")
            PlayerTweaks.requestLibraryFolder("video", place.url)
        else if (place.page === "songs")
            PlayerTweaks.requestLibraryFolder("audio", place.url)
    }

    Component.onCompleted: _requestFolder()

    Connections {
        target: PlayerTweaks
        function onLibraryFolderReady(kind, folder, result) {
            const page = kind === "video" ? "videos" : "songs"
            if (root.place.page !== page
                || decodeURIComponent(String(folder)) !== decodeURIComponent(String(root.place.url)))
                return
            const json = JSON.stringify(result)
            if (json !== root._libJson) {
                root._libJson = json
                root._libResult = result
            }
        }
    }

    // entries of the list: { kind, name, url, id, cover, progress, watched,
    // icon }, kind being "add", "nav", "folder" or "media"
    function _sorted(entries) {
        const needle = _search.toLowerCase()
        const fixed = entries.filter((e) => e.kind === "add" || e.kind === "nav")
        let rest = entries.filter((e) => e.kind !== "add" && e.kind !== "nav")
                          .filter((e) => needle === "" || e.name.toLowerCase().includes(needle))
        if (_descending)
            rest = rest.slice().reverse()
        return (needle === "" ? fixed : []).concat(rest)
    }

    readonly property var _entries: {
        PlayerTweaks.revision
        switch (place.page) {
        case "folder": {
            const info = PlayerTweaks.mediaInfo
            return _sorted(PlayerTweaks.folderItems(_diskFolder).map((i) => {
                const m = info[String(i.url)] ?? null
                return {
                    kind: i.isDir ? "folder" : "media", name: i.name, url: i.url,
                    cover: m?.thumbnail ?? "", progress: m?.progress ?? 0,
                    watched: (m?.progress ?? 0) > 0 || (m?.playCount ?? 0) > 0,
                    icon: i.isDir ? "folder" : (i.isVideo === false ? "music" : "video")
                }
            }))
        }
        case "videos":
        case "songs": {
            const r = _libResult
            const add = { kind: "add", name: qsTr("Add"), icon: "add" }
            if (!r)
                return [add]
            const folders = (r.folders ?? []).map((f) => ({ kind: "folder", name: f.name, url: f.url, icon: "folder" }))
            const media = (r.media ?? []).map((m) => ({
                kind: "media", name: (place.page === "songs" && m.artist) ? m.title + " - " + m.artist : (m.name || m.title),
                url: m.url, id: m.id, cover: m.thumbnail, progress: m.progress,
                watched: m.progress > 0 || m.playCount > 0,
                icon: place.page === "songs" ? "music" : "video"
            }))
            return _sorted([add].concat(folders, media))
        }
        case "music":
            return [
                { kind: "add", name: qsTr("Add"), icon: "add" },
                { kind: "nav", name: qsTr("Songs"), icon: "note", page: "songs" },
                { kind: "nav", name: qsTr("Albums"), icon: "album", page: "albums" },
                { kind: "nav", name: qsTr("Artists"), icon: "artist", page: "artists" },
                { kind: "nav", name: qsTr("Genres"), icon: "genre", page: "genres" }
            ]
        default:
            return []
        }
    }

    // pages showing a model of the library
    readonly property var _model: {
        switch (place.page) {
        case "albums": return albumModel
        case "artists": return artistModel
        case "genres": return genreModel
        case "network": return urlModel
        case "playlists": return playlistModel
        case "recent": return recentModel
        default: return null
        }
    }

    readonly property int _count: _model ? _model.count
                                         : _entries.filter((e) => e.kind !== "add").length

    // the path in the header: [{ text, page, url }]
    readonly property var _crumbs: {
        const p = place.page
        const titles = {
            "home": qsTr("Home"), "videos": qsTr("Videos"), "music": qsTr("Music"),
            "network": qsTr("Network"), "playlists": qsTr("Playlists"), "recent": qsTr("Recent")
        }
        let crumbs = []
        if (p === "folder") {
            const path = decodeURIComponent(String(_diskFolder)).replace(/^file:\/\/\/?/, "")
            const parts = path.split("/").filter((s) => s !== "")
            let url = String(_diskFolder).replace(/\/$/, "")
            const urls = []
            for (let i = parts.length - 1; i >= 0; --i) {
                urls.unshift(url + "/")
                url = url.substring(0, url.lastIndexOf("/"))
            }
            crumbs = parts.map((name, i) => ({ text: name, page: "folder", url: urls[i] }))
        } else if (p === "videos" || p === "songs") {
            crumbs = p === "videos" ? [{ text: qsTr("Videos"), page: "videos", url: "" }]
                                    : [{ text: qsTr("Music"), page: "music", url: "" },
                                       { text: qsTr("Songs"), page: "songs", url: "" }]
            crumbs = crumbs.concat((_libResult?.crumbs ?? []).map((c) => ({ text: c.name, page: p, url: c.url })))
        } else if (p === "albums" || p === "artists" || p === "genres") {
            const names = { "albums": qsTr("Albums"), "artists": qsTr("Artists"), "genres": qsTr("Genres") }
            crumbs = [{ text: qsTr("Music"), page: "music", url: "" }, { text: names[p], page: p, url: "" }]
        } else {
            crumbs = [{ text: titles[p] ?? "", page: p, url: "" }]
        }
        // the last ones, after "..."
        if (crumbs.length > 2)
            crumbs = [{ text: "...", page: "", url: "" }].concat(crumbs.slice(-2))
        return crumbs
    }

    // the pictures and progress of the files of the folder of what plays
    on_DiskFolderChanged: Qt.callLater(() => {
        if (place.page === "folder")
            PlayerTweaks.requestMediaInfo(PlayerTweaks.folderItems(root._diskFolder).filter((i) => !i.isDir).map((i) => i.url))
    })

    function activate(entry) {
        switch (entry.kind) {
        case "add":
            if (place.page === "network")
                PlayerTweaks.requestDialog("network")
            else if (place.page === "playlists")
                PlayerTweaks.requestDialog("playlist")
            else
                MainCtx.addLibraryFolder()
            break
        case "nav":
            go(entry.page, "")
            break
        case "folder":
            go(entry.home ?? place.page, entry.url)
            break
        default:
            if (entry.id !== undefined)
                MediaLib.addAndPlay(entry.id)
            else if (entry.url)
                MediaLib.addAndPlay(entry.url)
        }
    }

    // ---------------------------------------------------------------------

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // the rail
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
                        { pages: ["home"], page: "home", icon: "home", text: qsTr("Home") },
                        { pages: ["videos"], page: "videos", icon: "videos", text: qsTr("Videos") },
                        { pages: ["music", "songs", "albums", "artists", "genres"], page: "music", icon: "music", text: qsTr("Music") },
                        { pages: ["network"], page: "network", icon: "network", text: qsTr("Network") },
                        { pages: ["playlists"], page: "playlists", icon: "playlists", text: qsTr("Playlists") },
                        { pages: ["recent"], page: "recent", icon: "recent", text: qsTr("Recent") }
                    ]

                    delegate: RailButton {
                        required property var modelData

                        current: modelData.pages.includes(root.place.page)
                        iconName: current && ["home", "videos", "music"].includes(modelData.icon)
                                  ? modelData.icon + "_filled" : modelData.icon
                        text: modelData.text
                        onClicked: root.go(modelData.page, "")
                    }
                }

                RailButton {
                    id: addButton

                    iconName: "add"
                    text: qsTr("Add")
                    onClicked: addMenu.popupNextTo(addButton, true)

                    Widgets.PanelMenu {
                        id: addMenu
                        model: [
                            { text: qsTr("Open File(s)"), icon: "file", action: () => DialogsProvider.simpleOpenDialog() },
                            { text: qsTr("Add a Folder to the Library"), icon: "folder", action: () => MainCtx.addLibraryFolder() },
                            { text: qsTr("Open Network Stream"), icon: "link", action: () => PlayerTweaks.requestDialog("network") },
                            { text: qsTr("Create Playlist"), icon: "playlists", action: () => PlayerTweaks.requestDialog("playlist") }
                        ]
                    }
                }
            }
        }

        // the page
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root._c.panel

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(14, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)
                spacing: 0

                // back, forward, the path, more and the full library
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(52, VLCStyle.scale)
                    spacing: VLCStyle.dp(2, VLCStyle.scale)

                    Widgets.SvgToolButton {
                        iconName: "arrow_left"
                        description: qsTr("Back")
                        enabled: root._back.length > 0
                        onClicked: root.back()
                    }

                    Widgets.SvgToolButton {
                        iconName: "arrow_right"
                        description: qsTr("Forward")
                        enabled: root._forward.length > 0
                        onClicked: root.forward()
                    }

                    Row {
                        Layout.fillWidth: true
                        Layout.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                        clip: true
                        spacing: VLCStyle.dp(4, VLCStyle.scale)

                        Repeater {
                            model: root._crumbs

                            delegate: Row {
                                id: crumb

                                required property int index
                                required property var modelData

                                readonly property bool last: index === root._crumbs.length - 1

                                spacing: VLCStyle.dp(4, VLCStyle.scale)

                                Widgets.PanelIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: crumb.index > 0
                                    name: "caret_right"
                                    size: VLCStyle.dp(12, VLCStyle.scale)
                                    color: root._c.dim
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: crumb.modelData.text
                                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                                    color: crumb.last ? root._c.bright
                                                      : (crumbMouse.containsMouse ? root._c.bright : root._c.text)

                                    MouseArea {
                                        id: crumbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: !crumb.last && crumb.modelData.page !== ""
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.go(crumb.modelData.page, crumb.modelData.url)
                                    }
                                }
                            }
                        }
                    }

                    Widgets.SvgToolButton {
                        id: moreButton
                        iconName: "more"
                        description: qsTr("More")
                        checked: moreMenu.visible
                        onClicked: moreMenu.popupNextTo(moreButton, false)

                        Widgets.PanelMenu {
                            id: moreMenu
                            menuWidth: VLCStyle.dp(260, VLCStyle.scale)
                            model: [
                                { text: qsTr("Open the Full Library"), icon: "popout", action: () => root._openFull() },
                                { text: qsTr("Add a Folder to the Library"), icon: "folder", action: () => MainCtx.addLibraryFolder() },
                                { text: qsTr("Rescan the Library"), icon: "rotate", action: () => MainCtx.mediaLibrary.reload() }
                            ]
                        }
                    }

                    Widgets.SvgToolButton {
                        iconName: "popout"
                        description: qsTr("Open the full library")
                        onClicked: root._openFull()
                    }
                }

                // the count, then sorting, pictures and search
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(36, VLCStyle.scale)
                    spacing: VLCStyle.dp(2, VLCStyle.scale)

                    Text {
                        Layout.fillWidth: true
                        visible: !root.searching
                        text: root.place.page === "home" ? ""
                                                         : (root._count === 1 ? qsTr("1 item") : qsTr("%1 items").arg(root._count))
                        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                        color: root._c.label
                    }

                    Widgets.PanelSearchField {
                        id: searchField

                        Layout.fillWidth: true
                        implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
                        visible: root.searching
                        onPatternChanged: root._search = pattern.trim()
                        Keys.onEscapePressed: { text = ""; root.searching = false }
                    }

                    Widgets.SvgToolButton {
                        id: sortButton
                        visible: root.place.page !== "home" && root.place.page !== "music"
                        iconName: "sort"
                        description: qsTr("Sort")
                        checked: sortMenu.visible
                        onClicked: sortMenu.popupNextTo(sortButton, false)

                        Widgets.PanelMenu {
                            id: sortMenu
                            menuWidth: VLCStyle.dp(220, VLCStyle.scale)
                            model: [
                                { text: qsTr("Name, A to Z"), checked: !root._descending, action: () => { root._descending = false } },
                                { text: qsTr("Name, Z to A"), checked: root._descending, action: () => { root._descending = true } }
                            ]
                        }
                    }

                    Widgets.SvgToolButton {
                        id: viewButton
                        visible: root.place.page !== "home"
                        iconName: "list"
                        description: qsTr("View Options")
                        checked: viewMenu.visible
                        onClicked: viewMenu.popupNextTo(viewButton, false)

                        Widgets.PanelMenu {
                            id: viewMenu
                            menuWidth: VLCStyle.dp(220, VLCStyle.scale)
                            model: [
                                { text: qsTr("Show Pictures"), checked: root.showPictures,
                                  action: () => { root.showPictures = !root.showPictures } }
                            ]
                        }
                    }

                    Widgets.SvgToolButton {
                        iconName: root.searching ? "close" : "search"
                        description: root.searching ? qsTr("Close the search") : qsTr("Search")
                        visible: root.place.page !== "home" && root.place.page !== "music"
                        onClicked: {
                            root.searching = !root.searching
                            if (root.searching) {
                                searchField.forceActiveFocus()
                            } else {
                                searchField.text = ""
                                root._search = ""
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.border
                    color: root._c.separator
                }

                // a list of entries or of a model of the library
                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

                    visible: root.place.page !== "home"
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                    model: root._model ?? root._entries

                    header: root._model && ["network", "playlists"].includes(root.place.page) ? addRow : null

                    delegate: Entry {
                        required property var model
                        required property int index

                        width: list.width
                        entry: root._model ? root._modelEntry(model) : (model.modelData ?? model)
                    }
                }

                // Home: a few of each section
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

                    visible: root.place.page === "home"
                    clip: true
                    contentHeight: homeColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                    Column {
                        id: homeColumn

                        width: parent.width
                        spacing: VLCStyle.dp(6, VLCStyle.scale)

                        HomeSection {
                            title: qsTr("Continue Watching")
                            model: root.place.page === "home" ? continueModel : null
                            fullPath: ["home"]
                        }
                        HomeSection {
                            title: qsTr("Listen Again")
                            model: root.place.page === "home" ? listenModel : null
                            fullPath: ["music", "tracks"]
                        }
                        HomeSection {
                            title: qsTr("Frequently Visited Folders")
                            model: root.place.page === "home" ? foldersModel : null
                            fullPath: ["video"]
                        }
                        HomeSection {
                            title: qsTr("Frequently Visited Playlists")
                            model: root.place.page === "home" ? homePlaylistModel : null
                            fullPath: ["playlists"]
                        }
                        HomeSection {
                            title: qsTr("Frequently Listened Artists")
                            model: root.place.page === "home" ? homeArtistModel : null
                            fullPath: ["music", "artists"]
                        }
                    }
                }
            }
        }
    }

    // the same place in the full library
    function _openFull() {
        switch (place.page) {
        case "folder":
            // the folder in the folder view of the library
            PlayerTweaks.locateFolder(_diskFolder, true)
            fullLibraryRequested(["video"])
            break
        case "videos":
            fullLibraryRequested(["video"])
            if (String(place.url) !== "")
                History.push(["video", "folder"], { url: place.url })
            break
        default: {
            const paths = { "home": ["home"], "music": ["music"], "songs": ["music", "tracks"],
                            "albums": ["music", "albums"], "artists": ["music", "artists"],
                            "genres": ["music", "genres"], "network": ["network"],
                            "playlists": ["playlists"], "recent": ["recent"] }
            fullLibraryRequested(paths[place.page] ?? ["home"])
        }
        }
    }

    // an entry of a model of the library
    function _modelEntry(m) {
        switch (place.page) {
        case "albums":
            return { kind: "media", name: m.title + (m.main_artist ? " - " + m.main_artist : ""), id: m.id, cover: m.cover, icon: "album" }
        case "artists":
            return { kind: "media", name: m.name, id: m.id, cover: m.cover, icon: "artist", round: true }
        case "genres":
            return { kind: "media", name: m.name, id: m.id, cover: "", icon: "genre" }
        case "network":
            return { kind: "media", name: decodeURIComponent(String(m.url)), url: m.url, cover: "", icon: "network" }
        case "playlists":
            return { kind: "media", name: m.name, id: m.id, cover: "", icon: "playlists" }
        case "recent":
            return { kind: "media", name: m.title, id: m.id, mrl: m.mrl, cover: m.small_cover ?? m.thumbnail ?? "",
                     progress: m.progress ?? 0, icon: m.isVideo === false ? "music" : "video" }
        default:
            return { kind: "media", name: m.title ?? m.name ?? "", id: m.id }
        }
    }

    // ---------------------------------------------------------------------

    component RailButton: T.AbstractButton {
        id: railButton

        property bool current: false
        property string iconName

        implicitWidth: VLCStyle.dp(40, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
        hoverEnabled: true

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: railButton.hovered ? root._c.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        contentItem: Widgets.PanelIcon {
            name: railButton.iconName
            size: VLCStyle.dp(22, VLCStyle.scale)
            color: railButton.current ? theme.accent : (railButton.hovered ? root._c.bright : root._c.label)
            secondaryColor: root._c.raised
        }

        T.ToolTip.visible: hovered
        T.ToolTip.delay: VLCStyle.delayToolTipAppear
        T.ToolTip.text: text
        Accessible.name: text
    }

    // a line of the list: a picture or an icon, and a name
    component Entry: T.AbstractButton {
        id: line

        property var entry: ({})

        readonly property bool playing: entry.kind === "media"
                                        && ((entry.url !== undefined && String(entry.url) === String(Player.url))
                                            || (entry.mrl !== undefined && String(entry.mrl) === String(Player.url)))
        readonly property bool picture: root.showPictures && (entry.kind === "media") && !!entry.cover

        implicitHeight: VLCStyle.dp(42, VLCStyle.scale)
        hoverEnabled: true

        onClicked: root.activate(entry)

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: line.hovered ? root._c.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Item {
                Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)
                implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
                implicitHeight: implicitWidth

                Rectangle {
                    anchors.fill: parent
                    visible: line.picture
                    radius: line.entry.round ? width / 2 : VLCStyle.dp(4, VLCStyle.scale)
                    color: root._c.hover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: line.picture ? line.entry.cover : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(64, 64)
                        asynchronous: true
                        opacity: line.entry.watched && !line.hovered ? 0.6 : 1
                    }

                    // what was watched
                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        height: VLCStyle.dp(2, VLCStyle.scale)
                        width: parent.width * Math.min(1, line.entry.progress ?? 0)
                        visible: (line.entry.progress ?? 0) > 0 && !line.playing
                        color: theme.accent
                    }
                }

                Widgets.PanelIcon {
                    anchors.centerIn: parent
                    visible: !line.picture || line.playing
                    name: line.playing ? "play_filled" : (line.entry.icon ?? "video")
                    size: VLCStyle.dp(20, VLCStyle.scale)
                    color: line.playing ? theme.accent : (line.hovered ? root._c.bright : root._c.label)
                }
            }

            Text {
                Layout.fillWidth: true
                text: line.entry.name ?? ""
                elide: Text.ElideRight
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: line.playing ? theme.accent
                                    : (line.hovered ? root._c.bright
                                                    : ((line.entry.kind === "add") ? root._c.label
                                                                                    : (line.entry.watched ? root._c.dim : root._c.text)))
            }
        }

        Accessible.name: entry.name ?? ""
    }

    // the first row of the playlists and network pages
    Component {
        id: addRow

        Entry {
            width: list.width
            entry: root.place.page === "network"
                   ? { kind: "add", name: qsTr("Add Network Stream"), icon: "add" }
                   : { kind: "add", name: qsTr("Create playlist"), icon: "add" }
        }
    }

    // a section of Home: its title (to the full library) and a few lines
    component HomeSection: Column {
        id: section

        property string title
        property var model: null
        property var fullPath: []

        width: parent.width
        visible: (sectionRepeater.count > 0)
        spacing: 0

        T.AbstractButton {
            id: sectionTitle

            width: parent.width
            implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
            hoverEnabled: true
            onClicked: root.fullLibraryRequested(section.fullPath)

            contentItem: RowLayout {
                spacing: VLCStyle.dp(6, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    text: section.title
                    elide: Text.ElideRight
                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                    color: sectionTitle.hovered ? root._c.bright : root._c.text
                }

                Widgets.PanelIcon {
                    name: "chevron_right"
                    size: VLCStyle.dp(16, VLCStyle.scale)
                    color: sectionTitle.hovered ? root._c.bright : root._c.label
                }
            }
        }

        Repeater {
            id: sectionRepeater

            model: section.model

            delegate: Entry {
                required property var model

                width: section.width
                entry: {
                    const m = model
                    if (section.model === foldersModel)
                        return { kind: "folder", name: m.title, url: m.mrl, icon: "folder", home: "videos" }
                    if (section.model === homePlaylistModel)
                        return { kind: "media", name: m.name, id: m.id, icon: "playlists" }
                    if (section.model === homeArtistModel)
                        return { kind: "media", name: m.name, id: m.id, cover: m.cover, icon: "artist", round: true }
                    if (section.model === listenModel)
                        return { kind: "media", name: m.title + (m.main_artist ? " - " + m.main_artist : ""), id: m.id,
                                 cover: m.cover, icon: "music" }
                    return { kind: "media", name: m.title, id: m.id, mrl: m.mrl, cover: m.thumbnail,
                             progress: m.progress, icon: "video" }
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // models of the library

    MLAlbumModel { id: albumModel; ml: MediaLib; searchPattern: root.place.page === "albums" ? root._search : "" }
    MLArtistModel { id: artistModel; ml: MediaLib; searchPattern: root.place.page === "artists" ? root._search : "" }
    MLGenreModel { id: genreModel; ml: MediaLib; searchPattern: root.place.page === "genres" ? root._search : "" }
    MLUrlModel { id: urlModel; ml: MediaLib; searchPattern: root.place.page === "network" ? root._search : "" }
    MLPlaylistListModel { id: playlistModel; ml: MediaLib; searchPattern: root.place.page === "playlists" ? root._search : "" }
    MLRecentMediaModel { id: recentModel; ml: MediaLib; searchPattern: root.place.page === "recent" ? root._search : "" }

    MLRecentVideoModel { id: continueModel; ml: MediaLib; limit: 3 }
    MLRecentAudioModel { id: listenModel; ml: MediaLib; limit: 3 }
    MLVideoFoldersModel { id: foldersModel; ml: MediaLib; limit: 3 }
    MLPlaylistListModel { id: homePlaylistModel; ml: MediaLib; limit: 3 }
    MLArtistModel { id: homeArtistModel; ml: MediaLib; limit: 3; sortCriteria: "nb_tracks"; sortOrder: Qt.DescendingOrder }
}
