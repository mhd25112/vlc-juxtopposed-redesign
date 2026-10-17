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

import VLC.Style

// A small drawing of the player in a theme: title bar, navigation, video
// and control bar with the play key in the accent color. "dark" null draws
// half light, half dark, for the system theme.
Item {
    id: root

    property var dark: true
    property color accent: "#D37918"
    property bool selected: false
    property bool hovered: false

    component Player: Rectangle {
        id: player

        property bool isDark: true
        readonly property var c: PanelStyle.colors(isDark)

        color: c.window
        radius: VLCStyle.dp(6, VLCStyle.scale)
        clip: true

        // navigation
        Rectangle {
            x: parent.width * 0.04
            y: parent.height * 0.16
            width: parent.width * 0.2
            height: parent.height * 0.6
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: player.c.raised

            Column {
                anchors.fill: parent
                anchors.margins: parent.width * 0.15
                spacing: parent.height * 0.08
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        width: parent.width * (index === 0 ? 0.9 : 0.7)
                        height: VLCStyle.dp(3, VLCStyle.scale)
                        radius: height / 2
                        color: index === 0 ? root.accent : player.c.dim
                    }
                }
            }
        }

        // content
        Rectangle {
            x: parent.width * 0.28
            y: parent.height * 0.16
            width: parent.width * 0.68
            height: parent.height * 0.6
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: player.c.panel

            Grid {
                anchors.fill: parent
                anchors.margins: parent.width * 0.06
                columns: 3
                spacing: parent.width * 0.05
                Repeater {
                    model: 6
                    Rectangle {
                        width: (parent.width - 2 * parent.spacing) / 3
                        height: width * 0.6
                        radius: VLCStyle.dp(2, VLCStyle.scale)
                        color: player.c.hover
                    }
                }
            }
        }

        // control bar
        Rectangle {
            x: parent.width * 0.04
            y: parent.height * 0.82
            width: VLCStyle.dp(14, VLCStyle.scale)
            height: parent.height * 0.1
            radius: VLCStyle.dp(2, VLCStyle.scale)
            color: root.accent
        }

        Rectangle {
            x: parent.width * 0.04 + VLCStyle.dp(20, VLCStyle.scale)
            y: parent.height * 0.845
            width: parent.width * 0.6
            height: parent.height * 0.05
            radius: height / 2
            color: player.c.field

            Rectangle {
                width: parent.width * 0.35
                height: parent.height
                radius: parent.radius
                color: PanelStyle.accentFill(root.accent, player.isDark)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -VLCStyle.dp(4, VLCStyle.scale)
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: "transparent"
        border.width: VLCStyle.dp(2, VLCStyle.scale)
        border.color: root.selected ? root.accent
                                    : (root.hovered ? PanelStyle.dark.separatorBright : "transparent")
    }

    Player {
        anchors.fill: parent
        isDark: root.dark === true || root.dark === null
        visible: root.dark !== false
    }

    // System: the light half over the dark one
    Item {
        anchors.fill: parent
        visible: root.dark !== true
        clip: true

        Item {
            width: root.dark === null ? parent.width / 2 : parent.width
            height: parent.height
            clip: true

            Player {
                width: root.width
                height: root.height
                isDark: false
            }
        }
    }
}
