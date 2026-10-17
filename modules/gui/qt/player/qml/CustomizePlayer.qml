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
import VLC.PlayerControls
import VLC.Style
import VLC.Widgets as Widgets

// "Customize Player": the controls that are not in the bar, to drag into it
// (ControlBarEditor), and where to drop those to take away. Save keeps the
// arrangement in the current profile, Cancel puts back the saved one.
FocusScope {
    id: root

    required property PlayerControlbarModel barModel

    function save() {
        MainCtx.controlbarProfileModel.save()
        PlayerTweaks.customizing = false
    }

    function cancel() {
        // the saved arrangement
        MainCtx.controlbarProfileModel.reload()
        PlayerTweaks.customizing = false
    }

    focus: true
    Keys.onEscapePressed: cancel()

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    // changes made, for the Save button
    property int _changes: 0

    // the controls in the bar
    property var _used: []

    function _updateUsed() {
        const m = root.barModel
        root._used = m ? [].concat(m.left.ids(), m.center.ids(), m.right.ids()) : []
    }

    Component.onCompleted: _updateUsed()

    Connections {
        target: root.barModel?.left ?? null
        function onCountChanged() { root._updateUsed(); ++root._changes }
        function onRowsMoved() { ++root._changes }
    }
    Connections {
        target: root.barModel?.center ?? null
        function onCountChanged() { root._updateUsed(); ++root._changes }
        function onRowsMoved() { ++root._changes }
    }
    Connections {
        target: root.barModel?.right ?? null
        function onCountChanged() { root._updateUsed(); ++root._changes }
        function onRowsMoved() { ++root._changes }
    }

    readonly property var _available: PlayerControlbarControls.customizeList.filter((entry) =>
        entry.id === ControlListModel.WIDGET_SPACER || entry.id === ControlListModel.WIDGET_SPACER_EXTEND
        || !root._used.includes(entry.id))

    // the player behind, dimmed
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        // clicks do not go to the video
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -VLCStyle.dp(40, VLCStyle.scale)
        width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), parent.width - VLCStyle.dp(64, VLCStyle.scale))
        height: Math.min(VLCStyle.dp(655, VLCStyle.scale), parent.height - VLCStyle.dp(180, VLCStyle.scale))

        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root._c.panel
        border.width: VLCStyle.border
        border.color: dropArea.containsDrag ? theme.accent : root._c.separator

        Widgets.DefaultShadow { }

        // dropped here: taken away from the bar
        DropArea {
            id: dropArea

            anchors.fill: parent
            keys: ["vlc/control"]

            onEntered: (drag) => { drag.accepted = !!drag.source?.sourceModel }

            onDropped: (drop) => {
                const from = drop.source?.sourceModel
                const index = drop.source?.sourceIndex ?? -1
                if (!from || index < 0)
                    return
                Qt.callLater(() => from.remove(index))
                drop.accept(Qt.MoveAction)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)
                Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Customize Player")
                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                    color: root._c.bright
                }

                Widgets.SvgToolButton {
                    iconName: "close"
                    description: qsTr("Cancel")
                    onClicked: root.cancel()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(46, VLCStyle.scale)
                color: root._c.raised

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                    anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: qsTr("Drag items around and out of the box below to re-order them. Drag items into the box to remove them from the player.")
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: root._c.label
                }
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: VLCStyle.dp(24, VLCStyle.scale)

                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: Widgets.ScrollBarExt {
                    visible: grid.contentHeight > grid.height
                }

                readonly property int columns: Math.max(1, Math.floor(width / VLCStyle.dp(110, VLCStyle.scale)))
                cellWidth: Math.floor(width / columns)
                cellHeight: VLCStyle.dp(118, VLCStyle.scale)

                model: root._available

                delegate: Item {
                    id: entry

                    required property var modelData

                    width: grid.cellWidth
                    height: grid.cellHeight
                    opacity: drag.dragging ? 0.4 : 1

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: VLCStyle.dp(8, VLCStyle.scale)
                        spacing: VLCStyle.dp(10, VLCStyle.scale)

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: VLCStyle.dp(32, VLCStyle.scale)
                            height: VLCStyle.dp(32, VLCStyle.scale)

                            Widgets.DashedFrame {
                                anchors.fill: parent
                                radius: VLCStyle.dp(3, VLCStyle.scale)
                                color: drag.containsMouse ? theme.accent : root._c.dim
                            }

                            Widgets.PanelIcon {
                                anchors.centerIn: parent
                                visible: entry.modelData.icon !== ""
                                name: entry.modelData.icon
                                size: VLCStyle.dp(22, VLCStyle.scale)
                                color: drag.containsMouse ? root._c.bright : root._c.text
                            }

                            // the gap: a short line
                            Rectangle {
                                anchors.centerIn: parent
                                visible: entry.modelData.id === ControlListModel.WIDGET_SPACER
                                width: VLCStyle.dp(1, VLCStyle.scale)
                                height: parent.height * 0.6
                                color: root._c.dim
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: grid.cellWidth - VLCStyle.dp(12, VLCStyle.scale)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: entry.modelData.text
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            color: drag.containsMouse ? root._c.bright : root._c.text
                        }
                    }

                    ControlDragSource {
                        id: drag

                        anchors.fill: parent
                        hoverEnabled: true
                        controlId: entry.modelData.id
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(66, VLCStyle.scale)
                Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

                Widgets.PanelButton {
                    text: qsTr("Cancel")
                    implicitWidth: VLCStyle.dp(100, VLCStyle.scale)
                    onClicked: root.cancel()
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
                    elide: Text.ElideRight
                    text: {
                        const current = MainCtx.controlbarProfileModel.currentModel
                        return current ? qsTr("Profile: %1").arg(current.name) : ""
                    }
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                    color: root._c.dim
                }

                Widgets.PanelButton {
                    text: qsTr("Save")
                    accent: true
                    enabled: root._changes > 0
                    implicitWidth: VLCStyle.dp(100, VLCStyle.scale)
                    onClicked: root.save()
                }
            }
        }
    }
}
