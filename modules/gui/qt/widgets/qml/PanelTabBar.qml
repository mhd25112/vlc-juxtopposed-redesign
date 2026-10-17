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

// Tabs of the redesigned panels: icon and name, the current one underlined
// in the accent color.
FocusScope {
    id: root

    // [{ text, icon }]
    property var model: []
    property int currentIndex: 0

    signal activated(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: VLCStyle.dp(44, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    RowLayout {
        id: row

        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.model

            delegate: T.AbstractButton {
                id: tab

                required property int index
                required property var modelData

                readonly property bool current: index === root.currentIndex

                Layout.fillWidth: true
                Layout.fillHeight: true

                implicitWidth: content.implicitWidth + VLCStyle.dp(16, VLCStyle.scale)

                focusPolicy: Qt.StrongFocus
                focus: current

                onClicked: {
                    root.currentIndex = index
                    root.activated(index)
                }

                background: Item {
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: content.implicitWidth + VLCStyle.dp(16, VLCStyle.scale)
                        height: VLCStyle.dp(2, VLCStyle.scale)
                        radius: height / 2
                        visible: tab.current || tab.visualFocus
                        color: tab.current ? theme.accent : root._c.dim
                    }
                }

                contentItem: Item {
                    RowLayout {
                        id: content

                        anchors.centerIn: parent
                        spacing: VLCStyle.dp(6, VLCStyle.scale)

                        PanelIcon {
                            visible: !!tab.modelData.icon
                            name: tab.modelData.icon ?? ""
                            size: VLCStyle.dp(16, VLCStyle.scale)
                            color: tab.current ? theme.accent : (tab.hovered ? root._c.text : root._c.label)
                        }

                        Text {
                            text: tab.modelData.text
                            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                            color: tab.current || tab.hovered ? root._c.text : root._c.label
                        }
                    }
                }

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
            }
        }
    }
}
