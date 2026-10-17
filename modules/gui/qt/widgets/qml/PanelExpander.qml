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

import VLC.Style

// "Expand Settings" card: the less used settings of a filter, folded by
// default under the switch that enables it.
ColumnLayout {
    id: root

    property bool expanded: false
    property string expandText: qsTr("Expand Settings")
    property string collapseText: qsTr("Collapse Settings")

    default property alias content: body.data

    Layout.fillWidth: true
    spacing: 0

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    T.AbstractButton {
        id: header

        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus
        onClicked: root.expanded = !root.expanded

        background: Rectangle {
            color: header.hovered ? root._c.hover : root._c.card
            radius: VLCStyle.dp(6, VLCStyle.scale)
            border.width: header.visualFocus ? VLCStyle.border : 0
            border.color: theme.accent

            // square the bottom corners while the card is open
            Rectangle {
                visible: root.expanded
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }
        }

        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                text: root.expanded ? root.collapseText : root.expandText
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: root._c.label
            }

            PanelIcon {
                Layout.rightMargin: VLCStyle.dp(10, VLCStyle.scale)
                name: root.expanded ? "chevron_down" : "chevron_right"
                size: VLCStyle.dp(16, VLCStyle.scale)
                color: root._c.label
            }
        }

        Accessible.role: Accessible.Button
        Accessible.name: root.expanded ? root.collapseText : root.expandText
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + VLCStyle.dp(16, VLCStyle.scale)

        visible: root.expanded
        color: root._c.card
        radius: VLCStyle.dp(6, VLCStyle.scale)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.radius
            color: parent.color
        }

        ColumnLayout {
            id: body

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
            anchors.topMargin: VLCStyle.dp(4, VLCStyle.scale)

            spacing: VLCStyle.dp(8, VLCStyle.scale)
        }
    }
}
