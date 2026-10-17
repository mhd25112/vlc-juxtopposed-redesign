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

import VLC.Style

// A rounded rectangle with a dashed outline: what can be moved, or where it
// can go, in "Customize Player".
Canvas {
    id: root

    property color color: "#6b6b6b"
    property color fillColor: "transparent"
    property real radius: 0
    property real lineWidth: VLCStyle.dp(1, VLCStyle.scale)
    property real dash: VLCStyle.dp(3, VLCStyle.scale)

    onColorChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        const l = lineWidth / 2
        const w = width - lineWidth
        const h = height - lineWidth
        if (w <= 0 || h <= 0)
            return
        const r = Math.max(0, Math.min(radius, w / 2, h / 2))

        ctx.beginPath()
        ctx.moveTo(l + r, l)
        ctx.lineTo(l + w - r, l)
        ctx.arcTo(l + w, l, l + w, l + r, r)
        ctx.lineTo(l + w, l + h - r)
        ctx.arcTo(l + w, l + h, l + w - r, l + h, r)
        ctx.lineTo(l + r, l + h)
        ctx.arcTo(l, l + h, l, l + h - r, r)
        ctx.lineTo(l, l + r)
        ctx.arcTo(l, l, l + r, l, r)
        ctx.closePath()

        if (fillColor.a > 0) {
            ctx.fillStyle = fillColor
            ctx.fill()
        }
        ctx.setLineDash([dash / lineWidth, dash / lineWidth])
        ctx.lineWidth = lineWidth
        ctx.strokeStyle = color
        ctx.stroke()
    }
}
