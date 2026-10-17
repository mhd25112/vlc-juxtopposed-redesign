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
import QtQuick.Layouts

import VLC.Style

// One setting: its name on the left and its control on the right. "info"
// adds an (i) next to the name that explains the setting on hover.
RowLayout {
    id: root

    property string label
    property string info
    property bool dimmed: false

    default property alias control: slot.data

    Layout.fillWidth: true
    Layout.minimumHeight: VLCStyle.dp(32, VLCStyle.scale)

    spacing: VLCStyle.dp(12, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    RowLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.alignment: Qt.AlignVCenter
        spacing: VLCStyle.dp(6, VLCStyle.scale)

        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth

            text: root.label
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root.dimmed ? root._c.dim : root._c.label
            elide: Text.ElideRight
        }

        PanelIcon {
            id: infoIcon

            visible: root.info !== ""
            name: "info"
            size: VLCStyle.dp(14, VLCStyle.scale)
            color: infoHover.hovered ? theme.accent : root._c.dim

            HoverHandler { id: infoHover }

            ToolTipExt {
                visible: infoHover.hovered
                text: root.info
                delay: 200
            }
        }

        Item { Layout.fillWidth: true }
    }

    Item {
        id: slot

        readonly property Item control: children.length > 0 ? children[0] : null

        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        implicitWidth: control ? control.implicitWidth : 0
        implicitHeight: control ? control.implicitHeight : 0
    }
}
