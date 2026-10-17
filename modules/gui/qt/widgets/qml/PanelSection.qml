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

// A titled group of settings ("Defaults", "Synchronization"...), separated
// from the next one by a line.
ColumnLayout {
    id: root

    property string title
    property bool separator: true

    default property alias content: body.data

    spacing: 0

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    Text {
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.dp(18, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(8, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

        visible: root.title !== ""
        text: root.title
        font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
        font.weight: Font.DemiBold
        color: root._c.heading
        elide: Text.ElideRight
    }

    ColumnLayout {
        id: body

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
        Layout.topMargin: root.title === "" ? VLCStyle.dp(12, VLCStyle.scale) : 0
        Layout.bottomMargin: VLCStyle.dp(18, VLCStyle.scale)

        spacing: VLCStyle.dp(10, VLCStyle.scale)
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.border
        visible: root.separator
        color: root._c.separator
    }
}
