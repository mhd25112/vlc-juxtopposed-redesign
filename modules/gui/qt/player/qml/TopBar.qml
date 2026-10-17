/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.PlayerControls
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util

FocusScope{
    id: root

    // Properties

    required property int textWidth

    // For now, used for d&d functionality
    // Not strictly necessary to set
    property Item plListView

    property int reservedHeight: 0

    property int topMargin: 0
    property int sideMargin: 0

    property string title

    property bool showCSD: false
    property bool showToolbar: false
    property bool pinControls: false

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    // Private

    property bool _showTopBar: (pinControls === false || showToolbar === false)

    property bool _showCenterText: (pinControls && showToolbar === false && showCSD)

    readonly property int _sideMargin: VLCStyle.margin_small + sideMargin

    // Aliases

    property alias resumeVisible: resumeDialog.visible

    property alias playlistVisible: playlistButton.checked

    // Signals

    signal togglePlaylistVisibility()
    // the library next to the video, see CompactLibrary
    signal toggleLibrary()
    property bool libraryVisible: false
    signal requestLockUnlockAutoHide(bool lock)
    signal backRequested()

    ///incomming signal to request all menu and popup to close
    signal forceUnlock()

    // Settings

    Accessible.role: Accessible.ToolBar
    Accessible.name: qsTr("Player topbar")
    AccessibleCompat.id: "playerTopBar"

    // Events

    Component.onCompleted: _layout()

    onShowCSDChanged: _layout()
    onPinControlsChanged: _layout()
    onShowToolbarChanged: _layout()
    onTopMarginChanged: _layout()
    onSideMarginChanged: _layout()

    on_ShowTopBarChanged: _layout()
    on_ShowCenterTextChanged: _layout()

    // Functions

    // FIXME: Imperative layouting in QML is stupid, this needs to be gone.
    function _layoutLine(c1, c2, offset)
    {
        let c1Height = c1?.implicitHeight ?? 0
        let c2Height = c2?.implicitHeight ?? 0

        if (c2 === csdDecorations) {
            //csdDecorations.implicitHeight gets overwritten when the height is set,
            //VLCStyle.icon_normal is its initial value
            c2Height = VLCStyle.icon_normal
        }

        const lineHeight = Math.max(c1Height, c2Height)

        if (c1) {
            c1.height = lineHeight
            c1.anchors.topMargin = offset
        }

        if (c2) {
            c2.height = lineHeight
            c2.anchors.topMargin = offset
        }
        return lineHeight
    }

    // FIXME: Imperative layouting in QML is stupid, this needs to be gone.
    //FIXME: if CSD will be weirdly placed if application safe-area are used,
    //nota that if you need a safe area (kiosk mode), you probably don't need CSD
    function _layout() {
        let offset = topMargin

        if (_showCenterText) {
            //place everything on one line
            //csdDecorations.implicitHeight gets overwritten when the height is set,
            //VLCStyle.icon_normal is its initial value
            const lineHeight = Math.max(logoOrResume.implicitHeight, playlistGroup.implicitHeight, VLCStyle.icon_normal)

            centerTitleText.y = 0
            centerTitleText.height = lineHeight

            csdDecorations.height  = lineHeight

            logoOrResume.height =  lineHeight

            playlistGroup.height = lineHeight
            playlistGroup.anchors.topMargin = 0
            playlistGroup.extraRightMargin = Qt.binding(function() { return width - csdDecorations.x })


            implicitHeight = lineHeight
            offset += lineHeight

        } else {
            playlistGroup.extraRightMargin = 0

            let left = undefined
            let right = undefined
            let logoPlaced = false

            if (showToolbar) {
                left = menubar
            }

            if (showCSD) {
                right = csdDecorations
                if (!left) {
                    left = logoOrResume
                    logoPlaced = true
                }
            }

            if (!!left || !!right) {
                offset += _layoutLine(left, right, offset)

                if (showCSD) {
                    tapNDrag.height = offset
                }
            }

            if (!logoPlaced) {
                left = logoOrResume
            } else {
                left = undefined
            }

            if (_showTopBar)
                right = playlistGroup
            else
                right = undefined

            offset += _layoutLine(left, right, offset)
        }

        implicitHeight = offset
        reservedHeight = offset
    }

    // Children

    //drag and dbl click the titlebar in CSD mode
    Loader {
        id: tapNDrag

        anchors.fill: parent
        active: root.showCSD
        source: "qrc:///qt/qml/VLC/Widgets/CSDTitlebarTapNDrapHandler.qml"

        Connections {
            target: tapNDrag.item
            enabled: tapNDrag.status === Loader.Ready
            function onCsdMenuVisibleChanged() {
                root.requestLockUnlockAutoHide(tapNDrag.item.csdMenuVisible)
            }
        }
    }

    // Components -
    Menus.Menubar {
        id: menubar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.sideMargin
        anchors.right: root.showCSD ? csdDecorations.left : parent.right


        visible: root.showToolbar
        enabled: root.showToolbar

        onHoveredChanged: menu => root.requestLockUnlockAutoHide(hovered)
        onMenuOpenedChanged: menu => root.requestLockUnlockAutoHide(menuOpened)
        onImplicitHeightChanged: root._layout()
    }

    Item {
        id: logoOrResume

        anchors.left: root.left
        anchors.top: root.top
        anchors.leftMargin:  root._sideMargin

        implicitWidth: resumeVisible ? resumeDialog.implicitWidth
                                     : logoGroup.implicitWidth

        implicitHeight: {
            if (root.resumeVisible) {
                // Only if there are multiple lines use `resumeDialog`'s implicit height, otherwise the video
                // window may get resized by few pixels unnecessarily when `resumeDialog` is no longer visible.
                if (resumeDialog.implicitHeight >= (logoGroup.implicitHeight + resumeDialog.baselineOffset))
                    return resumeDialog.implicitHeight
                else
                    return logoGroup.implicitHeight
            } else if (_showTopBar)
                return logoGroup.implicitHeight
            else
                return 0
        }

        onImplicitHeightChanged: root._layout()

        Item {
            id: logoGroup

            anchors.fill: parent

            visible: (root._showTopBar && root.resumeVisible === false)

            implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
            implicitWidth: leftRow.implicitWidth

            Row {
                id: leftRow

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Widgets.BannerCone {
                    id: logo

                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(30, VLCStyle.scale)
                    height: VLCStyle.dp(22, VLCStyle.scale)
                    sourceSize.width: VLCStyle.dp(22, VLCStyle.scale)
                    sourceSize.height: VLCStyle.dp(22, VLCStyle.scale)
                    color: theme.accent
                }

                Widgets.SvgToolButton {
                    id: backBtn

                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "more"
                    description: qsTr("Menu")
                    AccessibleCompat.id: "topBarMenuButton"
                    width: VLCStyle.dp(34, VLCStyle.scale)
                    height: VLCStyle.dp(34, VLCStyle.scale)
                    checked: mainMenu.visible

                    focus: true

                    Navigation.parentItem: root
                    Navigation.rightItem: libraryButton

                    onClicked: mainMenu.show(backBtn)
                    onHoveredChanged: root.requestLockUnlockAutoHide(hovered)

                    Widgets.AppMainMenu {
                        id: mainMenu
                        onOpened: root.requestLockUnlockAutoHide(true)
                        onClosed: root.requestLockUnlockAutoHide(false)
                    }
                }

                Widgets.SvgToolButton {
                    id: libraryButton

                    anchors.verticalCenter: parent.verticalCenter
                    iconName: root.libraryVisible ? "sidebar_open" : "sidebar"
                    description: qsTr("Library")
                    checked: root.libraryVisible
                    width: VLCStyle.dp(34, VLCStyle.scale)
                    height: VLCStyle.dp(34, VLCStyle.scale)

                    Navigation.parentItem: root
                    Navigation.leftItem: backBtn
                    Navigation.rightItem: folderButton

                    onClicked: root.toggleLibrary()
                    onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.border
                    height: VLCStyle.dp(18, VLCStyle.scale)
                    color: PanelStyle.colors((theme.palette?.isDark ?? true)).separatorBright
                    visible: folderButton.visible
                }

                // the folder of what plays: the familiar name of the show,
                // it opens the library there
                T.AbstractButton {
                    id: folderButton

                    readonly property string folder: {
                        const url = decodeURIComponent(String(Player.url))
                        const parts = url.split(/[\\/]/).filter((p) => p !== "")
                        return parts.length > 1 ? parts[parts.length - 2] : ""
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    visible: folder !== "" && !folder.endsWith(":")
                    implicitWidth: folderRow.implicitWidth + VLCStyle.dp(16, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(30, VLCStyle.scale)

                    onClicked: root.toggleLibrary()
                    onHoveredChanged: root.requestLockUnlockAutoHide(hovered)

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: folderButton.hovered ? PanelStyle.colors((theme.palette?.isDark ?? true)).hover : "transparent"
                    }

                    contentItem: Item {
                        Row {
                            id: folderRow

                            anchors.centerIn: parent
                            spacing: VLCStyle.dp(8, VLCStyle.scale)

                            Widgets.PanelIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "folder"
                                size: VLCStyle.dp(18, VLCStyle.scale)
                                color: PanelStyle.colors((theme.palette?.isDark ?? true)).label
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: folderButton.folder
                                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                                color: folderButton.hovered ? PanelStyle.colors((theme.palette?.isDark ?? true)).bright
                                                            : PanelStyle.colors((theme.palette?.isDark ?? true)).text
                            }
                        }
                    }

                    Accessible.name: qsTr("Open %1 in the library").arg(folder)
                }
            }
        }

        ResumeDialog {
            id: resumeDialog

            // see ResumePrompt in Player
            active: false

            anchors.fill: parent
            //add aditional margin so it align with menubar text when visible (see MenuBar.qml)
            anchors.leftMargin: VLCStyle.margin_xsmall

            maxWidth: ((root.showCSD && !root.pinControls) ? csdDecorations : playlistGroup).x
                - VLCStyle.applicationHorizontalMargin
                - VLCStyle.margin_large

            colorContext.palette: theme.palette

            Navigation.parentItem: rootPlayer

            onHidden: {
                if (activeFocus) {
                    backBtn.forceActiveFocus()
                }
            }

            onVisibleChanged: {
                root.requestLockUnlockAutoHide(visible)
            }
        }
    }

    //FIXME use the the right class
    T.Label {
        id: centerTitleText

        readonly property int _leftLimit: logoOrResume.x + logoOrResume.width
        readonly property int _rightLimit: playlistGroup.x
        readonly property int _availableWidth: _rightLimit - _leftLimit
        readonly property int _centerX: ((root.width - centerTitleText.implicitWidth) / 2)
        readonly property bool _alignHCenter: _centerX > _leftLimit
                                              && _centerX + centerTitleText.implicitWidth < _rightLimit

        visible: (_showCenterText && root.resumeVisible === false)

        enabled: visible

        width: Math.min(centerTitleText._availableWidth, centerTitleText.implicitWidth)

        leftPadding: VLCStyle.margin_small
        rightPadding: VLCStyle.margin_small

        text: root.title
        color: PanelStyle.colors((theme.palette?.isDark ?? true)).text
        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter

        on_AlignHCenterChanged: _layout()
        Component.onCompleted: _layout()

        function _layout() {
            if (_alignHCenter) {
                centerTitleText.x = 0
                centerTitleText.anchors.horizontalCenter = root.horizontalCenter
            } else {
                centerTitleText.anchors.horizontalCenter = undefined
                centerTitleText.x = Qt.binding(function() { return centerTitleText._leftLimit })
            }
        }
    }

    //FIXME use the the right class
    T.Label {
        id: leftTitleText

        anchors.left: parent.left
        anchors.top: logoOrResume.bottom
        anchors.leftMargin: root._sideMargin

        width: root.textWidth - VLCStyle.margin_normal

        visible: !root.pinControls

        enabled: visible

        topPadding: VLCStyle.margin_large
        leftPadding: logo.x

        text: root.title
        horizontalAlignment: Text.AlignLeft
        color: theme.fg.primary
        font.weight: Font.DemiBold
        font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
        elide: Text.ElideRight
    }

    Loader {
        id: csdDecorations

        anchors.top: parent.top
        anchors.right: parent.right

        focus: false
        height: VLCStyle.icon_normal
        active: root.showCSD
        enabled: root.showCSD
        visible: root.showCSD
        source:  VLCStyle.palette.hasCSDImage
            ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
            : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"

        Connections {
            target: csdDecorations.item
            enabled: csdDecorations.status === Loader.Ready
            function onButtonHoveredChanged() { root.requestLockUnlockAutoHide(csdDecorations.item.buttonHovered) }
        }
    }

    Row {
        id: playlistGroup

        property int extraRightMargin: 0

        focus: true
        spacing: VLCStyle.margin_xxsmall

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: root._sideMargin + extraRightMargin

        visible: root._showTopBar

        Widgets.SvgToolButton {
            anchors.verticalCenter: parent.verticalCenter
            iconName: "pip"
            description: qsTr("Picture in picture")
            width: VLCStyle.dp(36, VLCStyle.scale)
            height: VLCStyle.dp(34, VLCStyle.scale)
            visible: root.showCSD && MainCtx.canShowVideoPIP
            onClicked: root.backRequested()
            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
        }

        Widgets.SvgToolButton {
            anchors.verticalCenter: parent.verticalCenter
            iconName: "fullscreen"
            description: qsTr("Fullscreen")
            width: VLCStyle.dp(36, VLCStyle.scale)
            height: VLCStyle.dp(34, VLCStyle.scale)
            visible: root.showCSD
            onClicked: MainCtx.toggleInterfaceFullScreen()
            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
        }

        Widgets.IconToolButton {
            id: menuSelector

            anchors.verticalCenter: parent.verticalCenter
            visible: false
            enabled: visible
            focus: visible
            font.pixelSize: VLCStyle.icon_banner

            width: VLCStyle.bannerButton_width
            height: VLCStyle.bannerButton_height

            text: VLCIcons.more
            description: qsTr("Menu")

            AccessibleCompat.id: "topBarMenuButton"

            checked: contextMenu.shown

            Navigation.parentItem: root
            Navigation.leftItem: backBtn
            Navigation.rightItem: playlistButton

            onClicked: contextMenu.popup(this.mapToGlobal(0, height))

            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)

            Menus.QmlGlobalMenu {
                id: contextMenu

                ctx: MainCtx

                onAboutToShow: root.requestLockUnlockAutoHide(true)
                onAboutToHide: root.requestLockUnlockAutoHide(false)
            }

            Connections {
                target: root

                function onForceUnlock() {
                    contextMenu.close()
                }
            }
        }

        PlaylistPane.PlaylistToggleButton {
            id: playlistButton

            // the queue opens from the control bar
            visible: false
            anchors.verticalCenter: parent.verticalCenter
            objectName: ControlListModel.PLAYLIST_BUTTON
            font.pixelSize: VLCStyle.icon_banner
            text: VLCIcons.playlist
            description: qsTr("Play Queue")

            AccessibleCompat.id: "topBarPlayqueueButton"

            focus: root.showToolbar

            width: VLCStyle.bannerButton_width
            height: VLCStyle.bannerButton_height

            plListView: root.plListView
            
            Navigation.parentItem: root
            Navigation.leftItem: menuSelector.visible ? menuSelector : backBtn

            onClicked: togglePlaylistVisibility()

            Accessible.onToggleAction:togglePlaylistVisibility()

            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
        }
    }
}
