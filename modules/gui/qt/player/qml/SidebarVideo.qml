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

// "Video" tab of the player sidebar
SidebarPage {
    id: root

    readonly property int _wideControl: VLCStyle.dp(200, VLCStyle.scale)

    function _filter(name) {
        root.rev
        return PlayerTweaks.videoFilter(name)
    }

    function _option(name) {
        root.rev
        return PlayerTweaks.videoOption(name)
    }

    // filters read most of their options when they start
    function _restart(name, option, value) {
        PlayerTweaks.setVideoFilter(name, false)
        PlayerTweaks.setVideoOption(option, value)
        PlayerTweaks.setVideoFilter(name, true)
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Defaults")

        Widgets.PanelRow {
            label: qsTr("Flip")
        }

        Widgets.PanelSegmented {
            Layout.fillWidth: true

            model: [qsTr("None"), qsTr("Horizontal"), qsTr("Vertical")]
            currentIndex: {
                if (!root._filter("transform"))
                    return 0
                switch (root._option("transform-type")) {
                case "hflip": return 1
                case "vflip": return 2
                default: return 0
                }
            }
            onActivated: (index) => {
                if (index === 0)
                    PlayerTweaks.setVideoFilter("transform", false)
                else
                    root._restart("transform", "transform-type", index === 1 ? "hflip" : "vflip")
            }
        }

        Widgets.PanelRow {
            label: qsTr("Rotate")

            Widgets.PanelTextField {
                numeric: true
                value: root._filter("rotate") ? Number(root._option("rotate-angle")) : 0
                from: -359
                to: 359
                stepSize: 90
                unit: qsTr(" deg")
                onValueModified: (value) => {
                    if (value === 0)
                        PlayerTweaks.setVideoFilter("rotate", false)
                    else
                        root._restart("rotate", "rotate-angle", value)
                }
            }
        }

        Widgets.PanelRow {
            label: qsTr("Zoom")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                enabled: count > 0
                model: Player.zoom
                textRole: "display"
                displayText: count > 0 ? currentText : qsTr("1:1 Original")
                selectedIndex: Player.zoom.currentIndex
                onActivated: (index) => Player.zoom.toggleIndex(index)
            }
        }

        Widgets.PanelRow {
            id: hdrRow

            readonly property var choices: { root.rev; return PlayerTweaks.optionChoices("d3d11-hdr-mode") }

            visible: choices.length > 0
            label: qsTr("HDR")
            info: qsTr("How HDR videos are shown. Applies to the next video.")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                model: hdrRow.choices.map((c) => c.text)
                selectedIndex: {
                    const v = root.read(PlayerTweaks.option, "d3d11-hdr-mode")
                    return hdrRow.choices.findIndex((c) => c.value === v)
                }
                onActivated: (index) => PlayerTweaks.setOption("d3d11-hdr-mode", hdrRow.choices[index].value)
            }
        }

        Widgets.PanelRow {
            id: resolutionRow

            readonly property var choices: { root.rev; return PlayerTweaks.optionChoices("preferred-resolution") }

            label: qsTr("Resolution")
            info: qsTr("The quality picked when a stream comes in several sizes")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                model: resolutionRow.choices.map((c) => c.text)
                selectedIndex: {
                    const v = Number(root.read(PlayerTweaks.option, "preferred-resolution"))
                    return resolutionRow.choices.findIndex((c) => Number(c.value) === v)
                }
                onActivated: (index) => PlayerTweaks.setOption("preferred-resolution", resolutionRow.choices[index].value)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Aspect Ratio")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                enabled: count > 0
                model: Player.aspectRatio
                textRole: "display"
                displayText: count > 0 ? currentText : qsTr("Default")
                selectedIndex: Player.aspectRatio.currentIndex
                onActivated: (index) => Player.aspectRatio.toggleIndex(index)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Crop")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                enabled: count > 0
                model: Player.crop
                textRole: "display"
                displayText: count > 0 ? currentText : qsTr("Default")
                selectedIndex: Player.crop.currentIndex
                onActivated: (index) => Player.crop.toggleIndex(index)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Render")
            info: qsTr("Plays here or on a device of the network, such as a Chromecast")

            Widgets.PanelComboBox {
                id: renderCombo

                implicitWidth: root._wideControl
                model: { root.rev; return [qsTr("Local")].concat(PlayerTweaks.renderers()) }
                selectedIndex: { root.rev; return PlayerTweaks.renderer() + 1 }
                onActivated: (index) => PlayerTweaks.setRenderer(index - 1)

                Connections {
                    target: renderCombo.popup
                    function onAboutToShow() { PlayerTweaks.scanRenderers() }
                }
            }
        }
    }

    Widgets.PanelSection {
        Layout.fillWidth: true
        title: qsTr("Filters")

        Widgets.PanelRow {
            label: qsTr("Deinterlace")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                enabled: count > 0
                model: Player.deinterlace
                textRole: "display"
                displayText: count > 0 ? currentText : qsTr("Automatic")
                selectedIndex: Player.deinterlace.currentIndex
                onActivated: (index) => Player.deinterlace.toggleIndex(index)
            }
        }

        Widgets.PanelRow {
            label: qsTr("Deinterlace Mode")

            Widgets.PanelComboBox {
                implicitWidth: root._wideControl
                enabled: count > 0
                model: Player.deinterlaceMode
                textRole: "display"
                displayText: count > 0 ? currentText : qsTr("Auto")
                selectedIndex: Player.deinterlaceMode.currentIndex
                onActivated: (index) => Player.deinterlaceMode.toggleIndex(index)
            }
        }

        VideoFilterGroup {
            title: qsTr("Essential")
            filters: [
                { name: "sharpen", text: qsTr("Sharpen"), options: [
                    { name: "sharpen-sigma", text: qsTr("Sigma"), from: 0, to: 2, step: 0.05, decimals: 2 } ] },
                { name: "hqdn3d", text: qsTr("Denoise"), options: [
                    { name: "hqdn3d-luma-spat", text: qsTr("Spatial luma"), from: 0, to: 254, step: 1, decimals: 1 },
                    { name: "hqdn3d-chroma-spat", text: qsTr("Spatial chroma"), from: 0, to: 254, step: 1, decimals: 1 },
                    { name: "hqdn3d-luma-temp", text: qsTr("Temporal luma"), from: 0, to: 254, step: 1, decimals: 1 },
                    { name: "hqdn3d-chroma-temp", text: qsTr("Temporal chroma"), from: 0, to: 254, step: 1, decimals: 1 } ] },
                { name: "gradfun", text: qsTr("Deband"), options: [
                    { name: "gradfun-strength", text: qsTr("Strength"), from: 0.51, to: 255, step: 0.5, decimals: 2 } ] },
                { name: "grain", text: qsTr("Film Grain"), options: [
                    { name: "grain-variance", text: qsTr("Variance"), from: 0, to: 10, step: 0.1, decimals: 1 } ] }
            ]
        }

        VideoFilterGroup {
            title: qsTr("Colors")
            filters: [
                { name: "adjust", text: qsTr("Image Adjust"), options: [
                    { name: "brightness", text: qsTr("Brightness"), from: 0, to: 2, step: 0.01, decimals: 2 },
                    { name: "contrast", text: qsTr("Contrast"), from: 0, to: 2, step: 0.01, decimals: 2 },
                    { name: "saturation", text: qsTr("Saturation"), from: 0, to: 3, step: 0.01, decimals: 2 },
                    { name: "hue", text: qsTr("Hue"), from: -180, to: 180, step: 1, decimals: 0 },
                    { name: "gamma", text: qsTr("Gamma"), from: 0.01, to: 10, step: 0.01, decimals: 2 } ] },
                { name: "invert", text: qsTr("Invert Colors"), options: [] },
                { name: "sepia", text: qsTr("Sepia"), options: [
                    { name: "sepia-intensity", text: qsTr("Intensity"), from: 0, to: 255, step: 1, decimals: 0 } ] },
                { name: "posterize", text: qsTr("Posterize"), options: [
                    { name: "posterize-level", text: qsTr("Levels"), from: 2, to: 256, step: 1, decimals: 0 } ] }
            ]
        }

        VideoFilterGroup {
            title: qsTr("Crop")
            filters: [
                { name: "croppadd", text: qsTr("Crop Borders"), options: [
                    { name: "croppadd-croptop", text: qsTr("Top"), from: 0, to: 1000, step: 2, decimals: 0, unit: "px" },
                    { name: "croppadd-cropbottom", text: qsTr("Bottom"), from: 0, to: 1000, step: 2, decimals: 0, unit: "px" },
                    { name: "croppadd-cropleft", text: qsTr("Left"), from: 0, to: 1000, step: 2, decimals: 0, unit: "px" },
                    { name: "croppadd-cropright", text: qsTr("Right"), from: 0, to: 1000, step: 2, decimals: 0, unit: "px" } ] }
            ]
        }

        VideoFilterGroup {
            title: qsTr("Effects")
            filters: [
                { name: "mirror", text: qsTr("Mirror"), options: [] },
                { name: "oldmovie", text: qsTr("Old Movie"), options: [] },
                { name: "vhs", text: qsTr("VHS"), options: [] },
                { name: "motionblur", text: qsTr("Motion Blur"), options: [
                    { name: "blur-factor", text: qsTr("Factor"), from: 1, to: 127, step: 1, decimals: 0 } ] },
                { name: "edgedetection", text: qsTr("Edge Detection"), options: [] },
                { name: "psychedelic", text: qsTr("Psychedelic"), options: [] }
            ]
        }
    }
}
