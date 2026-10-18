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

    // "Customize Player": the groups of the title bar in frames, to be
    // moved around
    property bool editMode: false

    // the items of the title bar, arranged like the control bar
    readonly property PlayerControlbarModel titlebarModel:
        MainCtx.controlbarProfileModel.currentModel?.getModel(PlayerControlbarModel.Titlebar) ?? null

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

                TitlebarZone {
                    id: leftZone

                    anchors.verticalCenter: parent.verticalCenter
                    height: VLCStyle.dp(34, VLCStyle.scale)
                    visible: !root.editMode
                    zoneModel: root.titlebarModel?.left ?? null
                    focus: true
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
                    leftZone.forceActiveFocus()
                }
            }

            onVisibleChanged: {
                root.requestLockUnlockAutoHide(visible)
            }
        }
    }

    // the middle group of the title bar: the name of what plays
    Item {
        id: centerTitleText

        readonly property int _leftLimit: logoOrResume.x + logoOrResume.width
        readonly property int _rightLimit: root.showCSD ? csdDecorations.x : playlistGroup.x
        readonly property int _availableWidth: _rightLimit - _leftLimit - 2 * VLCStyle.margin_small
        readonly property int _centerX: ((root.width - centerTitleText.implicitWidth) / 2)
        readonly property bool _alignHCenter: _centerX > _leftLimit
                                              && _centerX + centerTitleText.implicitWidth < _rightLimit

        visible: (_showCenterText && root.resumeVisible === false && !root.editMode)

        enabled: visible

        implicitWidth: centerZone.implicitWidth
        width: Math.max(0, Math.min(centerTitleText._availableWidth, centerTitleText.implicitWidth))

        TitlebarZone {
            id: centerZone

            anchors.fill: parent
            zoneModel: root.titlebarModel?.center ?? null
        }

        on_AlignHCenterChanged: _layout()
        Component.onCompleted: _layout()

        function _layout() {
            if (_alignHCenter) {
                centerTitleText.x = 0
                centerTitleText.anchors.horizontalCenter = root.horizontalCenter
            } else {
                centerTitleText.anchors.horizontalCenter = undefined
                centerTitleText.x = Qt.binding(function() { return centerTitleText._leftLimit + VLCStyle.margin_small })
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

        onLoaded: {
            if ("beforeClose" in item)
                item.beforeClose = rightZoneComponent
        }

        Connections {
            target: csdDecorations.item
            enabled: csdDecorations.status === Loader.Ready
            function onButtonHoveredChanged() { root.requestLockUnlockAutoHide(csdDecorations.item.buttonHovered) }
        }
    }

    Component {
        id: rightZoneComponent

        TitlebarZone {
            visible: !root.editMode
            zoneModel: root.titlebarModel?.right ?? null
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

        // with the window buttons of the system: on the right
        TitlebarZone {
            anchors.verticalCenter: parent.verticalCenter
            height: VLCStyle.dp(34, VLCStyle.scale)
            visible: !root.showCSD && !root.editMode
            zoneModel: root.titlebarModel?.right ?? null
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
            Navigation.leftItem: leftZone
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
            Navigation.leftItem: menuSelector.visible ? menuSelector : leftZone

            onClicked: togglePlaylistVisibility()

            Accessible.onToggleAction:togglePlaylistVisibility()

            onHoveredChanged: root.requestLockUnlockAutoHide(hovered)
        }
    }

    // "Customize Player": the groups of the title bar in frames
    Loader {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: root.showCSD ? csdDecorations.left : parent.right
        anchors.leftMargin: root._sideMargin + VLCStyle.dp(40, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.margin_small
        height: VLCStyle.dp(40, VLCStyle.scale)
        z: 2

        active: root.editMode
        sourceComponent: ControlBarEditor {
            barModel: root.titlebarModel
            zoneHeight: VLCStyle.dp(34, VLCStyle.scale)
            centerEmptyText: qsTr("Title")
        }
    }

    // a group of items of the title bar
    component TitlebarZone: RowLayout {
        id: zone

        property var zoneModel: null

        spacing: VLCStyle.dp(4, VLCStyle.scale)

        ControlRepeater {
            id: zoneRepeater

            model: ControlListFilter {
                sourceModel: zone.zoneModel

                player: Player
                ctx: MainCtx
            }

            Navigation.parentItem: root

            onRequestLockUnlockAutoHide: (lock) => root.requestLockUnlockAutoHide(lock)

            Component.onCompleted: root.forceUnlock.connect(zoneRepeater.forceUnlock)
        }
    }
}
