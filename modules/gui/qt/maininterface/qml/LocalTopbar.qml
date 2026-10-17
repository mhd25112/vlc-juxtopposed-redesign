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
import QtQml.Models
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Menus as Menus
import VLC.Util
import VLC.Player

T.ToolBar {
    id: root

    Accessible.name: qsTr("Local top bar")
    AccessibleCompat.id: "localTopbar"

    property bool useAcrylic: true

    // For now, used for d&d functionality
    // Not strictly necessary to set
    property Item plListView

    property bool _showCSD: MainCtx.clientSideDecoration
        && !(MainCtx.intfMainWindow.visibility === Window.FullScreen)
        && !MainCtx.hasToolbarMenu

    //whether the navigation pannel is actually visible or not
    property alias navigationVisible: navigationVisibilty.checked
    property alias playqueueVisible: playlistBtn.checked

    property alias navigationButton: navigationVisibilty

    signal toggleNavigationVisibility()
    signal togglePlayqueueVisibility()

    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                             implicitContentWidth + leftPadding + rightPadding + (_showCSD ? csdButtons.implicitWidth : 0))

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    // solid, like the title bar of the redesign
    background: Rectangle {
        color: theme.bg.primary
    }

    // Title bar of the redesign: the cone, the main menu and the navigation
    // toggle on the left, what plays in the middle, the window buttons on the
    // right.
    contentItem: Item {
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
        implicitWidth: navigationButtons.implicitWidth + VLCStyle.margin_xsmall * 2

        Item {
            id: navigationButtons

            implicitWidth: navigationButtonsRow.implicitWidth

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: VLCStyle.margin_xsmall
            }

            Navigation.parentItem: root

            Row {
                id: navigationButtonsRow

                anchors.verticalCenter: parent.verticalCenter

                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Navigation.parentItem: root
                Navigation.rightItem: playqueueButtonsTop

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
                    id: menuBtn

                    focus: true
                    iconName: "more"
                    description: qsTr("Menu")
                    checked: mainMenu.visible
                    width: VLCStyle.dp(34, VLCStyle.scale)
                    height: VLCStyle.dp(34, VLCStyle.scale)

                    onClicked: mainMenu.show(menuBtn)

                    Widgets.AppMainMenu {
                        id: mainMenu
                    }

                    Navigation.parentItem: navigationButtons
                    Navigation.rightItem: navigationVisibilty
                }

                Widgets.SvgToolButton {
                    id: navigationVisibilty

                    iconName: checked ? "sidebar_open" : "sidebar"
                    description: qsTr("Show navigation menu")
                    AccessibleCompat.id: "sidebarToggleButton"
                    width: VLCStyle.dp(34, VLCStyle.scale)
                    height: VLCStyle.dp(34, VLCStyle.scale)

                    onClicked: root.toggleNavigationVisibility()

                    Navigation.parentItem: navigationButtons
                    Navigation.leftItem: menuBtn
                }
            }
        }

        // what plays, or the name of the application
        Text {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 2 * Math.max(navigationButtons.width, playqueueButtonsTop.width) - VLCStyle.margin_large)

            text: (Player.title !== "") ? Player.title : qsTr("VLC Media Player")
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: PanelStyle.colors((theme.palette?.isDark ?? true)).text
        }

        Item {
            id: playqueueButtonsTop

            implicitWidth: playqueueButtonsTopRow.implicitWidth

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                //put the buttons below the CSD if we have enough space
                rightMargin: VLCStyle.margin_xsmall
                    + ((root._showCSD && root.topPadding < csdButtons.height)
                        ? Math.max(csdButtons.width - root.rightPadding, 0)
                        : 0)
            }

            Navigation.parentItem: root

            Row {
                id: playqueueButtonsTopRow

                anchors.verticalCenter: parent.verticalCenter

                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Navigation.parentItem: root
                Navigation.leftItem: navigationButtons

                // the play queue opens from the mini player
                PlaylistPane.PlaylistToggleButton {
                    id: playlistBtn

                    visible: false
                    plListView: root.plListView

                    onClicked: root.togglePlayqueueVisibility()
                }

                Widgets.SvgToolButton {
                    iconName: "fullscreen"
                    description: qsTr("Fullscreen")
                    width: VLCStyle.dp(36, VLCStyle.scale)
                    height: VLCStyle.dp(34, VLCStyle.scale)
                    visible: root._showCSD
                    onClicked: MainCtx.toggleInterfaceFullScreen()
                }
            }
        }

        Loader {
            z: -1
            anchors.fill: parent

            active: root._showCSD

            sourceComponent: Widgets.CSDTitlebarTapNDrapHandler {
            }
        }
    }

    Loader {
        id: csdButtons

        //csd button are
        parent:  root
        anchors {
            right: parent.right
            top: parent.top
        }

        height: VLCStyle.dp(40, VLCStyle.scale)
        active: root._showCSD
        source: VLCStyle.palette.hasCSDImage
                  ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
                  : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"
    }
}
