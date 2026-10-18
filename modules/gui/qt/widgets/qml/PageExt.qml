/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
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
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Menus
import VLC.Util
import VLC.Dialogs

T.Page {
    id: root

    //path of the current page loader
    property var pagePrefix: []

    // the path of a page showing a folder of the disk, after the name of the
    // section: [{ text, path, props }]
    property var folderCrumbs: null
    // items of the page that are not in its model (folders)
    property int headerExtraCount: 0

    //note that T.Page introduce an intermediate Item, so to access our delegate,
    //we need to use contentChildren[0] rather than contentItem
    readonly property Item _firstChild: contentChildren[0] ?? null

    //indicates whether the subview support grid/list mode
    property bool hasGridListMode: _firstChild?.hasGridListMode ?? false

    property bool isSearchable: _firstChild?.isSearchable ?? false

    property var sortModel: _firstChild?.sortModel ?? null

    //property is *not* readOnly, a PageLoader may define a localMenuDelegate common for its subviews (music, video)
    property SortMenu sortMenu: null

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    property bool enableBeginningFade: true
    property bool enableEndFade: true

    readonly property SearchCtx search: _searchCtx
    readonly property SortCtx sort: _sortCtx


    SearchCtx {
        id: _searchCtx
        available: root.isSearchable
    }

    SortCtx {
        id: _sortCtx

        readonly property string _sortCriteriaKey: ["sortCriteria", ...root.pagePrefix].join("/")
        readonly property string _sortOrderKey:  ["sortOrder", ...root.pagePrefix].join("/")

        available: Helpers.isArray(root.sortModel) && (root.sortModel).length > 0
        model: root.sortModel

        //save & restore setting of the page
        Component.onCompleted: {
            const criteria = MainCtx.settingValue(_sortCriteriaKey, undefined)
            if (criteria !== undefined)
                _sortCtx.criteria = criteria

            const order = MainCtx.settingValue(_sortOrderKey, undefined)
            if (order !== undefined)
                _sortCtx.order = parseInt(order)
        }

        Component.onDestruction: {
            MainCtx.setSettingValue(_sortCriteriaKey, _sortCtx.criteria)
            MainCtx.setSettingValue(_sortOrderKey, _sortCtx.order)
        }
    }

    Binding {
        target: MainCtx
        property: "hasGridListMode";
        value: root.hasGridListMode
    }

    on_FirstChildChanged: {
        if (!_firstChild)
            return
        _firstChild.Navigation.parentItem = root
        _firstChild.Navigation.upItem = root.header
    }

    function positionContentAtBeginning() {
        _firstChild?.positionContentAtBeginning?.()
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    header: DefaultPageHeader {
        text: root.title

        leftPadding: VLCStyle.dynamicAppMargins(width) + VLCStyle.layout_left_margin + root.leftPadding
        rightPadding: VLCStyle.dynamicAppMargins(width) + VLCStyle.layout_right_margin + root.rightPadding

        sortMenu: root.sortMenu

        search: _searchCtx
        sort: _sortCtx

        Navigation.parentItem: root
        Navigation.downAction: function() {
            if (typeof root.setCurrentItemFocus === "function")
                root.setCurrentItemFocus(Qt.TabFocusReason)
            else if (typeof root._firstChild?.setCurrentItemFocus === "function")
             root._firstChild.setCurrentItemFocus(Qt.TabFocusReason)
            else if (root._firstChild)
                root._firstChild.forceActiveFocus(Qt.TabFocusReason)
        }
    }

    // Header of the redesigned library: back and forward, the path of the
    // page (each part goes back to it), the number of items, then sorting,
    // grid or list, search, add and more.
    component DefaultPageHeader: T.ToolBar {
        id: defaultPageHeader

        // Properties

        property string text
        property SortMenu sortMenu
        property SearchCtx search
        property SortCtx sort

        readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

        readonly property var _names: ({
            "home": qsTr("Home"),
            "video": qsTr("Videos"),
            "music": qsTr("Music"),
            "network": qsTr("Network"),
            "playlists": qsTr("Playlists"),
            "recent": qsTr("Recent"),
            "discover": qsTr("Discover"),
            "all": qsTr("All"),
            "tracks": qsTr("Songs"),
            "albums": qsTr("Albums"),
            "artists": qsTr("Artists"),
            "genres": qsTr("Genres"),
            "services": qsTr("Services"),
            "url": qsTr("URL"),
            "mlsettings": qsTr("Folders")
        })

        // [{ text, path, props }]
        readonly property var _crumbs: {
            const path = History.viewPath
            if (root.folderCrumbs !== null && path.length > 0 && _names[path[0]] !== undefined)
                return [{ text: _names[path[0]], path: [path[0]] }].concat(root.folderCrumbs)
            const crumbs = []
            for (let i = 0; i < path.length; ++i) {
                let name = _names[path[i]]
                if (name === undefined) {
                    // a page of its own (an album, a playlist, a folder): its title
                    if (i === path.length - 1)
                        name = defaultPageHeader.text || History.viewProp.title || ""
                    else
                        continue
                }
                if (name === "" || (crumbs.length > 0 && crumbs[crumbs.length - 1].text === name))
                    continue
                crumbs.push({ text: name, path: path.slice(0, i + 1) })
            }
            if (crumbs.length === 0 && defaultPageHeader.text !== "")
                crumbs.push({ text: defaultPageHeader.text, path: path })
            return crumbs
        }

        property int _count: -1

        function _updateCount() {
            const model = root._firstChild?.model
            if (model && typeof model.rowCount === "function")
                _count = model.rowCount()
            else
                _count = -1
        }

        Connections {
            target: (root._firstChild?.model && typeof root._firstChild.model.rowCount === "function")
                    ? root._firstChild.model : null
            ignoreUnknownSignals: true
            function onRowsInserted() { defaultPageHeader._updateCount() }
            function onRowsRemoved() { defaultPageHeader._updateCount() }
            function onModelReset() { defaultPageHeader._updateCount() }
            function onLayoutChanged() { defaultPageHeader._updateCount() }
        }

        Connections {
            target: root
            function on_FirstChildChanged() { Qt.callLater(defaultPageHeader._updateCount) }
        }

        Component.onCompleted: Qt.callLater(_updateCount)

        position: T.ToolBar.Header

        topPadding: VLCStyle.dp(12, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(12, VLCStyle.scale)

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        Navigation.navigable: true

        readonly property ColorContext colorContext: ColorContext {
            id: theme
            colorSet: ColorContext.View
        }

        background: Rectangle {
            color: theme.bg.primary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: defaultPageHeader.leftPadding
                anchors.rightMargin: defaultPageHeader.rightPadding
                height: VLCStyle.border
                color: defaultPageHeader._c.separator
            }
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(6, VLCStyle.scale)

            SvgToolButton {
                iconName: "arrow_left"
                description: qsTr("Back")
                enabled: !History.previousEmpty
                onClicked: History.previous()
            }

            SvgToolButton {
                iconName: "arrow_right"
                description: qsTr("Forward")
                enabled: !History.nextEmpty
                onClicked: History.next()
            }

            // address line
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: crumbRow.implicitHeight
                Layout.leftMargin: VLCStyle.dp(10, VLCStyle.scale)

                contentWidth: crumbRow.implicitWidth
                contentX: Math.max(0, contentWidth - width)
                interactive: contentWidth > width
                clip: true

                Row {
                    id: crumbRow

                    spacing: VLCStyle.dp(4, VLCStyle.scale)

                    Repeater {
                        model: defaultPageHeader._crumbs

                        delegate: Row {
                            required property int index
                            required property var modelData

                            readonly property bool last: index === defaultPageHeader._crumbs.length - 1

                            spacing: VLCStyle.dp(4, VLCStyle.scale)

                            PanelIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index > 0
                                name: "caret_right"
                                size: VLCStyle.dp(14, VLCStyle.scale)
                                color: defaultPageHeader._c.dim
                            }

                            T.AbstractButton {
                                id: crumb

                                enabled: !last
                                implicitWidth: crumbText.implicitWidth
                                implicitHeight: crumbText.implicitHeight
                                onClicked: History.push(modelData.path, modelData.props ?? {})

                                contentItem: Text {
                                    id: crumbText
                                    text: modelData.text
                                    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                                    font.weight: last ? Font.DemiBold : Font.Normal
                                    color: last ? defaultPageHeader._c.bright
                                                : (crumb.hovered ? defaultPageHeader._c.bright : defaultPageHeader._c.text)
                                }

                                Accessible.name: modelData.text
                            }
                        }
                    }
                }
            }

            Text {
                Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                readonly property int total: defaultPageHeader._count + root.headerExtraCount
                visible: defaultPageHeader._count >= 0
                text: total === 1 ? qsTr("1 item") : qsTr("%1 items").arg(total)
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: defaultPageHeader._c.label
            }

            SvgToolButton {
                id: sortButton

                readonly property bool _sorted: !!defaultPageHeader.sort && defaultPageHeader.sort.criteria !== ""
                                                && defaultPageHeader.sort.criteria !== (root.sortModel?.[0]?.criteria ?? "")

                visible: !!defaultPageHeader.sort && defaultPageHeader.sort.available
                iconName: "sort"
                description: qsTr("Sort")
                checked: sortMenu.visible

                onClicked: {
                    const entries = []
                    const sortCtx = defaultPageHeader.sort
                    for (const m of root.sortModel) {
                        if (m.criteria === "playcount") {
                            entries.push({ text: qsTr("Unwatched First"),
                                           checked: sortCtx.criteria === "playcount" && sortCtx.order === Qt.AscendingOrder,
                                           action: () => { sortCtx.criteria = "playcount"; sortCtx.order = Qt.AscendingOrder } })
                            entries.push({ text: qsTr("Watched First"),
                                           checked: sortCtx.criteria === "playcount" && sortCtx.order === Qt.DescendingOrder,
                                           action: () => { sortCtx.criteria = "playcount"; sortCtx.order = Qt.DescendingOrder } })
                            continue
                        }
                        const current = sortCtx.criteria === m.criteria
                        entries.push({ text: m.text + (current ? (sortCtx.order === Qt.AscendingOrder ? "  ↑" : "  ↓") : ""),
                                       checked: current,
                                       action: () => {
                                           if (sortCtx.criteria === m.criteria) {
                                               sortCtx.order = (sortCtx.order === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder
                                           } else {
                                               sortCtx.criteria = m.criteria
                                               sortCtx.order = Qt.AscendingOrder
                                           }
                                       } })
                    }
                    sortMenu.model = entries
                    sortMenu.popupNextTo(sortButton, false)
                }

                // a dot tells the items are not in their usual order
                Rectangle {
                    visible: sortButton._sorted
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                    width: VLCStyle.dp(6, VLCStyle.scale)
                    height: width
                    radius: width / 2
                    color: theme.accent
                }

                PanelMenu {
                    id: sortMenu
                    menuWidth: VLCStyle.dp(240, VLCStyle.scale)
                }
            }

            SvgToolButton {
                visible: MainCtx.hasGridListMode
                iconName: MainCtx.gridView ? "grid" : "list"
                description: MainCtx.gridView ? qsTr("Grid view, show as a list") : qsTr("List view, show as a grid")
                onClicked: MainCtx.gridView = !MainCtx.gridView
            }

            PanelSearchField {
                Layout.preferredWidth: Math.min(VLCStyle.dp(320, VLCStyle.scale), defaultPageHeader.width / 4)
                Layout.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                visible: !!defaultPageHeader.search && defaultPageHeader.search.available

                onPatternChanged: {
                    if (defaultPageHeader.search)
                        defaultPageHeader.search.pattern = pattern
                }

                Connections {
                    target: defaultPageHeader.search
                    function onAskShow() { parent.forceActiveFocus() }
                }
            }

            SvgToolButton {
                id: addButton

                iconName: "add"
                description: qsTr("Add")
                checked: addMenu.visible
                onClicked: addMenu.popupNextTo(addButton, false)

                PanelMenu {
                    id: addMenu

                    menuWidth: VLCStyle.dp(280, VLCStyle.scale)
                    model: [
                        { text: qsTr("Open File(s)"), icon: "file", shortcut: "Ctrl + O", action: () => DialogsProvider.simpleOpenDialog() },
                        { text: qsTr("Add a Folder to the Library"), icon: "folder", action: () => MainCtx.addLibraryFolder() },
                        { text: qsTr("Open Network Stream"), icon: "link", shortcut: "Ctrl + N", action: () => PlayerTweaks.requestDialog("network") },
                        { text: qsTr("Create Playlist"), icon: "playlists", action: () => PlayerTweaks.requestDialog("playlist") }
                    ]
                }
            }

            SvgToolButton {
                id: moreButton

                iconName: "more"
                description: qsTr("More")
                checked: moreMenu.visible
                onClicked: moreMenu.popupNextTo(moreButton, false)

                PanelMenu {
                    id: moreMenu

                    menuWidth: VLCStyle.dp(260, VLCStyle.scale)
                    model: [
                        { text: MainCtx.gridView ? qsTr("Show as a List") : qsTr("Show as a Grid"), icon: MainCtx.gridView ? "list" : "grid",
                          enabled: MainCtx.hasGridListMode, action: () => { MainCtx.gridView = !MainCtx.gridView } },
                        ...(History.viewPath[0] === "video"
                            ? (History.viewPath[1] === "all"
                               ? [{ text: qsTr("Show Folders"), icon: "folder", action: () => History.push(["video", "folder"]) }]
                               : [{ text: qsTr("All Videos"), icon: "videos", action: () => History.push(["video", "all"]) }])
                            : []),
                        { text: qsTr("Rescan the Library"), icon: "rotate", action: () => MainCtx.mediaLibrary.reload() },
                        { separator: true },
                        { text: qsTr("Library Settings"), icon: "preferences", action: () => PlayerTweaks.requestDialog("settings", "library") }
                    ]
                }
            }
        }
    }
}
