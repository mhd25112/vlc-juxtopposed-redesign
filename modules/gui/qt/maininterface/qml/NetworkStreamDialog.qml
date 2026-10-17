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

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets

// Open Network Stream: one or more links, and a name to keep them as a
// playlist of the library (a list of TV channels, a podcast...).
Widgets.PanelDialog {
    id: root

    title: qsTr("Open Network Stream")
    preferredWidth: VLCStyle.dp(1048, VLCStyle.scale)
    preferredHeight: VLCStyle.dp(631, VLCStyle.scale)

    readonly property var _urls: urlsField.text.split(/\s+/).map((u) => u.trim()).filter((u) => /^[a-z][a-z0-9+.-]*:\/\//i.test(u))

    onOpened: {
        urlsField.text = ""
        nameField.text = ""
        urlsField.forceActiveFocus()
    }

    ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: VLCStyle.dp(20, VLCStyle.scale)
            spacing: VLCStyle.dp(6, VLCStyle.scale)

            Text {
                text: qsTr("Network URL")
                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                font.weight: Font.DemiBold
                color: root._c.bright
            }

            Text {
                text: qsTr("You can enter multiple links to load.")
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root._c.label
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(194, VLCStyle.scale)
                Layout.topMargin: VLCStyle.dp(14, VLCStyle.scale)
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: root._c.field
                border.width: VLCStyle.border
                border.color: urlsField.activeFocus ? theme.accent : root._c.fieldBorder

                Flickable {
                    id: urlsFlickable

                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(12, VLCStyle.scale)
                    contentHeight: urlsField.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    T.TextArea {
                        id: urlsField

                        width: urlsFlickable.width
                        wrapMode: TextEdit.WrapAnywhere
                        selectByMouse: true
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        color: root._c.text
                        selectionColor: theme.accent
                        placeholderText: qsTr("e.g., https://www.example.com/stream.avi")
                        placeholderTextColor: root._c.dim

                        Text {
                            width: parent.width
                            text: urlsField.placeholderText
                            font: urlsField.font
                            color: urlsField.placeholderTextColor
                            visible: urlsField.length === 0 && urlsField.preeditText === ""
                        }
                    }
                }
            }

            Text {
                Layout.topMargin: VLCStyle.dp(28, VLCStyle.scale)
                text: qsTr("Playlist Name (optional)")
                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                font.weight: Font.DemiBold
                color: root._c.bright
            }

            Text {
                text: qsTr("The playlist will be saved and displayed with this title.")
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root._c.label
            }

            Widgets.PanelTextField {
                id: nameField

                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.dp(14, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(37, VLCStyle.scale)
                placeholderText: qsTr("e.g., Favorite TV Channels")
            }

            Item { Layout.fillHeight: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border
            color: root._c.separator
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(70, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)

            Widgets.PanelButton {
                text: qsTr("Cancel")
                flat: true
                onClicked: root.close()
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                visible: urlsField.text.trim() !== ""
                text: root._urls.length === 1 ? qsTr("1 link") : qsTr("%1 links").arg(root._urls.length)
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: root._c.label
            }

            Item { Layout.fillWidth: urlsField.text.trim() === "" }

            Widgets.PanelButton {
                text: qsTr("Save")
                accent: true
                implicitWidth: VLCStyle.dp(96, VLCStyle.scale)
                enabled: root._urls.length > 0
                onClicked: {
                    PlayerTweaks.createPlaylist(nameField.text, root._urls, true)
                    root.close()
                }
            }
        }
    }
}
