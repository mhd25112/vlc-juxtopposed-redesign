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

import VLC.MainInterface
import VLC.PlayerControls
import VLC.Style
import VLC.Widgets as Widgets

// "Customize Player": the control bar while it is arranged. The same three
// groups of controls, each control in a dashed frame: dragged within the
// bar, between the groups, from the list of controls, or onto the list to
// take it away. With controls in the middle group, the seek bar goes on a
// line of its own.
Item {
    id: root

    required property PlayerControlbarModel barModel

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    EditZone {
        id: leftZone

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        listModel: root.barModel?.left ?? null
    }

    EditZone {
        id: rightZone

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        listModel: root.barModel?.right ?? null
    }

    // the middle: its controls, or the seek bar when it has none
    EditZone {
        id: centerZone

        readonly property real space: rightZone.x - (leftZone.x + leftZone.width) - 2 * VLCStyle.dp(16, VLCStyle.scale)

        anchors.verticalCenter: parent.verticalCenter
        x: listModel && listModel.count > 0 ? Math.round((root.width - width) / 2)
                                           : leftZone.x + leftZone.width + VLCStyle.dp(16, VLCStyle.scale)
        minimumWidth: (listModel && listModel.count > 0) ? VLCStyle.dp(48, VLCStyle.scale) : Math.max(0, space)
        listModel: root.barModel?.center ?? null
        emptyText: qsTr("Seek bar: drop controls here to put them in the middle")
    }

    // a group of controls of the bar
    component EditZone: Item {
        id: zone

        property var listModel: null
        property real minimumWidth: VLCStyle.dp(48, VLCStyle.scale)
        property string emptyText: ""

        // where a drop would go, -1 when nothing is dragged over
        property int _dropIndex: -1

        implicitWidth: Math.max(minimumWidth, row.implicitWidth + 2 * VLCStyle.dp(6, VLCStyle.scale))
        width: implicitWidth
        height: VLCStyle.dp(44, VLCStyle.scale)

        function _indexAt(x) {
            const count = tiles.count
            for (let i = 0; i < count; ++i) {
                const tile = tiles.itemAt(i)
                if (tile && x < row.x + tile.x + tile.width / 2)
                    return i
            }
            return count
        }

        Widgets.DashedFrame {
            anchors.fill: parent
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: dropArea.containsDrag ? theme.accent : root._c.separatorBright
            fillColor: dropArea.containsDrag ? Qt.alpha(theme.accent, 0.08) : "transparent"
        }

        Text {
            anchors.centerIn: parent
            visible: tiles.count === 0 && zone.emptyText !== ""
            width: parent.width - VLCStyle.dp(16, VLCStyle.scale)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: zone.emptyText
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
            color: root._c.label
        }

        Row {
            id: row

            x: VLCStyle.dp(6, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter
            spacing: VLCStyle.dp(6, VLCStyle.scale)

            Repeater {
                id: tiles

                model: zone.listModel

                delegate: Item {
                    id: tile

                    required property int index
                    required property var model

                    width: Math.max(VLCStyle.dp(32, VLCStyle.scale), control.implicitWidth + VLCStyle.dp(8, VLCStyle.scale))
                    height: VLCStyle.dp(36, VLCStyle.scale)
                    opacity: dragSource.dragging ? 0.3 : 1

                    // the control, drawn only
                    Loader {
                        id: control

                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, VLCStyle.dp(160, VLCStyle.scale))
                        enabled: false
                        source: PlayerControlbarControls.control(tile.model.id).source
                        onLoaded: {
                            if (item.paintOnly !== undefined)
                                item.paintOnly = true
                        }
                    }

                    Widgets.DashedFrame {
                        anchors.fill: parent
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: dragSource.containsMouse ? theme.accent : root._c.label
                    }

                    // where it would go
                    Rectangle {
                        x: -VLCStyle.dp(4, VLCStyle.scale)
                        width: VLCStyle.dp(2, VLCStyle.scale)
                        height: parent.height
                        radius: width / 2
                        visible: zone._dropIndex === tile.index
                        color: theme.accent
                    }

                    ControlDragSource {
                        id: dragSource

                        anchors.fill: parent
                        hoverEnabled: true
                        controlId: tile.model.id
                        sourceModel: zone.listModel
                        sourceIndex: tile.index
                    }
                }
            }

            // after the last one
            Rectangle {
                width: VLCStyle.dp(2, VLCStyle.scale)
                height: VLCStyle.dp(36, VLCStyle.scale)
                radius: width / 2
                visible: zone._dropIndex >= 0 && zone._dropIndex === tiles.count
                color: theme.accent
            }
        }

        DropArea {
            id: dropArea

            anchors.fill: parent
            anchors.margins: -VLCStyle.dp(4, VLCStyle.scale)
            keys: ["vlc/control"]

            onPositionChanged: (drag) => { zone._dropIndex = zone._indexAt(drag.x) }
            onExited: zone._dropIndex = -1

            onDropped: (drop) => {
                const index = zone._indexAt(drop.x)
                zone._dropIndex = -1
                const source = drop.source
                if (!source || !zone.listModel)
                    return

                // after the drag: the change can remove what is dragged
                const target = zone.listModel
                const from = source.sourceModel
                const fromIndex = source.sourceIndex
                const id = source.controlId
                Qt.callLater(() => {
                    if (from === target) {
                        const to = index > fromIndex ? index - 1 : index
                        if (to !== fromIndex)
                            target.move(fromIndex, to)
                    } else {
                        target.insert(index, { "id": id })
                        if (from)
                            from.remove(fromIndex)
                    }
                })
                drop.accept(Qt.MoveAction)
            }
        }
    }
}
