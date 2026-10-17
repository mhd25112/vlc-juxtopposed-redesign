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

import VLC.Style

// Search field of the library header: always visible, with its icon and a
// button to clear it. "pattern" follows the text after a short delay.
T.TextField {
    id: control

    property string pattern: ""

    implicitWidth: VLCStyle.dp(300, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

    leftPadding: VLCStyle.dp(40, VLCStyle.scale)
    rightPadding: VLCStyle.dp(34, VLCStyle.scale)
    verticalAlignment: TextInput.AlignVCenter

    selectByMouse: true
    placeholderText: qsTr("Search")
    font.pixelSize: VLCStyle.dp(13.5, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    color: _c.text
    placeholderTextColor: _c.dim
    selectionColor: theme.accent
    selectedTextColor: "white"

    onTextChanged: patternTimer.restart()
    Keys.onEscapePressed: (event) => {
        if (text !== "") {
            text = ""
            event.accepted = true
        } else {
            event.accepted = false
        }
    }

    Timer {
        id: patternTimer
        interval: 250
        onTriggered: control.pattern = control.text
    }

    background: Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: control._c.card
        border.width: control.activeFocus ? VLCStyle.border : 0
        border.color: theme.accent

        PanelIcon {
            anchors.verticalCenter: parent.verticalCenter
            x: VLCStyle.dp(12, VLCStyle.scale)
            name: "search"
            size: VLCStyle.dp(18, VLCStyle.scale)
            color: control.activeFocus ? control._c.text : control._c.label
        }

        // the template does not draw it
        Text {
            x: control.leftPadding
            width: control.width - control.leftPadding - control.rightPadding
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: control.placeholderText
            font: control.font
            color: control.placeholderTextColor
            elide: Text.ElideRight
            visible: control.length === 0 && control.preeditText === ""
        }

        T.AbstractButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
            width: VLCStyle.dp(20, VLCStyle.scale)
            height: width
            visible: control.text !== ""
            onClicked: control.text = ""

            contentItem: PanelIcon {
                name: "close"
                size: VLCStyle.dp(16, VLCStyle.scale)
                color: control._c.label
            }

            Accessible.name: qsTr("Clear")
        }
    }
}
