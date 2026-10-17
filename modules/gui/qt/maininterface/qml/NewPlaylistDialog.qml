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

// New Playlist: a name, then the files, dropped in the box or picked.
Widgets.PanelDialog {
    id: root

    title: qsTr("New Playlist")
    preferredWidth: VLCStyle.dp(713, VLCStyle.scale)
    preferredHeight: VLCStyle.dp(589, VLCStyle.scale)

    property var _files: []

    onOpened: {
        _files = []
        nameField.text = ""
        nameField.forceActiveFocus()
    }

    function _name(url) {
        const path = decodeURIComponent(String(url))
        return path.substring(path.lastIndexOf("/") + 1)
    }

    function _add(urls) {
        const known = root._files.map(String)
        root._files = root._files.concat(urls.filter((u) => !known.includes(String(u))))
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
                text: qsTr("Playlist Details")
                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                font.weight: Font.DemiBold
                color: root._c.bright
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("The playlist will be saved and displayed with this title.")
                wrapMode: Text.WordWrap
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root._c.label
            }

            Widgets.PanelTextField {
                id: nameField

                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.dp(14, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(37, VLCStyle.scale)
                placeholderText: qsTr("e.g., Favorite Videos")
            }

            Text {
                Layout.topMargin: VLCStyle.dp(24, VLCStyle.scale)
                text: qsTr("Select Files")
                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                font.weight: Font.DemiBold
                color: root._c.bright
            }

            Text {
                text: qsTr("These files will be added to the playlist.")
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: root._c.label
            }

            // the drop zone, a click picks files
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: VLCStyle.dp(120, VLCStyle.scale)
                Layout.topMargin: VLCStyle.dp(14, VLCStyle.scale)

                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: dropArea.containsDrag ? PanelStyle.accentFill(theme.accent, theme.palette?.isDark ?? true) : root._c.field
                border.width: VLCStyle.border
                border.color: dropArea.containsDrag ? theme.accent : root._c.fieldBorder

                DropArea {
                    id: dropArea
                    anchors.fill: parent
                    onDropped: (drop) => {
                        if (drop.hasUrls) {
                            root._add(drop.urls)
                            drop.accept()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root._files.length === 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._add(PlayerTweaks.chooseFiles(qsTr("Select Files"), ""))
                }

                Column {
                    anchors.centerIn: parent
                    visible: root._files.length === 0
                    spacing: VLCStyle.dp(16, VLCStyle.scale)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Drag files into the box or click here to select files.")
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        color: root._c.label
                    }

                    Widgets.PanelIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "download"
                        size: VLCStyle.dp(24, VLCStyle.scale)
                        color: root._c.label
                    }
                }

                ListView {
                    id: fileList

                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                    visible: root._files.length > 0
                    clip: true
                    model: root._files
                    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                    delegate: RowLayout {
                        required property int index
                        required property var modelData

                        width: fileList.width
                        height: VLCStyle.dp(34, VLCStyle.scale)
                        spacing: VLCStyle.dp(10, VLCStyle.scale)

                        Widgets.PanelIcon {
                            Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                            name: "file"
                            size: VLCStyle.dp(18, VLCStyle.scale)
                            color: root._c.label
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root._name(modelData)
                            elide: Text.ElideMiddle
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            color: root._c.text
                        }

                        Widgets.SvgToolButton {
                            iconName: "close"
                            description: qsTr("Remove")
                            width: VLCStyle.dp(28, VLCStyle.scale)
                            height: width
                            onClicked: root._files = root._files.filter((f, i) => i !== index)
                        }
                    }

                    footer: Widgets.PanelButton {
                        flat: true
                        iconName: "add"
                        text: qsTr("Add More Files")
                        onClicked: root._add(PlayerTweaks.chooseFiles(qsTr("Select Files"), ""))
                    }
                }
            }
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

            Item { Layout.fillWidth: true }

            Widgets.PanelButton {
                text: qsTr("Save")
                accent: true
                implicitWidth: VLCStyle.dp(96, VLCStyle.scale)
                enabled: nameField.text.trim() !== ""
                onClicked: {
                    PlayerTweaks.createPlaylist(nameField.text, root._files, false)
                    root.close()
                }
            }
        }
    }
}
