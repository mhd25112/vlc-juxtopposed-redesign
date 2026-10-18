/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
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
import QtQml.Models

import VLC.Style
import VLC.Widgets as Widgets

import VLC.MainInterface
import VLC.Dialogs
import VLC.Util

T.Pane {
    id: root

    signal itemClicked(uri : var, item : Item)

    //safe area margins for delegate content,
    //so the background of the delegates fills the available space
    //but the content remains within the safe area
    property int safeAreaLeftMargin: 0
    property int safeAreaRightMargin: 0

    property bool useAcrylic: true

    property bool delegateShowText: true

    property alias model: navigationModel

    readonly property int minimumWidth: VLCStyle.expandNavigationPaneWidth + safeAreaLeftMargin + safeAreaRightMargin

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: VLCStyle.margin_normal

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Accessible.name: qsTr("Sidebar")

    NavigationModel {
        id: navigationModel
        hasMedialib: MainCtx.mediaLibraryAvailable
    }

    Connections {
        target: History

        // NOTE: handles cases where the path changes not by clicking in the sidebar
        function onViewPathChanged(viewPath) {
            for (let i = 0; i < listView.count; ++i) {
                const rowIndex = navigationModel.index(i, 0)
                const uri = navigationModel.data(rowIndex, NavigationModel.URI)

                if (uri && History.match(viewPath, uri)) {
                    // handle back button
                    listView.currentIndex = i

                    // handle keyboard navigation
                    if (!navigationModel.data(rowIndex, NavigationModel.EXPANDED))
                        navigationModel.setData(rowIndex, true, NavigationModel.EXPANDED)

                    return
                }
            }
        }
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    // a rounded panel a step lighter than the library
    background: Item {
        // the gap around the panel, as the library
        readonly property color color: (theme.palette?.isDark ?? true) ? PanelStyle.dark.panel : PanelStyle.light.panel

        Rectangle {
            anchors.fill: parent
            anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
            anchors.rightMargin: 0
            color: root._c.raised
            radius: VLCStyle.dp(8, VLCStyle.scale)
        }
    }

    readonly property var _icons: ({
        "home": "home",
        "video": "videos",
        "music": "music",
        "network": "network",
        "playlists": "playlists",
        "recent": "recent",
        "discover": "podcast"
    })

    contentItem:  Item {
        id: contentItemId

        //don't use Layout as top item as items put as children of the Control
        //would be parented (and layouted) to the Layout
        ColumnLayout {
            anchors.fill: parent
            spacing: VLCStyle.margin_xsmall

            Widgets.ListViewExt {
                id: listView

                // the pages, then "Add item" right under them as in the design
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: contentHeight
                Layout.maximumHeight: contentItemId.height - addButton.height

                clip: !fadingEdge.implicitClipping && (height < contentHeight)
                focus: true

                model: navigationModel

                Binding {
                    target: listView.T.ScrollBar.vertical
                    property: "policy"
                    when: listView.T.ScrollBar.vertical?.size > (1.0 - Number.EPSILON)
                    value: T.ScrollBar.AlwaysOff
                }

                colorContext.colorSet: ColorContext.Window

                fadingEdge.backgroundColor:  (root.background && (root.background.color.a >= 1.0)) ? root.background.color
                                                                                                   : "transparent"

                component DelegateAnimation : NumberAnimation {
                    easing.type: Easing.InOutSine
                    duration: VLCStyle.duration_long
                }

                reuseItems: false // Not relevant here, we disable it because of QTBUG-131106 when transition is involved.

                // As the docs note, `ListView` transitions do not seem to handle height animation. For that reason,
                // we animate the height directly in the delegate (Qt's recommended workaround). Because of this, we
                // do not need to have `addDisplaced` transition here, but we can have `removeDisplaced` here:
                removeDisplaced: Transition {
                    DelegateAnimation { property: "y" }
                }

                onCurrentIndexChanged: {
                    const rowIndex = navigationModel.index(currentIndex, 0)

                    if (rowIndex.valid && !navigationModel.data(rowIndex, NavigationModel.EXPANDED)
                            && History.match(History.viewPath, navigationModel.data(rowIndex, NavigationModel.URI)))
                        navigationModel.setData(rowIndex, true, NavigationModel.EXPANDED)
                }

                property bool readyForAnimations: false

                onModelChanged: {
                    if (!listView.readyForAnimations)
                        Qt.callLater(() => { listView.readyForAnimations = true })
                }

                Navigation.parentItem: root
                Navigation.downItem: preferenceButton

                delegate: SideNavigationDelegate {
                    id: delegate

                    width: ListView.view.contentWidth
                    height: preferredHeight

                    property real preferredHeight: shouldShow ? (depth === 0 ? VLCStyle.dp(46, VLCStyle.scale)
                                                                             : VLCStyle.dp(36, VLCStyle.scale)) : 0.0

                    leftPadding: root.safeAreaLeftMargin + VLCStyle.margin_xsmall
                    rightPadding: root.safeAreaRightMargin

                    leftInset: root.safeAreaLeftMargin + implicitLeftInset
                    rightInset: root.safeAreaRightMargin + implicitRightInset

                    iconTxt: icon_alias
                    iconName: (depth === 0 && uri && uri.length > 0) ? (root._icons[uri[0]] ?? "") : ""
                    text: title

                    showText: root.delegateShowText

                    required property string title
                    required property var uri
                    required property int depth
                    // TODO: Qt 6.2 has property `icon` marked final, so we can't override it:
                    required property string icon_alias
                    required property bool expandable
                    required property bool expanded

                    required property int index

                    visible: (height > 0.0)

                    // the pages of the design: no sub pages, no "Discover"
                    property bool shouldShow: (showText || (iconTxt.length > 0))
                                              && depth === 0 && !(uri && uri[0] === "discover")

                    onShouldShowChanged: {
                        if (listView.readyForAnimations)
                            heightBehavior.enabled = true // At this point, it can keep being enabled for good.
                    }

                    Binding on highlighted {
                        when: !!uri && History.match(History.viewPath, uri)
                        value: true
                    }
                    checked: (!showText || !expanded) && highlighted

                    onClicked: {
                        itemClicked(uri, this)
                        listView.currentIndex = index
                        listView.forceActiveFocus(focusReason)
                    }

                    Behavior on height {
                        id: heightBehavior

                        enabled: false

                        DelegateAnimation {
                            onRunningChanged: {
                                if (running) {
                                    delegate.clip = true
                                } else {
                                    delegate.clip = false
                                }
                            }
                        }
                    }

                    ListView.onAdd: {
                        if (listView.readyForAnimations && delegate.showText) {
                            heightBehavior.enabled = false
                            delegate.height = 0.0
                            heightBehavior.enabled = true
                            delegate.height = Qt.binding(() => delegate.preferredHeight)
                            heightBehavior.enabled = false
                        }
                    }
                }
            }

            Loader {
                id: loaderProgress

                Layout.fillWidth: true

                active: (MainCtx.mediaLibraryAvailable && MainCtx.mediaLibrary.idle === false)
                visible: active

                source: "qrc:///qt/qml/VLC/MediaLibrary/ScanProgressBar.qml"

                onLoaded: {
                    if (item.background) {
                        item.background.opacity = 0.6
                        item.background.radius = Qt.binding(() => VLCStyle.dp(4, VLCStyle.scale))
                    }

                    item.leftPadding = Qt.binding(function() { return root.safeAreaLeftMargin + VLCStyle.margin_small })
                    item.rightPadding = Qt.binding(function() { return root.safeAreaRightMargin + VLCStyle.margin_small })

                    item.leftInset = Qt.binding(() => { return VLCStyle.margin_xxsmall + root.safeAreaLeftMargin })
                    item.rightInset = Qt.binding(() => { return VLCStyle.margin_xxsmall + root.safeAreaRightMargin })
                }
            }

            // "Add item": a folder to the library, a network stream or a playlist
            SideNavigationDelegate {
                id: addButton

                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(46, VLCStyle.scale)

                leftPadding: root.safeAreaLeftMargin + VLCStyle.margin_xsmall
                rightPadding: root.safeAreaRightMargin

                iconName: "add"
                text: qsTr("Add item")
                showText: root.delegateShowText
                focusPolicy: Qt.StrongFocus

                onClicked: addMenu.popup(addButton.mapToGlobal(addButton.width, 0))

                Widgets.PanelMenu {
                    id: addMenu

                    model: [
                        { text: qsTr("Add a folder to the library"), icon: "folder" },
                        { text: qsTr("Open a network stream"), icon: "link" },
                        { text: qsTr("Create a playlist"), icon: "playlists" }
                    ]

                    onTriggered: (index) => {
                        switch (index) {
                        case 0: MainCtx.addLibraryFolder(); break
                        case 1: PlayerTweaks.requestDialog("network"); break
                        case 2: PlayerTweaks.requestDialog("playlist"); break
                        }
                    }
                }

                Navigation.parentItem: root
                Navigation.upItem: listView
                Navigation.downItem: preferenceButton
            }

            Item { Layout.fillHeight: true }

            SideNavigationDelegate {
                id: preferenceButton

                AccessibleCompat.id: "preferencesButton"

                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(46, VLCStyle.scale)

                leftPadding: root.safeAreaLeftMargin + VLCStyle.margin_xsmall
                rightPadding: root.safeAreaRightMargin

                leftInset: root.safeAreaLeftMargin + implicitLeftInset
                rightInset: root.safeAreaRightMargin + implicitRightInset

                iconName: "preferences"
                text: qsTr("Settings")

                // in the "..." menu in the design
                visible: false

                checked: DialogsProvider.prefsDialogVisible

                showText: root.delegateShowText

                onClicked: PlayerTweaks.requestDialog("settings")

                //SideNavigationDelegate is an ItemDelegate and has NoFocus by default
                focusPolicy: Qt.StrongFocus

                Navigation.parentItem: root
                Navigation.upItem: listView

                Keys.priority: Keys.AfterItem
                Keys.onPressed: (e) => Navigation.defaultKeyAction(e)
                Keys.onReleased: (e) => Navigation.defaultKeyReleaseAction(e)
            }

        }
    }
}
