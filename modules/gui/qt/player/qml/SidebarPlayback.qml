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
import QtQuick.Templates as T

import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets

// "Playback" tab of the player sidebar
SidebarPage {
    id: root

    readonly property var _sleepChoices: [0, 5, 10, 15, 30, 45, 60, 90, 120]

    function _minutes(seconds) {
        const m = Math.floor(seconds / 60)
        const s = seconds % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        separator: false

        Widgets.PanelRow {
            label: qsTr("Show Subtitle Timeline on Seekbar")
            info: qsTr("Shows the lines of the subtitles on the seek bar. Press and hold the seek bar, then drag, to move the subtitles earlier or later; right click to reset.")

            Widgets.PanelToggle {
                checked: root.uiFlag("subtitleTimeline")
                onSwitched: (on) => PlayerTweaks.setUiOption("subtitleTimeline", on)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Show Waveform on Seekbar")
            info: qsTr("Draws the loudness of the audio along the seek bar")

            Widgets.PanelToggle {
                checked: root.uiFlag("waveform")
                onSwitched: (on) => PlayerTweaks.setUiOption("waveform", on)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Show Metadata")
            info: qsTr("Shows the title, format and size of the media over the video")

            Widgets.PanelToggle {
                checked: root.uiFlag("metadata")
                onSwitched: (on) => PlayerTweaks.setUiOption("metadata", on)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Reverse")
            dimmed: !Player.rewindable

            Widgets.PanelToggle {
                enabled: Player.rewindable
                checked: Player.rate < 0
                onSwitched: Player.reverse()
            }
        }

        Widgets.PanelRow {
            label: PlayerTweaks.sleepTimer > 0
                   ? qsTr("Sleep Timer (%1)").arg(root._minutes(PlayerTweaks.sleepTimerRemaining))
                   : qsTr("Sleep Timer")

            Widgets.PanelComboBox {
                implicitWidth: VLCStyle.dp(200, VLCStyle.scale)

                model: root._sleepChoices.map((m) => m === 0 ? qsTr("Off") : qsTr("%1 minutes").arg(m))
                selectedIndex: Math.max(0, root._sleepChoices.indexOf(PlayerTweaks.sleepTimer))
                onActivated: (index) => PlayerTweaks.sleepTimer = root._sleepChoices[index]
            }
        }

        Widgets.PanelRow {
            label: qsTr("Audio Visualizer")

            Widgets.PanelComboBox {
                implicitWidth: VLCStyle.dp(200, VLCStyle.scale)

                enabled: count > 0
                model: Player.audioVisualization
                textRole: "display"
                displayText: count > 0 ? currentText : qsTr("Disabled")
                selectedIndex: Player.audioVisualization.currentIndex
                onActivated: (index) => Player.audioVisualization.toggleIndex(index)
            }
        }

        Widgets.PanelRow {
            Layout.topMargin: VLCStyle.dp(6, VLCStyle.scale)
            label: qsTr("Speed")

            Widgets.PanelTextField {
                numeric: true
                value: Player.rate
                from: 0.25
                to: 4
                stepSize: 0.25
                decimals: 2
                unit: "x"
                enabled: Player.ratechangable
                onValueModified: (value) => Player.rate = value
            }
        }

        Widgets.PanelSlider {
            Layout.fillWidth: true

            from: 0.25
            to: 2
            stepSize: 0.05
            snapMode: T.Slider.SnapAlways
            enabled: Player.ratechangable
            boundValue: Math.abs(Player.rate)
            origin: from
            ticks: [0.5, 0.75, 1, 1.25, 1.5, 1.75]
            labels: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map((v) => ({ value: v, text: String(v) }))

            onMoved: Player.rate = Math.round(value * 100) / 100
        }
    }
}
