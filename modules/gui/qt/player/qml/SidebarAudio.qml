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

// "Audio" tab of the player sidebar
SidebarPage {
    id: root

    readonly property var _delayLabels: [
        { value: -10, text: qsTr("-10 s") },
        { value: 0, text: qsTr("0 s") },
        { value: 10, text: qsTr("+10 s") }
    ]

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Defaults")

        TrackDefaultRows {
            trackOption: "audio-track"
            languageOption: "audio-language"
            trackLabel: qsTr("Audio Track")
            languageLabel: qsTr("Audio Language")
        }

        Widgets.PanelRow {
            label: qsTr("Stereo Mode")
            info: qsTr("Test plays a sound on the left speaker, then on the right one")

            Widgets.PanelButton {
                text: qsTr("Test")
                accent: true
                onClicked: PlayerTweaks.testStereo()
            }
        }

        Widgets.PanelComboBox {
            Layout.fillWidth: true

            enabled: count > 0
            model: Player.audioStereoMode
            textRole: "display"
            displayText: count > 0 ? currentText : qsTr("Unset")
            selectedIndex: Player.audioStereoMode.currentIndex
            onActivated: (index) => Player.audioStereoMode.toggleIndex(index)
        }
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Synchronization")

        Widgets.PanelRow {
            label: qsTr("Audio Track Delay")

            Widgets.PanelTextField {
                numeric: true
                value: Player.audioDelayMS / 1000
                from: -600
                to: 600
                stepSize: 0.05
                decimals: 3
                unit: " s"
                onValueModified: (value) => Player.audioDelayMS = Math.round(value * 1000)
            }
        }

        Widgets.PanelSlider {
            Layout.fillWidth: true
            from: -10
            to: 10
            stepSize: 0.05
            origin: 0
            boundValue: Player.audioDelayMS / 1000
            ticks: [0]
            labels: root._delayLabels
            onMoved: Player.audioDelayMS = Math.round(value * 1000)
        }
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Filters")

        Widgets.PanelRow {
            label: qsTr("Equalizer")
        }

        Widgets.PanelComboBox {
            Layout.fillWidth: true

            visibleEntries: 9
            model: [qsTr("None")].concat(PlayerTweaks.equalizerPresets)
            curveFor: (index) => index > 0 ? PlayerTweaks.equalizerPresetCurve(index - 1) : null
            selectedIndex: { root.rev; return PlayerTweaks.equalizerPreset() + 1 }
            onActivated: (index) => PlayerTweaks.setEqualizerPreset(index - 1)
        }

        Widgets.PanelExpander {
            Widgets.PanelValueSlider {
                text: qsTr("Preamp")
                editable: true
                from: -20
                to: 20
                stepSize: 0.1
                decimals: 1
                unit: qsTr(" dB")
                origin: 0
                value: { root.rev; return Number(PlayerTweaks.audioOption("equalizer-preamp")) }
                onMoved: (value) => {
                    PlayerTweaks.setAudioOption("equalizer-preamp", value)
                    PlayerTweaks.setAudioFilter("equalizer", true)
                }
            }

            Repeater {
                model: PlayerTweaks.equalizerBands

                delegate: Widgets.PanelValueSlider {
                    required property int index
                    required property string modelData

                    text: modelData
                    editable: true
                    from: -20
                    to: 20
                    stepSize: 0.1
                    decimals: 1
                    unit: qsTr(" dB")
                    origin: 0
                    value: { root.rev; return PlayerTweaks.equalizerBandValues()[index] }
                    onMoved: (value) => {
                        PlayerTweaks.setEqualizerBand(index, value)
                        PlayerTweaks.setAudioFilter("equalizer", true)
                    }
                }
            }
        }

        Widgets.PanelRow {
            label: qsTr("2 Pass")
            info: qsTr("Filters the audio twice, for a stronger effect")

            Widgets.PanelToggle {
                checked: { root.rev; return PlayerTweaks.audioOption("equalizer-2pass") === true }
                onSwitched: (on) => PlayerTweaks.setAudioOption("equalizer-2pass", on)
            }
        }

        AudioFilterBlock {
            filter: "compressor"
            text: qsTr("Compressor")
            options: [
                { name: "compressor-rms-peak", text: qsTr("RMS / Peak"), from: 0, to: 1, step: 0.01, decimals: 1 },
                { name: "compressor-attack", text: qsTr("Attack"), from: 1.5, to: 400, step: 0.5, decimals: 1, unit: " ms" },
                { name: "compressor-release", text: qsTr("Release"), from: 2, to: 800, step: 1, decimals: 1, unit: " ms" },
                { name: "compressor-threshold", text: qsTr("Threshold"), from: -30, to: 0, step: 0.5, decimals: 1, unit: " dB" },
                { name: "compressor-ratio", text: qsTr("Ratio"), from: 1, to: 20, step: 0.1, decimals: 1, unit: ":1" },
                { name: "compressor-knee", text: qsTr("Knee Radius"), from: 1, to: 10, step: 0.1, decimals: 1, unit: " dB" },
                { name: "compressor-makeup-gain", text: qsTr("Makeup Gain"), from: 0, to: 24, step: 0.1, decimals: 1, unit: " dB" }
            ]
        }

        AudioFilterBlock {
            filter: "spatializer"
            text: qsTr("Spatializer")
            options: [
                { name: "spatializer-roomsize", text: qsTr("Size"), from: 0, to: 1.1, step: 0.01, decimals: 2 },
                { name: "spatializer-width", text: qsTr("Width"), from: 0, to: 1, step: 0.01, decimals: 2 },
                { name: "spatializer-wet", text: qsTr("Wet"), from: 0, to: 1, step: 0.01, decimals: 2 },
                { name: "spatializer-dry", text: qsTr("Dry"), from: 0, to: 1, step: 0.01, decimals: 2 },
                { name: "spatializer-damp", text: qsTr("Damp"), from: 0, to: 1, step: 0.01, decimals: 2 }
            ]
        }

        AudioFilterBlock {
            filter: "stereo_widen"
            text: qsTr("Stereo Widener")
            options: [
                { name: "stereowiden-delay", text: qsTr("Delay"), from: 1, to: 100, step: 1, decimals: 0, unit: " ms" },
                { name: "stereowiden-feedback", text: qsTr("Feedback"), from: 0, to: 0.9, step: 0.01, decimals: 2 },
                { name: "stereowiden-crossfeed", text: qsTr("Crossfeed"), from: 0, to: 0.8, step: 0.01, decimals: 2 },
                { name: "stereowiden-dry-mix", text: qsTr("Dry Mix"), from: 0, to: 1, step: 0.01, decimals: 2 }
            ]
        }

        AudioFilterBlock {
            filter: "normvol"
            text: qsTr("Volume Normalizer")
            options: [
                { name: "norm-max-level", text: qsTr("Maximum Level"), from: 0, to: 10, step: 0.1, decimals: 1 }
            ]
        }

        Widgets.PanelValueSlider {
            text: qsTr("Adjust Pitch")
            from: -12
            to: 12
            stepSize: 0.5
            decimals: 1
            unit: qsTr(" semitones")
            origin: 0
            value: { root.rev; return PlayerTweaks.audioFilter("scaletempo_pitch") ? Number(PlayerTweaks.audioOption("pitch-shift")) : 0 }
            onMoved: (value) => {
                PlayerTweaks.setAudioOption("pitch-shift", value)
                PlayerTweaks.setAudioFilter("scaletempo_pitch", value !== 0)
            }
        }
    }
}
