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

// A folded group of video filters of the sidebar ("Essential", "Colors"...):
// a switch per filter, and its settings under it while it is on.
Widgets.PanelExpander {
    id: root

    property string title
    // [{ name, text, options: [{ name, text, from, to, step, decimals, unit }] }]
    property var filters: []

    readonly property int _rev: PlayerTweaks.revision

    expandText: title
    collapseText: title

    Repeater {
        model: root.filters

        delegate: ColumnLayout {
            id: filterItem

            required property var modelData

            readonly property bool enabledFilter: { root._rev; return PlayerTweaks.videoFilter(modelData.name) }

            Layout.fillWidth: true
            spacing: VLCStyle.dp(4, VLCStyle.scale)

            Widgets.PanelRow {
                label: filterItem.modelData.text

                Widgets.PanelToggle {
                    checked: filterItem.enabledFilter
                    onSwitched: (on) => PlayerTweaks.setVideoFilter(filterItem.modelData.name, on)
                }
            }

            Repeater {
                model: filterItem.enabledFilter ? filterItem.modelData.options : []

                delegate: Widgets.PanelValueSlider {
                    required property var modelData

                    text: modelData.text
                    from: modelData.from
                    to: modelData.to
                    stepSize: modelData.step
                    decimals: modelData.decimals
                    unit: modelData.unit ?? ""
                    value: { root._rev; return Number(PlayerTweaks.videoOption(modelData.name)) }

                    onMoved: (value) => PlayerTweaks.setVideoOption(modelData.name, value)
                }
            }
        }
    }
}
