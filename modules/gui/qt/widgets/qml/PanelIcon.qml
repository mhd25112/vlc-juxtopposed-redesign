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
import VLC.Util

// A line icon of the redesign (pixmaps/redesign), drawn in one color, with
// its accent parts (#FF8800 in the files) in accentColor.
Image {
    id: root

    // file name without extension, such as "subtitles"
    property string name
    property color color: "white"
    // cut-outs of the filled icons, usually the background color
    property color secondaryColor: "black"
    // the accent parts, as in the menus of the redesign
    property color accentColor: color
    property real size: VLCStyle.dp(18, VLCStyle.scale)

    width: size
    height: size

    sourceSize: Qt.size(size, size)
    // drawn at its size, centered, even when a button stretches it
    fillMode: Image.Pad
    horizontalAlignment: Image.AlignHCenter
    verticalAlignment: Image.AlignVCenter
    asynchronous: false

    source: name ? SVGColorImage.colorize(PanelStyle.icon(name))
                                .color1(root.color)
                                .color2(root.secondaryColor)
                                .accent(root.accentColor)
                                .uri()
                 : ""
}
