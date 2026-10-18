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
import VLC.Player
import VLC.Widgets as Widgets

// "Show Subtitle Timeline on Seekbar": the seek bar becomes a window of a
// minute of the subtitles, each line a block. Drag the blocks to move the
// subtitles earlier or later (the subtitle delay), click to seek, ‹ and ›
// move the window, − and + zoom it. Right click resets the delay.
Item {
    id: root

    // [start, end, start, end...] in seconds, without the delay
    property var cues: []

    property color accent
    property var panel

    readonly property real length: Player.length.valid() ? Player.length.toSeconds() : 0
    readonly property real time: Player.time.valid() ? Player.time.toSeconds() : 0
    // where the lines show: their time plus the subtitle delay
    readonly property real delay: Player.subtitleDelayMS / 1000

    // the window shown: a minute, as in the design, from 10 s to 10 min
    readonly property var spans: [10, 20, 30, 60, 120, 300, 600]
    property int spanIndex: 3
    readonly property real span: Math.max(1, Math.min(spans[spanIndex], length > 0 ? length : spans[spanIndex]))
    property real start: 0
    readonly property real end: start + span

    // the window follows what plays, until it is moved by hand (a click to
    // seek brings it back)
    property bool follow: true

    function _clampStart(s) {
        return Math.max(0, Math.min(s, Math.max(0, length - span)))
    }

    function _place() {
        if (follow && (time < start || time >= end))
            start = _clampStart(Math.floor(time / span) * span)
    }

    function zoom(step) {
        const center = follow ? time : start + span / 2
        spanIndex = Math.max(0, Math.min(spans.length - 1, spanIndex + step))
        start = follow ? _clampStart(Math.floor(time / span) * span)
                       : _clampStart(center - span / 2)
    }

    function pan(direction) {
        follow = false
        start = _clampStart(start + direction * span / 2)
    }

    onTimeChanged: _place()
    onLengthChanged: { start = _clampStart(start); _place() }

    Connections {
        target: Player
        function onUrlChanged() {
            root.follow = true
            root.start = 0
        }
    }

    function _formatDelay(ms) {
        const s = ms / 1000
        return (s > 0 ? "+" : "") + s.toFixed(2) + " s"
    }

    component EdgeButton: T.AbstractButton {
        id: button

        property string iconName

        width: Math.round(root.height * 0.7)
        height: root.height - 2 * VLCStyle.border
        anchors.verticalCenter: parent.verticalCenter

        hoverEnabled: true
        focusPolicy: Qt.NoFocus

        background: Rectangle {
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: button.pressed ? Qt.darker(root.accent, 1.25)
                                  : (button.hovered ? Qt.lighter(root.accent, 1.12) : root.accent)
        }

        contentItem: Item {
            Widgets.PanelIcon {
                anchors.centerIn: parent
                name: button.iconName
                size: Math.round(Math.min(button.width, button.height) * 0.85)
                color: "#0e0e0e"
                opacity: button.enabled ? 1 : 0.45
            }
        }

        T.ToolTip.visible: hovered
        T.ToolTip.delay: VLCStyle.delayToolTipAppear
    }

    Rectangle {
        anchors.fill: parent
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: root.panel.field
        border.width: VLCStyle.border
        border.color: root.panel.fieldBorder
    }

    Row {
        id: leftButtons

        anchors.left: parent.left
        anchors.leftMargin: VLCStyle.border
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: VLCStyle.border

        EdgeButton {
            iconName: "chevron_left"
            enabled: root.start > 0
            T.ToolTip.text: qsTr("Earlier")
            onClicked: root.pan(-1)
        }
        EdgeButton {
            iconName: "minus"
            enabled: root.spanIndex < root.spans.length - 1 && root.span < root.length
            T.ToolTip.text: qsTr("Zoom out")
            onClicked: root.zoom(1)
        }
    }

    Row {
        id: rightButtons

        anchors.right: parent.right
        anchors.rightMargin: VLCStyle.border
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: VLCStyle.border

        EdgeButton {
            iconName: "plus"
            enabled: root.spanIndex > 0
            T.ToolTip.text: qsTr("Zoom in")
            onClicked: root.zoom(-1)
        }
        EdgeButton {
            iconName: "chevron_right"
            enabled: root.end < root.length
            T.ToolTip.text: qsTr("Later")
            onClicked: root.pan(1)
        }
    }

    // the lines in the window, the part already played in the accent color
    Canvas {
        id: blocks

        anchors.left: leftButtons.right
        anchors.right: rightButtons.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: VLCStyle.border
        anchors.leftMargin: VLCStyle.dp(2, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(2, VLCStyle.scale)

        readonly property color playedBack: Qt.tint(root.panel.field, Qt.alpha(root.accent, 0.22))
        readonly property color playedBlock: Qt.tint(root.panel.separatorBright, Qt.alpha(root.accent, 0.35))
        readonly property color block: root.panel.separatorBright
        readonly property color draggedBlock: Qt.tint(root.panel.separatorBright, Qt.alpha(root.accent, 0.6))

        function xOf(t) {
            return (t - root.start) / root.span * width
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (root.span <= 0 || width <= 0)
                return

            const playX = Math.max(0, Math.min(width, xOf(root.time)))
            ctx.fillStyle = playedBack
            ctx.fillRect(0, 0, playX, height)

            const pad = Math.round(height * 0.12)
            for (let i = 0; i + 1 < root.cues.length; i += 2) {
                const s = root.cues[i] + root.delay
                const e = root.cues[i + 1] + root.delay
                if (e < root.start || s > root.end)
                    continue
                const x0 = Math.max(0, xOf(s))
                const x1 = Math.min(width, Math.max(x0 + 1, xOf(e)))
                if (dragArea.dragging) {
                    ctx.fillStyle = draggedBlock
                    ctx.fillRect(x0, pad, x1 - x0, height - 2 * pad)
                    continue
                }
                // played part, then the rest
                const split = Math.max(x0, Math.min(x1, playX))
                if (split > x0) {
                    ctx.fillStyle = playedBlock
                    ctx.fillRect(x0, pad, split - x0, height - 2 * pad)
                }
                if (x1 > split) {
                    ctx.fillStyle = block
                    ctx.fillRect(split, pad, x1 - split, height - 2 * pad)
                }
            }
        }

        Connections {
            target: root
            function onTimeChanged() { blocks.requestPaint() }
            function onStartChanged() { blocks.requestPaint() }
            function onSpanChanged() { blocks.requestPaint() }
            function onDelayChanged() { blocks.requestPaint() }
            function onCuesChanged() { blocks.requestPaint() }
            function onAccentChanged() { blocks.requestPaint() }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        // where the media is
        Rectangle {
            visible: root.time >= root.start && root.time <= root.end
            x: Math.round(blocks.xOf(root.time) - width / 2)
            width: VLCStyle.dp(6, VLCStyle.scale)
            height: blocks.height
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: root.accent
        }

        MouseArea {
            id: dragArea

            anchors.fill: parent

            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            preventStealing: true

            property real _pressX: 0
            property int _pressDelay: 0
            property bool dragging: false

            // the line under the pointer, if any
            function _cueAt(x) {
                const t = root.start + x / width * root.span - root.delay
                for (let i = 0; i + 1 < root.cues.length; i += 2) {
                    if (t >= root.cues[i] && t <= root.cues[i + 1])
                        return true
                }
                return false
            }

            property bool overCue: false
            onPositionChanged: (mouse) => {
                if (!pressed) {
                    overCue = _cueAt(mouse.x)
                    return
                }
                if (!dragging && Math.abs(mouse.x - _pressX) > VLCStyle.dp(4, VLCStyle.scale))
                    dragging = true
                if (dragging && width > 0)
                    Player.subtitleDelayMS = Math.round(_pressDelay + (mouse.x - _pressX) / width * root.span * 1000)
            }

            cursorShape: dragging || overCue ? Qt.SizeHorCursor : Qt.PointingHandCursor

            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    Player.subtitleDelayMS = 0
                    return
                }
                _pressX = mouse.x
                _pressDelay = Player.subtitleDelayMS
                dragging = false
            }

            onReleased: (mouse) => {
                if (mouse.button !== Qt.LeftButton)
                    return
                if (!dragging && root.length > 0) {
                    // a click: seek there
                    const t = root.start + mouse.x / width * root.span
                    root.follow = true
                    Player.position = Math.max(0, Math.min(1, t / root.length))
                }
                dragging = false
                blocks.requestPaint()
            }

            onCanceled: {
                dragging = false
                blocks.requestPaint()
            }

            onDraggingChanged: blocks.requestPaint()

            T.ToolTip.visible: containsMouse || pressed
            T.ToolTip.delay: dragging ? 0 : VLCStyle.delayToolTipAppear
            T.ToolTip.text: dragging
                            ? qsTr("Subtitles %1").arg(root._formatDelay(Player.subtitleDelayMS))
                            : (overCue ? qsTr("Drag to move the subtitles (%1), right click to reset")
                                         .arg(root._formatDelay(Player.subtitleDelayMS))
                                       : qsTr("Click to seek, drag to move the subtitles"))
        }
    }
}
