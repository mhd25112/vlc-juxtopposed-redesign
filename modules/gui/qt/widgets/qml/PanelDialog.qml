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

// Dialog of the redesign, over the window: a rounded panel with its title
// and a close button at the top, the rest of the window dimmed behind it.
T.Popup {
    id: root

    property string title
    property bool showHeader: true
    property real preferredWidth: VLCStyle.dp(1048, VLCStyle.scale)
    property real preferredHeight: VLCStyle.dp(800, VLCStyle.scale)
    // items in the header, after the title
    property alias headerItems: headerExtra.data

    default property alias content: body.data

    parent: T.Overlay.overlay

    anchors.centerIn: parent
    width: Math.min(preferredWidth, parent.width - VLCStyle.dp(32, VLCStyle.scale))
    height: Math.min(preferredHeight, parent.height - VLCStyle.dp(32, VLCStyle.scale))

    modal: true
    focus: true
    padding: 0
    closePolicy: T.Popup.CloseOnEscape

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.55)
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: VLCStyle.duration_short }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: VLCStyle.duration_veryShort }
    }

    background: Rectangle {
        color: root._c.panel
        radius: VLCStyle.dp(10, VLCStyle.scale)
        border.width: VLCStyle.border
        border.color: root._c.separator

        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.margins: -VLCStyle.dp(1, VLCStyle.scale)
            anchors.topMargin: VLCStyle.dp(8, VLCStyle.scale)
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.45)
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // readable by the content, which is not parented to the popup
        readonly property ColorContext colorContext: ColorContext {
            colorSet: ColorContext.View
            palette: VLCStyle.palette
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)
            visible: root.showHeader

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                spacing: VLCStyle.dp(8, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                    font.weight: Font.DemiBold
                    color: root._c.bright
                    elide: Text.ElideRight
                }

                Item {
                    id: headerExtra
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                }

                T.AbstractButton {
                    implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
                    implicitHeight: implicitWidth
                    onClicked: root.close()

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: parent.hovered ? root._c.hover : "transparent"
                    }
                    contentItem: PanelIcon {
                        name: "close"
                        size: VLCStyle.dp(18, VLCStyle.scale)
                        color: root._c.label
                    }

                    Accessible.name: qsTr("Close")
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: VLCStyle.border
                color: root._c.separator
            }
        }

        Item {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
