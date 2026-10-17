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
pragma Singleton

import QtQuick

// Colors of the redesigned interface (player sidebar, library, settings),
// from the color variables of Juxtopposed's VLC redesign: flat surfaces in a
// few steps of grey, near black input fields and the accent color for the
// selection.
QtObject {
    id: root

    readonly property QtObject dark: QtObject {
        readonly property color window: "#1b1b1b"        // BG/A3: title bar, window frame
        readonly property color panel: "#0e0e0e"         // BG/B1: sidebars, library
        readonly property color raised: "#191919"        // BG/A4: navigation, dropdowns
        readonly property color card: "#151515"          // BG/A5: folded settings
        readonly property color field: "#090909"         // BG/B2: inputs, slider tracks
        readonly property color fieldBorder: "#222222"   // Divider/Dim
        readonly property color control: "#191919"       // BG/A4
        readonly property color controlBorder: "#2b2b2b"
        readonly property color hover: "#222222"         // BG/A1
        readonly property color separator: "#222222"     // Divider/Dim
        readonly property color separatorBright: "#373737" // Divider/Bright
        readonly property color knob: "#404040"          // FG/A4
        readonly property color text: "#c6c6c6"          // FG/2
        readonly property color bright: "#eaeaea"        // FG/1
        readonly property color label: "#8f8f8f"         // FG/A2
        readonly property color heading: "#c6c6c6"       // FG/2
        readonly property color dim: "#6b6b6b"           // FG/A3
        readonly property color faint: "#404040"         // FG/A4
        readonly property color popup: "#191919"
        readonly property color video: "#2d2b29"
    }

    // as rendered in the light design: its "transparent" surfaces over the
    // window give a mid grey frame (#ABABAB) and lighter panels (#C2C2C2)
    readonly property QtObject light: QtObject {
        readonly property color window: "#ababab"        // BG/A3 Transparent, as rendered
        readonly property color panel: "#c2c2c2"         // BG/B1 Transparent, as rendered
        readonly property color raised: "#b9b9b9"
        readonly property color card: "#bcbcbc"
        readonly property color field: "#dedede"         // BG/B2: inputs, slider tracks
        readonly property color fieldBorder: "#a6a6a6"
        readonly property color control: "#cecece"
        readonly property color controlBorder: "#9b9b9b" // Divider/Bright
        readonly property color hover: "#b3b3b3"
        readonly property color separator: "#a8a8a8"
        readonly property color separatorBright: "#8a8a8a"
        readonly property color knob: "#8f8f8f"
        readonly property color text: "#2e2e2e"          // FG/A2
        readonly property color bright: "#161616"
        readonly property color label: "#4d4d4d"
        readonly property color heading: "#2e2e2e"
        readonly property color dim: "#7a7a7a"
        readonly property color faint: "#8f8f8f"
        readonly property color popup: "#cbcbcb"
        readonly property color video: "#2d2b29"
    }

    // when a menu last closed (Date.now()): the click closing a menu over
    // the video is not a click on the video
    property real lastMenuClosedAt: 0

    function colors(isDark) {
        return isDark ? root.dark : root.light
    }

    // Accent Bright: the accent over the background, for selections and the
    // filled part of sliders (#371F06 for the default accent #D37918)
    function accentFill(accent, isDark) {
        if (isDark)
            return Qt.rgba(accent.r * 0.26, accent.g * 0.26, accent.b * 0.26, 1)
        const base = 0xd1 / 255
        return Qt.rgba(base + (accent.r - base) * 0.3,
                       base + (accent.g - base) * 0.3,
                       base + (accent.b - base) * 0.3, 1)
    }

    // Accent Dark: a hint of the accent, for hovered selections
    function accentTint(accent, isDark) {
        if (isDark)
            return Qt.rgba(0.055 + accent.r * 0.05, 0.055 + accent.g * 0.03, 0.055 + accent.b * 0.01, 1)
        return Qt.rgba(0.9 + accent.r * 0.08, 0.9 + accent.g * 0.06, 0.9 + accent.b * 0.04, 1)
    }

    // the skip icons show their length when there is a picture for it
    function skipIcon(forward, seconds) {
        const n = Math.round(Number(seconds))
        if ([3, 5, 10, 15, 20, 30, 60].includes(n))
            return (forward ? "forward_" : "backward_") + n
        return forward ? "skip_forward" : "skip_back"
    }

    function icon(name) {
        return "qrc:///redesign/" + name + ".svg"
    }
}
