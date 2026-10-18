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

// "Show Subtitle Timeline on Seekbar": the seek bar with the subtitle lines
// as blocks. A click or a drag seeks; press and hold, then drag, to move the
// subtitles earlier or later: the bar zooms on half a minute around what
// plays meanwhile, and zooms back out once released. It also zooms for a
// moment when the subtitle delay is changed elsewhere (the sidebar, the
// keyboard), to show the lines move. Right click resets the delay.
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

    // the zoomed window: half a minute around what plays
    readonly property real zoomSpan: Math.max(1, Math.min(30, length))
    property real _focusTime: 0
    readonly property real _zoomStart: Math.max(0, Math.min(_focusTime - zoomSpan / 2, length - zoomSpan))

    // 0: the whole media, 1: zoomed
    property bool adjusting: false
    property real zoom: adjusting ? 1 : 0
    Behavior on zoom {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    readonly property bool zoomed: zoom > 0.5

    // the window shown, zooming smoothly (the span on a log scale), the
    // moment adjusted staying in place
    readonly property real viewSpan: length <= 0 ? 1 : length * Math.pow(zoomSpan / length, zoom)
    readonly property real viewStart: {
        if (length <= 0)
            return 0
        const anchorFull = _focusTime / length
        const anchorZoomed = (_focusTime - _zoomStart) / zoomSpan
        const anchor = anchorFull + (anchorZoomed - anchorFull) * zoom
        return Math.max(0, Math.min(_focusTime - anchor * viewSpan, length - viewSpan))
    }
    readonly property real viewEnd: viewStart + viewSpan

    function _timeAt(x) {
        return viewStart + Math.max(0, Math.min(1, x / blocks.width)) * viewSpan
    }

    function _seekTo(x) {
        if (length > 0)
            Player.position = _timeAt(x) / length
    }

    function _formatDelay(ms) {
        const s = ms / 1000
        return (s > 0 ? "+" : "") + s.toFixed(2) + " s"
    }

    // zoomed out a moment after the last change
    Timer {
        id: zoomOutTimer
        interval: 1500
        onTriggered: {
            if (dragArea.mode !== "adjust")
                root.adjusting = false
        }
    }

    // the delay changed elsewhere: show it
    Connections {
        target: Player
        function onSubtitleDelayChanged() {
            if (dragArea.mode === "adjust")
                return
            if (!root.adjusting)
                root._focusTime = root.time
            root.adjusting = true
            zoomOutTimer.interval = 2000
            zoomOutTimer.restart()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: root.panel.field
        border.width: VLCStyle.border
        border.color: root.zoomed ? Qt.alpha(root.accent, 0.6) : root.panel.fieldBorder

        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    // the lines, the part already played in the accent color
    Canvas {
        id: blocks

        anchors.fill: parent
        anchors.margins: VLCStyle.border + VLCStyle.dp(1, VLCStyle.scale)

        readonly property color playedBack: Qt.tint(root.panel.field, Qt.alpha(root.accent, 0.22))
        readonly property color playedBlock: Qt.tint(root.panel.separatorBright, Qt.alpha(root.accent, 0.35))
        readonly property color block: root.panel.separatorBright
        readonly property color movingBlock: Qt.tint(root.panel.separatorBright, Qt.alpha(root.accent, 0.6))

        function xOf(t) {
            return (t - root.viewStart) / root.viewSpan * width
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (root.viewSpan <= 0 || width <= 0)
                return

            const playX = Math.max(0, Math.min(width, xOf(root.time)))
            ctx.fillStyle = playedBack
            ctx.fillRect(0, 0, playX, height)

            const moving = dragArea.mode === "adjust"
            const pad = Math.round(height * 0.14)
            for (let i = 0; i + 1 < root.cues.length; i += 2) {
                const s = root.cues[i] + root.delay
                const e = root.cues[i + 1] + root.delay
                if (e < root.viewStart || s > root.viewEnd)
                    continue
                const x0 = Math.max(0, xOf(s))
                const x1 = Math.min(width, Math.max(x0 + 1, xOf(e)))
                if (moving) {
                    ctx.fillStyle = movingBlock
                    ctx.fillRect(x0, pad, x1 - x0, height - 2 * pad)
                    continue
                }
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
            function onViewStartChanged() { blocks.requestPaint() }
            function onViewSpanChanged() { blocks.requestPaint() }
            function onDelayChanged() { blocks.requestPaint() }
            function onCuesChanged() { blocks.requestPaint() }
            function onAccentChanged() { blocks.requestPaint() }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        // where the media is
        Rectangle {
            visible: root.time >= root.viewStart && root.time <= root.viewEnd
            x: Math.round(blocks.xOf(root.time) - width / 2)
            y: -VLCStyle.dp(1, VLCStyle.scale)
            width: VLCStyle.dp(6, VLCStyle.scale)
            height: blocks.height + 2 * VLCStyle.dp(1, VLCStyle.scale)
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: root.accent
        }
    }

    MouseArea {
        id: dragArea

        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        preventStealing: true

        // "": pressed, not decided yet; "seek": dragging the time;
        // "adjust": moving the subtitles (after holding)
        property string mode: ""
        property real _pressX: 0
        property int _pressDelay: 0

        cursorShape: mode === "adjust" ? Qt.SizeHorCursor : Qt.PointingHandCursor

        Timer {
            id: holdTimer
            interval: 350
            onTriggered: {
                if (!dragArea.pressed || dragArea.mode !== "")
                    return
                dragArea.mode = "adjust"
                zoomOutTimer.stop()
                // around what plays: the line just heard, to move to it
                root._focusTime = root.time
                root.adjusting = true
                blocks.requestPaint()
            }
        }

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Player.subtitleDelayMS = 0
                return
            }
            _pressX = mouse.x
            _pressDelay = Player.subtitleDelayMS
            mode = ""
            holdTimer.restart()
        }

        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const dx = mouse.x - _pressX
            if (mode === "" && Math.abs(dx) > VLCStyle.dp(4, VLCStyle.scale)) {
                holdTimer.stop()
                mode = "seek"
            }
            if (mode === "seek")
                root._seekTo(mouse.x - blocks.x)
            else if (mode === "adjust" && blocks.width > 0)
                // at the scale of the zoomed window
                Player.subtitleDelayMS = Math.round(_pressDelay + dx / blocks.width * root.zoomSpan * 1000)
        }

        onReleased: (mouse) => {
            if (mouse.button !== Qt.LeftButton)
                return
            holdTimer.stop()
            if (mode === "")
                root._seekTo(mouse.x - blocks.x)
            if (mode === "adjust") {
                zoomOutTimer.interval = 1200
                zoomOutTimer.restart()
            }
            mode = ""
            blocks.requestPaint()
        }

        onCanceled: {
            holdTimer.stop()
            if (mode === "adjust")
                zoomOutTimer.restart()
            mode = ""
            blocks.requestPaint()
        }

        T.ToolTip.visible: mode === "adjust" || (root.zoomed && containsMouse)
        T.ToolTip.delay: 0
        T.ToolTip.text: qsTr("Subtitles %1").arg(root._formatDelay(Player.subtitleDelayMS))
    }
}
