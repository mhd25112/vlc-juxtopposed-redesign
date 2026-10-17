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

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets

// "Customize Player": what drags a control, from the bar (sourceModel and
// sourceIndex set) or from the list of controls (sourceModel null). While
// dragged, a picture of the control follows the pointer above everything;
// the drop areas read controlId, sourceModel and sourceIndex from
// drag.source.
MouseArea {
    id: root

    required property int controlId
    property var sourceModel: null
    property int sourceIndex: -1

    readonly property bool dragging: _ghost !== null

    property Item _ghost: null
    property point _pressPos

    cursorShape: pressed ? Qt.DragMoveCursor : Qt.OpenHandCursor
    preventStealing: true

    onPressed: (mouse) => { _pressPos = Qt.point(mouse.x, mouse.y) }

    // the picture follows the pointer once it moved a little
    onPositionChanged: (mouse) => {
        if (!pressed)
            return
        if (!_ghost) {
            if (Math.abs(mouse.x - _pressPos.x) + Math.abs(mouse.y - _pressPos.y) < VLCStyle.dp(6, VLCStyle.scale))
                return
            const info = PlayerControlbarControls.customizeInfo(root.controlId)
            const size = VLCStyle.dp(48, VLCStyle.scale)
            _ghost = ghostComponent.createObject(root.Window.contentItem, {
                width: size, height: size, iconName: info.icon, label: info.text
            })
        }
        const pos = root.mapToItem(_ghost.parent, mouse.x, mouse.y)
        _ghost.x = pos.x - _ghost.width / 2
        _ghost.y = pos.y - _ghost.height / 2
        _ghost.Drag.active = true
    }

    onReleased: {
        if (_ghost) {
            _ghost.Drag.drop()
            _ghost.destroy()
            _ghost = null
        }
    }

    onCanceled: {
        if (_ghost) {
            _ghost.Drag.cancel()
            _ghost.destroy()
            _ghost = null
        }
    }

    Component {
        id: ghostComponent

        Rectangle {
            id: ghost

            property string iconName
            property string label

            z: 10000
            radius: VLCStyle.dp(8, VLCStyle.scale)
            color: PanelStyle.colors(true).raised
            border.width: VLCStyle.dp(1.5, VLCStyle.scale)
            border.color: theme.accent
            opacity: 0.92

            Drag.source: root
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.keys: ["vlc/control"]

            Widgets.PanelIcon {
                anchors.centerIn: parent
                visible: ghost.iconName !== ""
                name: ghost.iconName
                size: VLCStyle.dp(24, VLCStyle.scale)
                color: "#eaeaea"
            }

            Text {
                anchors.centerIn: parent
                visible: ghost.iconName === ""
                width: parent.width - VLCStyle.dp(4, VLCStyle.scale)
                horizontalAlignment: Text.AlignHCenter
                text: ghost.label
                elide: Text.ElideRight
                font.pixelSize: VLCStyle.dp(10, VLCStyle.scale)
                color: "#eaeaea"
            }
        }
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }
}
