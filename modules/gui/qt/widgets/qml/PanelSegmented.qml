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

// A choice between a few options shown side by side, such as
// "None | Horizontal | Vertical"; the current one is in the accent color.
FocusScope {
    id: root

    // list of strings
    property var model: []
    property int currentIndex: 0

    signal activated(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    Rectangle {
        anchors.fill: parent
        radius: VLCStyle.dp(5, VLCStyle.scale)
        color: root._c.field
        border.width: VLCStyle.border
        border.color: root._c.fieldBorder
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: VLCStyle.border
        spacing: VLCStyle.border

        Repeater {
            model: root.model

            delegate: T.AbstractButton {
                id: button

                required property int index
                required property var modelData

                readonly property bool current: index === root.currentIndex

                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitWidth: label.implicitWidth + VLCStyle.dp(28, VLCStyle.scale)

                focusPolicy: Qt.StrongFocus
                focus: current

                // "currentIndex" stays bound to the setting
                onClicked: root.activated(index)

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: button.current ? PanelStyle.accentFill(theme.accent, (theme.palette?.isDark ?? true))
                                          : (button.hovered ? root._c.hover : root._c.control)
                    border.width: button.visualFocus ? VLCStyle.border : 0
                    border.color: theme.accent
                }

                contentItem: Text {
                    id: label
                    text: button.modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                    color: button.current ? theme.accent : root._c.label
                }

                Accessible.role: Accessible.RadioButton
                Accessible.checked: current
                Accessible.name: modelData
            }
        }
    }
}
