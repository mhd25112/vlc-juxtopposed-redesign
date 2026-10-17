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
import VLC.Dialogs
import VLC.Widgets as Widgets

// "Subtitles" tab of the player sidebar: timing and look of the subtitles,
// which can be saved as presets and reused for other series.
SidebarPage {
    id: root

    readonly property bool _pixels: uiFlag("subtitleSizeInPixels")

    readonly property int _fontPixels: { root.rev; return Number(PlayerTweaks.option("freetype-fontsize")) }
    readonly property int _outline: { root.rev; return Number(PlayerTweaks.option("freetype-outline-thickness")) }

    readonly property var _delayLabels: [
        { value: -10, text: qsTr("-10 s") },
        { value: 0, text: qsTr("0 s") },
        { value: 10, text: qsTr("+10 s") }
    ]

    function _setScale(value) {
        PlayerTweaks.setVideoOption("sub-text-scale", Math.round(value))
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Defaults")

        TrackDefaultRows {
            trackOption: "sub-track"
            languageOption: "sub-language"
            trackLabel: qsTr("Subtitle Track")
            languageLabel: qsTr("Subtitle Language")
        }
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Synchronization")

        Widgets.PanelRow {
            label: qsTr("Subtitle Track Delay")

            Widgets.PanelTextField {
                numeric: true
                value: Player.subtitleDelayMS / 1000
                from: -600
                to: 600
                stepSize: 0.05
                decimals: 3
                unit: " s"
                onValueModified: (value) => Player.subtitleDelayMS = Math.round(value * 1000)
            }
        }

        Widgets.PanelSlider {
            Layout.fillWidth: true
            from: -10
            to: 10
            stepSize: 0.05
            origin: 0
            boundValue: Player.subtitleDelayMS / 1000
            ticks: [0]
            labels: root._delayLabels
            onMoved: Player.subtitleDelayMS = Math.round(value * 1000)
        }

        Widgets.PanelRow {
            label: qsTr("Subtitle Speed")
            info: qsTr("Speed of the subtitles compared to the video, to fix subtitles made for another frame rate")

            Widgets.PanelTextField {
                numeric: true
                value: Player.subtitleFPS
                from: 0.1
                to: 10
                stepSize: 0.001
                decimals: 3
                unit: qsTr(" fps")
                onValueModified: (value) => Player.subtitleFPS = value
            }
        }

        Widgets.PanelSlider {
            Layout.fillWidth: true
            from: 0.5
            to: 2
            stepSize: 0.001
            origin: 1
            boundValue: Player.subtitleFPS
            ticks: [1]
            onMoved: Player.subtitleFPS = Number(value.toFixed(3))
        }

        Widgets.PanelRow {
            id: durationRow

            readonly property real factor: { root.rev; return PlayerTweaks.videoFilter("subsdelay") ? Number(PlayerTweaks.videoOption("subsdelay-factor")) : 0 }

            function apply(value) {
                PlayerTweaks.setVideoOption("subsdelay-factor", value)
                PlayerTweaks.setVideoFilter("subsdelay", value > 0)
            }

            label: qsTr("Subtitle Duration Factor")
            info: qsTr("Keeps each line on screen longer, 0 leaves the timing as it is")

            Widgets.PanelTextField {
                numeric: true
                value: durationRow.factor
                from: 0
                to: 20
                stepSize: 0.2
                decimals: 3
                onValueModified: (value) => durationRow.apply(value)
            }
        }

        Widgets.PanelSlider {
            Layout.fillWidth: true
            from: 0
            to: 20
            stepSize: 0.2
            boundValue: durationRow.factor
            onMoved: durationRow.apply(Number(value.toFixed(1)))
        }
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Appearance")

        Widgets.PanelRow {
            label: qsTr("Embedded Sub Format")
            info: qsTr("Uses the styling written in the subtitles, such as italics and colors")

            Widgets.PanelToggle {
                checked: { root.rev; return PlayerTweaks.option("subsdec-formatting") === true }
                onSwitched: (on) => PlayerTweaks.setOption("subsdec-formatting", on)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Subtitle Font")

            Widgets.PanelTextField {
                id: fontField

                Binding on text {
                    when: !fontField.activeFocus
                    value: { root.rev; return String(PlayerTweaks.option("freetype-font") ?? "") }
                }
                onEditingFinished: PlayerTweaks.setOption("freetype-font", text.trim())
            }
        }

        Widgets.PanelRow {
            label: qsTr("Text Color")

            Widgets.PanelColorField {
                colorValue: { root.rev; return PlayerTweaks.colorOption("freetype-color") }
                onColorModified: (value) => PlayerTweaks.setColorOption("freetype-color", value)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Outline Color")

            Widgets.PanelColorField {
                colorValue: { root.rev; return PlayerTweaks.colorOption("freetype-outline-color") }
                onColorModified: (value) => PlayerTweaks.setColorOption("freetype-outline-color", value)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Subtitle Offset")
            info: qsTr("Distance from the bottom of the video")

            Widgets.PanelTextField {
                numeric: true
                value: { root.rev; return Number(PlayerTweaks.videoOption("sub-margin")) }
                from: -2000
                to: 2000
                stepSize: 5
                unit: "px"
                onValueModified: (value) => PlayerTweaks.setVideoOption("sub-margin", Math.round(value))
            }
        }

        Widgets.PanelRow {
            label: qsTr("Size Values")

            Widgets.PanelSegmented {
                implicitWidth: VLCStyle.dp(160, VLCStyle.scale)
                model: [qsTr("Relative"), qsTr("Pixels")]
                currentIndex: root._pixels ? 1 : 0
                onActivated: (index) => {
                    PlayerTweaks.setUiOption("subtitleSizeInPixels", index === 1)
                    if (index === 1 && root._fontPixels <= 0)
                        PlayerTweaks.setOption("freetype-fontsize", 48)
                    else if (index === 0)
                        PlayerTweaks.setOption("freetype-fontsize", 0)
                }
            }
        }

        // Relative sizes
        Widgets.PanelValueSlider {
            visible: !root._pixels
            text: qsTr("Font Size")
            from: 25
            to: 300
            stepSize: 5
            decimals: 0
            unit: "%"
            value: { root.rev; return Number(PlayerTweaks.videoOption("sub-text-scale")) }
            onMoved: (value) => root._setScale(value)
        }

        Widgets.PanelValueSlider {
            visible: !root._pixels
            text: qsTr("Outline Thickness")
            from: 0
            to: 12
            stepSize: 1
            decimals: 0
            unit: "%"
            value: root._outline
            onMoved: (value) => PlayerTweaks.setOption("freetype-outline-thickness", Math.round(value))
        }

        Widgets.PanelValueSlider {
            visible: !root._pixels
            text: qsTr("Background Opacity")
            from: 0
            to: 100
            stepSize: 1
            decimals: 0
            unit: "%"
            value: { root.rev; return Math.round(Number(PlayerTweaks.option("freetype-background-opacity")) * 100 / 255) }
            onMoved: (value) => PlayerTweaks.setOption("freetype-background-opacity", Math.round(value * 255 / 100))
        }

        // Sizes in pixels
        Widgets.PanelRow {
            visible: root._pixels
            label: qsTr("Font Size")

            Widgets.PanelTextField {
                numeric: true
                value: root._fontPixels
                from: 1
                to: 400
                unit: "px"
                onValueModified: (value) => PlayerTweaks.setOption("freetype-fontsize", Math.round(value))
            }
        }

        Widgets.PanelRow {
            visible: root._pixels
            label: qsTr("Outline Thickness")

            Widgets.PanelTextField {
                numeric: true
                value: Math.round(root._outline * Math.max(1, root._fontPixels) / 100)
                from: 0
                to: 50
                unit: "px"
                onValueModified: (value) => PlayerTweaks.setOption("freetype-outline-thickness",
                                     Math.min(50, Math.round(value * 100 / Math.max(1, root._fontPixels))))
            }
        }

        Widgets.PanelRow {
            visible: root._pixels
            label: qsTr("Background Opacity")

            Widgets.PanelTextField {
                numeric: true
                value: { root.rev; return Math.round(Number(PlayerTweaks.option("freetype-background-opacity")) * 100 / 255) }
                from: 0
                to: 100
                stepSize: 5
                unit: "%"
                onValueModified: (value) => PlayerTweaks.setOption("freetype-background-opacity", Math.round(value * 255 / 100))
            }
        }
    }

    SubtitlePresetPicker {
        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
        Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)
    }

    Widgets.PanelButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
        flat: true
        iconName: "preferences"
        text: qsTr("Open Advanced Settings")
        onClicked: PlayerTweaks.requestDialog("settings", "subtitles")
    }
}
