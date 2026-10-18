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

import VLC.MediaLibrary
import VLC.MainInterface
import VLC.Player
import VLC.Util
import VLC.Widgets as Widgets
import VLC.Style

// The list view of the redesign: the videos in columns, each a line with a
// small picture and the name; what was watched is dimmed, with its progress
// under the picture.
Widgets.ExpandGridView {
    id: root

    property MLDragItem dragItem
    property MLContextMenu contextMenu

    signal itemDoubleClicked(var model)

    readonly property int _columnWidth: VLCStyle.dp(280, VLCStyle.scale)

    nbItemPerRow: Math.max(1, Math.floor((_availableContentWidth + horizontalSpacing) / (_columnWidth + horizontalSpacing)))
    cellWidth: Math.floor((_availableContentWidth - (nbItemPerRow - 1) * horizontalSpacing) / nbItemPerRow)
    cellHeight: VLCStyle.dp(36, VLCStyle.scale)

    horizontalSpacing: VLCStyle.dp(16, VLCStyle.scale)
    verticalSpacing: VLCStyle.dp(6, VLCStyle.scale)
    topMargin: VLCStyle.dp(16, VLCStyle.scale)

    activeFocusOnTab: true

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    onActiveFocusChanged: {
        if (!activeFocus || model.count === 0 || selectionModel.hasSelection)
            return
        resetFocus()
    }

    delegate: T.AbstractButton {
        id: line

        // set by the view
        required property Item view
        required property var model
        required property int index
        property bool selected: false

        readonly property bool watched: model?.isNew === false
        // what plays: in the accent, as in the design
        readonly property bool playing: !!model?.mrl && Player.isStarted
                                        && decodeURIComponent(String(model.mrl)) === decodeURIComponent(String(Player.url))
        // the name of the file, as in the design ("The_Wand_S01E05.mp4")
        readonly property string fileName: {
            const mrl = decodeURIComponent(String(model?.mrl ?? ""))
            return mrl.substring(mrl.lastIndexOf("/") + 1)
        }

        width: root.cellWidth
        height: root.cellHeight

        hoverEnabled: true
        focusPolicy: Qt.NoFocus

        Drag.active: dragHandler.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction

        DragHandler {
            id: dragHandler
            target: null
            onActiveChanged: {
                if (active && root.dragItem) {
                    if (!line.selected)
                        root.leftClickOnItem(Qt.NoModifier, line.index, true)
                    root.dragItem.Drag.active = true
                }
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: (eventPoint, button) => {
                root.leftClickOnItem(point.modifiers, line.index, true)
                root.forceActiveFocus(Qt.MouseFocusReason)
            }
            onDoubleTapped: root.itemDoubleClicked(line.model)
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: (eventPoint, button) => {
                root.rightClickOnItem(line.index)
                root.contextMenu?.popup(root.selectionModel.selectedIndexes,
                                        line.mapToGlobal(eventPoint.position.x, eventPoint.position.y))
            }
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: line.selected ? PanelStyle.accentTint(theme.accent, theme.palette?.isDark ?? true)
                                 : (line.hovered ? root._c.hover : "transparent")
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Item {
                Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                Image {
                    anchors.fill: parent
                    source: line.model?.thumbnail || VLCStyle.noArtVideoCover
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(VLCStyle.dp(64, VLCStyle.scale), VLCStyle.dp(64, VLCStyle.scale))
                    asynchronous: true
                    smooth: true
                    opacity: line.watched && !line.hovered ? 0.6 : 1
                }

                // play on hover, and on what plays
                Rectangle {
                    anchors.fill: parent
                    radius: VLCStyle.dp(3, VLCStyle.scale)
                    visible: line.hovered || line.playing
                    color: Qt.rgba(0, 0, 0, 0.55)

                    Widgets.PanelIcon {
                        anchors.centerIn: parent
                        name: "play_filled"
                        size: VLCStyle.dp(16, VLCStyle.scale)
                        color: theme.accent
                    }

                    TapHandler {
                        onTapped: {
                            MediaLib.addAndPlay(line.model.id)
                            MainCtx.playerView = true
                        }
                    }
                }

                // what was watched
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -VLCStyle.dp(3, VLCStyle.scale)
                    height: VLCStyle.dp(2, VLCStyle.scale)
                    width: parent.width * Helpers.clamp(line.model?.progress ?? 0, 0, 1)
                    visible: (line.model?.progress ?? 0) > 0
                    radius: height / 2
                    color: theme.accent
                }
            }

            Text {
                Layout.fillWidth: true

                text: line.fileName || line.model?.title || qsTr("Unknown title")
                elide: Text.ElideMiddle
                font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                color: (line.hovered || line.playing) ? theme.accent
                                                      : (line.watched ? root._c.dim : root._c.text)
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                visible: line.hovered
                text: line.model?.duration?.formatHMS() ?? ""
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                color: root._c.label
            }
        }

        Accessible.name: model?.title ?? ""
    }
}
