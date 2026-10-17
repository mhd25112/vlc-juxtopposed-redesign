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

// Slider of the redesigned panels: a thick black track, filled with a dark
// accent from "origin" to a thin accent handle. Optional tick marks and
// labels under the track ("-10 s  0 s  +10 s", "0.25 ... 2").
T.Slider {
    id: control

    // where the fill starts, "from" by default; the middle for a delay
    property real origin: from
    // current value of the setting, the handle follows it unless dragged
    property real boundValue: from

    Binding on value {
        when: !control.pressed
        value: control.boundValue
    }

    // values where to draw a tick mark
    property var ticks: []
    // [{ value, text }] shown under the track
    property var labels: []

    readonly property real _trackHeight: VLCStyle.dp(12, VLCStyle.scale)
    readonly property real _labelsHeight: labels.length > 0 ? VLCStyle.dp(22, VLCStyle.scale) : 0

    implicitWidth: VLCStyle.dp(240, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(24, VLCStyle.scale) + _labelsHeight

    topPadding: 0
    bottomPadding: _labelsHeight
    leftPadding: 0
    rightPadding: 0

    focusPolicy: Qt.StrongFocus
    wheelEnabled: true

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    function _pos(v) {
        return (v - from) / ((to - from) || 1)
    }

    background: Item {
        x: control.leftPadding
        width: control.availableWidth
        height: control.height

        Rectangle {
            id: track

            y: (control.availableHeight - height) / 2
            width: parent.width
            height: control._trackHeight
            radius: height / 2

            color: control._c.field
            border.width: VLCStyle.border
            border.color: control._c.fieldBorder

            Rectangle {
                readonly property real a: control._pos(control.origin) * track.width
                readonly property real b: control.visualPosition * track.width

                x: Math.min(a, b)
                width: Math.abs(b - a)
                height: parent.height
                radius: parent.radius

                color: PanelStyle.accentFill(theme.accent, (theme.palette?.isDark ?? true))
            }

            Repeater {
                model: control.ticks

                delegate: Rectangle {
                    required property var modelData

                    x: control._pos(modelData) * track.width - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.border
                    height: track.height / 2
                    color: control._c.dim
                    visible: modelData > control.from && modelData < control.to
                }
            }
        }

        Repeater {
            model: control.labels

            delegate: Text {
                required property var modelData

                readonly property real _center: control._pos(modelData.value) * track.width

                x: Math.max(0, Math.min(track.width - width, _center - width / 2))
                y: track.y + track.height + VLCStyle.dp(6, VLCStyle.scale)

                text: modelData.text
                font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
                color: control._c.label
            }
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: (control.availableHeight - height) / 2

        width: VLCStyle.dp(6, VLCStyle.scale)
        height: VLCStyle.dp(22, VLCStyle.scale)
        radius: width / 2

        color: control.pressed || control.visualFocus ? Qt.lighter(theme.accent, 1.15) : theme.accent
    }
}
