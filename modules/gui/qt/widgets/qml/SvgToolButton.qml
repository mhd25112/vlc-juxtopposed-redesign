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

// IconToolButton drawing one of the line icons of the redesign
// (pixmaps/redesign) instead of a glyph of the icon font.
IconToolButton {
    id: root

    property string iconName
    // icon size relative to the font size of the button
    property real iconScale: 1.0

    // the color of the icon for the state of the button: muted (FG/A2), lit
    // when hovered or pressed, the accent when checked
    readonly property var _c: PanelStyle.colors(root.colorContext.palette?.isDark ?? true)
    readonly property color stateColor: {
        if (root.checked)
            return root.colorContext.accent
        if (!root.enabled && !root.paintOnly)
            return Qt.alpha(root._c.label, 0.4)
        if (root.down || root.hovered || root.visualFocus)
            return root._c.bright
        return root._c.label
    }

    color: stateColor
    text: iconName

    padding: VLCStyle.dp(4, VLCStyle.scale)

    background: Rectangle {
        implicitWidth: root.font.pixelSize
        implicitHeight: root.font.pixelSize

        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: root.down ? Qt.alpha(root._c.bright, 0.13)
                         : (root.hovered && root.enabled ? Qt.alpha(root._c.bright, 0.07)
                                                         : Qt.alpha(root._c.bright, 0))
        border.width: root.visualFocus ? VLCStyle.focus_border : 0
        border.color: root.colorContext.visualFocus

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: Item {
        implicitWidth: root.font.pixelSize
        implicitHeight: root.font.pixelSize

        PanelIcon {
            anchors.centerIn: parent
            size: Math.round(root.font.pixelSize * root.iconScale)
            name: root.iconName
            color: root.color
            secondaryColor: root.colorContext.bg.primary

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
}
