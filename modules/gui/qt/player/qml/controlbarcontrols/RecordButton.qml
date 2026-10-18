/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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


import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Util

Widgets.SvgToolButton {
    id: control

    enabled: !paintOnly && Player.isStarted

    // red while recording, blinking
    color: Player.recording ? "#ff3b30" : stateColor
    iconName: "record"
    description: Player.recording ? qsTr("Stop recording") : qsTr("Record")

    AccessibleCompat.id: "recordButton"

    onClicked: Player.toggleRecord()

    SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: Player.recording
        NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) control.opacity = 1
    }
}
