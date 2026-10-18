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
import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets

// Add Subtitles: to this file, to every episode of its folder or to the
// whole queue at once. Each media gets the subtitle whose name matches it
// best (same episode number, then the closest name), every match can be
// changed, and the choice is remembered for the next time the media plays.
Widgets.PanelDialog {
    id: root

    title: qsTr("Add Subtitles")
    preferredWidth: VLCStyle.dp(1048, VLCStyle.scale)
    preferredHeight: VLCStyle.dp(800, VLCStyle.scale)

    // 0: this file, 1: this folder, 2: this playlist
    property int target: 0
    // 0: computer, 1: OpenSubtitles, 2: link
    property int origin: 0

    // [{ name, url }]
    property var _media: []
    property var _subtitles: []
    // media url -> subtitle url (or "" for none)
    property var _matches: ({})
    property string _link: ""

    // OpenSubtitles: the media searched for, the results, what is going on
    property int _onlineIndex: 0
    readonly property var _onlineMedia: _media[_onlineIndex] ?? null
    property var _online: []
    property string _onlineStatus: ""
    property bool _onlineBusy: false
    // media url -> the file downloaded for it
    property var _downloaded: ({})
    property string _downloadedLink: ""

    readonly property var _languages: [
        { code: "all", name: qsTr("All Languages") },
        { code: "eng", name: "English" }, { code: "ara", name: "العربية" },
        { code: "fre", name: "Français" }, { code: "spa", name: "Español" },
        { code: "ger", name: "Deutsch" }, { code: "ita", name: "Italiano" },
        { code: "por", name: "Português" }, { code: "pob", name: "Português (Brasil)" },
        { code: "rus", name: "Русский" }, { code: "tur", name: "Türkçe" },
        { code: "dut", name: "Nederlands" }, { code: "pol", name: "Polski" },
        { code: "swe", name: "Svenska" }, { code: "gre", name: "Ελληνικά" },
        { code: "heb", name: "עברית" }, { code: "per", name: "فارسی" },
        { code: "hin", name: "हिन्दी" }, { code: "chi", name: "中文" },
        { code: "jpn", name: "日本語" }, { code: "kor", name: "한국어" }
    ]

    // the language of the interface, or the one chosen the last time
    property string _language: {
        const saved = String(PlayerTweaks.uiOption("opensubLanguage", ""))
        if (saved !== "")
            return saved
        const two = { "en": "eng", "ar": "ara", "fr": "fre", "es": "spa", "de": "ger", "it": "ita",
                      "pt": "por", "ru": "rus", "tr": "tur", "nl": "dut", "pl": "pol", "sv": "swe",
                      "el": "gre", "he": "heb", "fa": "per", "hi": "hin", "zh": "chi", "ja": "jpn", "ko": "kor" }
        return two[Qt.locale().name.substring(0, 2)] ?? "eng"
    }

    // the same file, however its name is encoded
    function _sameUrl(a, b) {
        return decodeURIComponent(String(a)) === decodeURIComponent(String(b))
    }

    // "The_Wand_S01E04.mp4" -> "The Wand S01E04"
    function _query(name) {
        return name.replace(/\.[^.]*$/, "").replace(/[._]+/g, " ").trim()
    }

    function _searchOnline() {
        const m = _onlineMedia
        if (!m || onlineQuery.text.trim() === "")
            return
        _online = []
        _onlineBusy = true
        _onlineStatus = qsTr("Searching OpenSubtitles...")
        PlayerTweaks.searchOnlineSubtitles(m.url, onlineQuery.text.trim(), _language)
    }

    on_OnlineMediaChanged: {
        if (_onlineMedia)
            onlineQuery.text = _query(_onlineMedia.name)
        _online = []
        _onlineStatus = ""
        if (origin === 1)
            Qt.callLater(_searchOnline)
    }

    onOriginChanged: {
        if (origin === 1 && _online.length === 0 && !_onlineBusy)
            Qt.callLater(_searchOnline)
    }

    Connections {
        target: PlayerTweaks

        function onOnlineSubtitlesReady(media, query, results, error) {
            if (!root._onlineMedia || !root._sameUrl(media, root._onlineMedia.url))
                return
            root._onlineBusy = false
            // made for this file first, then the most downloaded
            root._online = results.slice().sort((a, b) => (b.exact - a.exact) || (b.downloads - a.downloads))
            root._onlineStatus = error !== "" ? error
                                              : (results.length === 0 ? qsTr("No subtitles found. Try another name or language.") : "")
        }

        function onOnlineSubtitleDownloaded(media, file, error) {
            if (error !== "") {
                root._onlineStatus = error
                return
            }
            root._onlineStatus = ""
            const downloaded = Object.assign({}, root._downloaded)
            const key = root._media.find((m) => root._sameUrl(m.url, media))?.url ?? media
            downloaded[String(key)] = String(file)
            root._downloaded = downloaded
            root._setMatch(key, file)
            if (!root._subtitles.some((s) => String(s.url) === String(file)))
                root._subtitles = root._subtitles.concat([{ name: root._name(file), url: file }])
        }
    }

    // the file to give subtitles to: given when opened from the library
    // (see RedesignDialogs), otherwise what plays
    property var argument: undefined
    readonly property url _file: argument ? argument : Player.url

    readonly property url _folder: PlayerTweaks.parentFolder(_file)

    onOpened: _refresh()
    onTargetChanged: _refresh()

    function _name(url) {
        const path = decodeURIComponent(String(url))
        return path.substring(path.lastIndexOf("/") + 1)
    }

    function _refresh() {
        // the media to give subtitles to
        if (target === 0)
            _media = String(_file) !== "" ? [{ name: _name(_file), url: _file }] : []
        else if (target === 1)
            _media = PlayerTweaks.folderItems(_folder).filter((i) => !i.isDir && i.isVideo)
        else
            _media = PlayerTweaks.queueItems()

        // the subtitles next to them, and the ones already picked
        const known = {}
        const subtitles = []
        const add = (s) => { if (!known[String(s.url)]) { known[String(s.url)] = true; subtitles.push(s) } }
        for (const s of PlayerTweaks.subtitleFiles(_folder))
            add(s)
        for (const s of _subtitles)
            add(s)
        _subtitles = subtitles
        _autoMatch()
    }

    // "S01E04", "1x04" or the last number of a name
    function _episode(name) {
        let m = /s(\d{1,2})[ ._-]*e(\d{1,3})/i.exec(name) || /(\d{1,2})x(\d{2,3})/i.exec(name)
        if (m)
            return parseInt(m[1]) * 1000 + parseInt(m[2])
        const numbers = name.replace(/\.[^.]*$/, "").match(/\d+/g)
        return numbers ? parseInt(numbers[numbers.length - 1]) : -1
    }

    function _base(name) {
        return name.replace(/\.[^.]*$/, "").toLowerCase().replace(/[^a-z0-9]/g, "")
    }

    function _autoMatch() {
        const matches = {}
        for (const m of _media) {
            const remembered = PlayerTweaks.subtitleFor(m.url)
            if (String(remembered) !== "") {
                matches[String(m.url)] = String(remembered)
                if (!_subtitles.some((s) => String(s.url) === String(remembered)))
                    _subtitles = _subtitles.concat([{ name: _name(remembered), url: remembered }])
                continue
            }
            const base = _base(m.name)
            const episode = _episode(m.name)
            let best = ""
            let bestScore = 0
            for (const s of _subtitles) {
                let score = 0
                const sBase = _base(s.name)
                if (sBase.startsWith(base) || base.startsWith(sBase))
                    score = 3
                else if (episode >= 0 && _episode(s.name) === episode)
                    score = 2
                if (score > bestScore) {
                    bestScore = score
                    best = String(s.url)
                }
            }
            matches[String(m.url)] = best
        }
        _matches = matches
    }

    function _setMatch(media, subtitle) {
        const matches = Object.assign({}, _matches)
        matches[String(media)] = String(subtitle)
        _matches = matches
    }

    function _addFiles() {
        const urls = PlayerTweaks.chooseFiles(qsTr("Choose Subtitle Files"),
                                              qsTr("Subtitles (*.srt *.ass *.ssa *.vtt *.sub *.idx *.smi *.txt)"))
        if (urls.length === 0)
            return
        _subtitles = _subtitles.concat(urls.map((u) => ({ name: _name(u), url: u })))
        _autoMatch()
    }

    function save() {
        for (const m of _media) {
            const subtitle = (origin === 2 && _link !== "") ? _link : (_matches[String(m.url)] ?? "")
            if (subtitle !== "")
                PlayerTweaks.setSubtitleFor(m.url, subtitle)
        }
        close()
    }

    ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // to what, from where
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(10, VLCStyle.scale)
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.PanelComboBox {
                implicitWidth: VLCStyle.dp(200, VLCStyle.scale)
                model: [qsTr("To This File"), qsTr("To This Folder"), qsTr("To This Playlist")]
                selectedIndex: root.target
                onActivated: (index) => root.target = index
            }

            Widgets.PanelComboBox {
                implicitWidth: VLCStyle.dp(200, VLCStyle.scale)
                model: [qsTr("From Computer"), qsTr("From OpenSubtitles"), qsTr("From Link...")]
                selectedIndex: root.origin
                onActivated: (index) => root.origin = index
            }

            // what gets them
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.dp(30, VLCStyle.scale)
                visible: root.origin === 0
                text: {
                    if (root.target === 0)
                        return root._media.length > 0 ? root._media[0].name : qsTr("Nothing plays")
                    if (root.target === 2)
                        return qsTr("The queue, %1 items").arg(root._media.length)
                    const path = decodeURIComponent(String(root._folder)).replace(/^file:\/\/\/?/, "").split("/")
                    return path.slice(-3).join(" / ")
                }
                elide: Text.ElideLeft
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root._c.text
            }

            // OpenSubtitles: the name to search and the language
            Widgets.PanelSearchField {
                id: onlineQuery

                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                visible: root.origin === 1
                implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
                Keys.onReturnPressed: root._searchOnline()
                Keys.onEnterPressed: root._searchOnline()
            }

            Widgets.PanelComboBox {
                visible: root.origin === 1
                implicitWidth: VLCStyle.dp(170, VLCStyle.scale)
                model: root._languages.map((l) => l.name)
                selectedIndex: Math.max(0, root._languages.findIndex((l) => l.code === root._language))
                onActivated: (index) => {
                    root._language = root._languages[index].code
                    PlayerTweaks.setUiOption("opensubLanguage", root._language)
                    root._searchOnline()
                }
            }

            Widgets.PanelButton {
                visible: root.origin === 1
                text: qsTr("Search")
                iconName: "search"
                enabled: !root._onlineBusy
                onClicked: root._searchOnline()
            }

            Widgets.PanelTextField {
                id: linkField

                Layout.fillWidth: true
                implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
                visible: root.origin === 2
                placeholderText: qsTr("https://example.com/subtitles.srt")
                onTextChanged: root._link = text.trim()
            }

            Widgets.PanelButton {
                visible: root.origin === 0
                text: qsTr("Add Files")
                iconName: "add"
                onClicked: root._addFiles()
            }
        }

        // OpenSubtitles: the media on the left, the subtitles found for the
        // one chosen on the right; a click downloads one next to the media
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.origin === 1
            spacing: 0

            ListView {
                id: onlineMediaList

                Layout.preferredWidth: parent.width / 2
                Layout.fillHeight: true
                Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

                clip: true
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                model: root._media

                delegate: T.AbstractButton {
                    id: mediaRow

                    required property var modelData
                    required property int index

                    readonly property bool current: index === root._onlineIndex
                    readonly property bool done: !!root._downloaded[String(modelData.url)]

                    width: onlineMediaList.width
                    implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
                    hoverEnabled: true
                    onClicked: root._onlineIndex = index

                    background: Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: VLCStyle.dp(14, VLCStyle.scale)
                        anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: mediaRow.current ? PanelStyle.accentTint(theme.accent, theme.palette?.isDark ?? true)
                                                : (mediaRow.hovered ? root._c.hover : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    contentItem: RowLayout {
                        spacing: VLCStyle.dp(12, VLCStyle.scale)

                        Widgets.PanelIcon {
                            Layout.leftMargin: VLCStyle.dp(26, VLCStyle.scale)
                            name: mediaRow.done ? "check" : "video"
                            size: VLCStyle.dp(18, VLCStyle.scale)
                            color: mediaRow.done || mediaRow.current ? theme.accent : root._c.label
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
                            text: mediaRow.modelData.name
                            elide: Text.ElideMiddle
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            color: mediaRow.current ? root._c.bright : root._c.text
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: VLCStyle.border
                Layout.fillHeight: true
                color: root._c.separator
            }

            ListView {
                id: onlineResults

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

                clip: true
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                model: root._online

                delegate: T.AbstractButton {
                    id: resultRow

                    required property var modelData

                    readonly property bool chosen: String(root._matches[String(root._onlineMedia?.url ?? "")] ?? "") !== ""
                                                   && root._downloadedLink === modelData.link

                    width: onlineResults.width
                    implicitHeight: VLCStyle.dp(54, VLCStyle.scale)
                    hoverEnabled: true

                    onClicked: {
                        root._downloadedLink = modelData.link
                        root._onlineStatus = qsTr("Downloading %1...").arg(modelData.name)
                        PlayerTweaks.downloadOnlineSubtitle(root._onlineMedia.url, modelData.link,
                                                            modelData.languageId, modelData.format)
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                        anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: resultRow.hovered ? root._c.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    contentItem: RowLayout {
                        spacing: VLCStyle.dp(12, VLCStyle.scale)

                        Widgets.PanelIcon {
                            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
                            name: resultRow.chosen ? "check" : "subtitles"
                            size: VLCStyle.dp(18, VLCStyle.scale)
                            color: resultRow.chosen || resultRow.modelData.exact ? theme.accent : root._c.label
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)
                            spacing: VLCStyle.dp(3, VLCStyle.scale)

                            Text {
                                width: parent.width
                                text: resultRow.modelData.name
                                elide: Text.ElideMiddle
                                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                                color: resultRow.hovered ? root._c.bright : root._c.text
                            }

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: [resultRow.modelData.exact ? qsTr("Made for this file") : "",
                                       resultRow.modelData.language,
                                       qsTr("%1 downloads").arg(resultRow.modelData.downloads.toLocaleString())]
                                      .filter((t) => t !== "").join("  ·  ")
                                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                                color: resultRow.modelData.exact ? theme.accent : root._c.dim
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - VLCStyle.dp(60, VLCStyle.scale)
                    visible: onlineResults.count === 0 || root._onlineBusy
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root._onlineStatus !== "" ? root._onlineStatus
                                                    : (root._media.length === 0 ? qsTr("Play a video first.") : "")
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: root._c.dim
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(24, VLCStyle.scale)
            visible: root.origin === 2
            wrapMode: Text.WordWrap
            text: qsTr("The subtitles at this address are added to %1.").arg(
                      root.target === 0 ? qsTr("this file") : qsTr("each of these %1 media").arg(root._media.length))
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: root._c.label
        }

        // media -> subtitle
        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

            visible: root.origin === 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            model: root._media

            delegate: RowLayout {
                id: row

                required property var modelData

                readonly property string match: root._matches[String(modelData.url)] ?? ""

                width: list.width
                height: VLCStyle.dp(40, VLCStyle.scale)
                spacing: VLCStyle.dp(12, VLCStyle.scale)

                Widgets.PanelIcon {
                    Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
                    name: "video"
                    size: VLCStyle.dp(18, VLCStyle.scale)
                    color: root._c.label
                }

                Text {
                    Layout.preferredWidth: list.width / 2 - VLCStyle.dp(90, VLCStyle.scale)
                    text: row.modelData.name
                    elide: Text.ElideMiddle
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: root._c.text
                }

                // the dashes between a media and its subtitle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.border
                    color: row.match !== "" ? root._c.separatorBright : "transparent"
                }

                Widgets.PanelComboBox {
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    implicitWidth: VLCStyle.dp(470, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

                    readonly property var entries: [{ name: qsTr("No subtitles"), url: "" }].concat(root._subtitles)

                    model: entries.map((s) => s.name)
                    selectedIndex: entries.findIndex((s) => String(s.url) === row.match)
                    onActivated: (index) => root._setMatch(row.modelData.url, entries[index].url)
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - VLCStyle.dp(80, VLCStyle.scale)
                visible: list.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("Play a video first, or pick the folder or the playlist to give subtitles to.")
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root._c.dim
            }
        }

        Item { Layout.fillHeight: true; visible: root.origin === 2 }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border
            color: root._c.separator
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(70, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)

            Widgets.PanelButton {
                text: qsTr("Cancel")
                flat: true
                onClicked: root.close()
            }

            Item { Layout.fillWidth: true }

            Widgets.PanelButton {
                text: qsTr("Save")
                accent: true
                implicitWidth: VLCStyle.dp(96, VLCStyle.scale)
                enabled: root._media.length > 0 && (root.origin !== 2 || root._link !== "")
                onClicked: root.save()
            }
        }
    }
}
