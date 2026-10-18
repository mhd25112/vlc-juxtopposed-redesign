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

import VLC.MainInterface
import VLC.MediaLibrary

import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style
import VLC.Menus

// Videos as the folders on the disk, as in the design: "Videos > Shows >
// The Wand > S01". The folders of the current one come first, then its
// videos, in the grid or the list of the library.
Widgets.PageExt {
    id: root

    property alias currentIndex: videoAll.currentIndex

    // the folder shown, the top of the library when empty (given by the
    // history: History.push(["video", "folder"], { url: ... }))
    property url url
    readonly property url folder: url

    // from PlayerTweaks.requestLibraryFolder()
    property var _result: null
    property string _resultJson: ""
    readonly property var _folders: _result?.folders ?? []

    function openFolder(url) {
        History.push(["video", "folder"], { url: url })
    }

    // once, after the changes of a frame
    function _refresh() {
        Qt.callLater(root._request)
    }

    function _request() {
        PlayerTweaks.requestLibraryFolder("video", root.folder)
    }

    // the same folder, however its name is encoded
    function _sameFolder(a, b) {
        return decodeURIComponent(String(a)) === decodeURIComponent(String(b))
    }

    title: qsTr("Videos")

    // the path in the header
    folderCrumbs: (_result?.crumbs ?? []).map((c) => ({ text: c.name, path: ["video", "folder"], props: { url: c.url } }))
    headerExtraCount: _folders.length

    sortMenu: SortMenuVideo {
        ctx: MainCtx

        onGrouping: (grouping) => { MainCtx.grouping = grouping }
    }

    Component.onCompleted: _refresh()
    onFolderChanged: _refresh()

    Connections {
        target: PlayerTweaks

        function onLibraryFolderReady(kind, folder, result) {
            if (kind !== "video" || !root._sameFolder(folder, root.folder))
                return
            // only when it changed: the folders are not built again
            const json = JSON.stringify(result)
            if (json !== root._resultJson) {
                root._resultJson = json
                root._result = result
            }
        }
    }

    // the folders follow the library as it finds files
    Connections {
        target: MainCtx.mediaLibrary
        ignoreUnknownSignals: true

        function onIdleChanged() { refreshTimer.restart() }
        function onParsingProgressChanged() { refreshTimer.restart() }
    }

    Timer {
        id: refreshTimer
        interval: 1500
        onTriggered: root._refresh()
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    VideoAll {
        id: videoAll

        anchors.fill: parent

        focus: true

        displayMarginBeginning: root.displayMarginBeginning
        displayMarginEnd: root.displayMarginEnd
        enableBeginningFade: root.enableBeginningFade
        enableEndFade: root.enableEndFade

        sectionProperty: ""

        function isInfoExpandPanelAvailable(/* modelIndexData */) {
            return true
        }

        header: root._folders.length > 0 ? foldersHeader : null

        // a folder holding only folders is not empty
        emptyLabel: root._folders.length > 0 || root._result === null ? null : emptyComponent

        model: MLVideoModel {
            id: modelVideo

            ml: MediaLib
            // nothing until the folder is known (all the videos otherwise)
            parentId: root._result?.parentId ?? PlayerTweaks.emptyFolder()

            searchPattern: root.search.pattern
            sortOrder: root.sort.order
            sortCriteria: root.sort.criteria
        }

        contextMenu: MLContextMenu { model: modelVideo; showPlayAsAudioAction: true }
    }

    Component {
        id: emptyComponent

        Widgets.EmptyLabelButton {
            coverWidth : VLCStyle.dp(182, VLCStyle.scale)
            coverHeight: VLCStyle.dp(114, VLCStyle.scale)

            focus: true

            text: qsTr("No video found\nPlease try adding sources")

            cover: VLCStyle.noArtVideoCover

            Navigation.parentItem: root
        }
    }

    // the folders, laid out like the items of the view below them
    Component {
        id: foldersHeader

        Item {
            id: header

            readonly property Item view: videoAll.currentItem
            readonly property bool grid: MainCtx.gridView
            readonly property real leftMargin: view?.contentLeftMargin ?? VLCStyle.layout_left_margin
            readonly property real spacing: view?.horizontalSpacing ?? VLCStyle.dp(16, VLCStyle.scale)
            readonly property real cellWidth: view?.cellWidth ?? VLCStyle.dp(280, VLCStyle.scale)
            // the size of the pictures of the videos in their cells
            readonly property real pictureWidth: Math.min(view?.maxPictureWidth ?? cellWidth, cellWidth)
            readonly property real pictureHeight: Math.round(pictureWidth * 9 / 16)

            width: view?.width ?? root.width
            implicitHeight: flow.implicitHeight + (grid ? VLCStyle.dp(24, VLCStyle.scale) : VLCStyle.dp(8, VLCStyle.scale))

            Flow {
                id: flow

                x: header.leftMargin
                width: header.width - header.leftMargin - (header.view?.contentRightMargin ?? header.leftMargin)
                spacing: header.spacing

                Repeater {
                    model: root._folders

                    delegate: T.AbstractButton {
                        id: tile

                        required property var modelData

                        width: header.cellWidth
                        implicitHeight: header.grid ? (cover.height + VLCStyle.gridItemTitle_topMargin + nameLabel.implicitHeight
                                                       + VLCStyle.dp(4, VLCStyle.scale))
                                                    : VLCStyle.dp(36, VLCStyle.scale)

                        hoverEnabled: true
                        onClicked: root.openFolder(modelData.url)

                        background: Rectangle {
                            visible: !header.grid
                            radius: VLCStyle.dp(6, VLCStyle.scale)
                            color: tile.hovered ? root._c.hover : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        contentItem: Item {
                            // grid: a card with the folder, its name under it
                            Rectangle {
                                id: cover

                                visible: header.grid
                                width: header.pictureWidth
                                height: header.grid ? header.pictureHeight : 0
                                radius: VLCStyle.gridCover_radius
                                color: tile.hovered ? Qt.lighter(PanelStyle.colors(theme.palette?.isDark ?? true).card, 1.6)
                                                    : ((theme.palette?.isDark ?? true) ? "#1e1e1e" : root._c.card)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Widgets.PanelIcon {
                                    anchors.centerIn: parent
                                    name: "folder"
                                    size: VLCStyle.dp(40, VLCStyle.scale)
                                    color: tile.hovered ? root._c.bright : root._c.label
                                }
                            }

                            // list: a line with the folder and its name
                            Widgets.PanelIcon {
                                id: listIcon

                                visible: !header.grid
                                x: VLCStyle.dp(8, VLCStyle.scale)
                                anchors.verticalCenter: parent.verticalCenter
                                name: "folder"
                                size: VLCStyle.dp(22, VLCStyle.scale)
                                color: tile.hovered ? root._c.bright : root._c.label
                            }

                            Text {
                                id: nameLabel

                                x: header.grid ? 0 : listIcon.x + listIcon.width + VLCStyle.dp(14, VLCStyle.scale)
                                y: header.grid ? cover.height + VLCStyle.gridItemTitle_topMargin
                                               : Math.round((parent.height - height) / 2)
                                width: (header.grid ? header.pictureWidth : tile.width - x) - VLCStyle.dp(8, VLCStyle.scale)
                                text: tile.modelData.name
                                elide: Text.ElideRight
                                font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                                color: tile.hovered ? root._c.bright : root._c.text
                            }
                        }

                        Accessible.name: modelData.name
                    }
                }
            }
        }
    }
}
