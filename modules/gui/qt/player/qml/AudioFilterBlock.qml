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
import QtQuick.Layouts

import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets

// An audio filter of the sidebar: its switch, and its settings folded under
// "Expand Settings".
ColumnLayout {
    id: root

    property string filter
    property string text
    // [{ name, text, from, to, step, decimals, unit }]
    property var options: []

    readonly property int _rev: PlayerTweaks.revision
    readonly property bool active: { _rev; return PlayerTweaks.audioFilter(filter) }

    Layout.fillWidth: true
    spacing: VLCStyle.dp(8, VLCStyle.scale)

    Widgets.PanelRow {
        label: root.text

        Widgets.PanelToggle {
            checked: root.active
            onSwitched: (on) => PlayerTweaks.setAudioFilter(root.filter, on)
        }
    }

    Widgets.PanelExpander {
        visible: root.options.length > 0

        Repeater {
            model: root.options

            delegate: Widgets.PanelValueSlider {
                required property var modelData

                text: modelData.text
                from: modelData.from
                to: modelData.to
                stepSize: modelData.step
                decimals: modelData.decimals
                unit: modelData.unit ?? ""
                value: { root._rev; return Number(PlayerTweaks.audioOption(modelData.name)) }

                onMoved: (value) => PlayerTweaks.setAudioOption(modelData.name, value)
            }
        }
    }
}
