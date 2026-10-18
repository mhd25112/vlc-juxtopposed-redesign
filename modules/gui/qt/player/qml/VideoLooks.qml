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
import QtQuick.Effects
import QtQuick.Templates as T

import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets

// Looks: ready-made settings of the video filters, each one shown on the
// picture that plays, as the presets of the equalizer show their curve. A
// click applies the filters; the filters below can then be tuned.
ColumnLayout {
    id: root

    spacing: VLCStyle.dp(8, VLCStyle.scale)

    readonly property int _rev: PlayerTweaks.revision

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    // what each look sets (the filters of "adjust", "sepia", "oldmovie" and
    // "vhs"), and how its tile shows it
    readonly property var looks: [
        { name: qsTr("Original") },
        { name: qsTr("Vivid"), adjust: { saturation: 1.6, contrast: 1.15 },
          effect: { saturation: 0.55, contrast: 0.15 } },
        { name: qsTr("Bright"), adjust: { brightness: 1.25, gamma: 1.15 },
          effect: { brightness: 0.22 } },
        { name: qsTr("Contrast"), adjust: { contrast: 1.5 },
          effect: { contrast: 0.45 } },
        { name: qsTr("Muted"), adjust: { saturation: 0.5 },
          effect: { saturation: -0.5 } },
        { name: qsTr("Black & White"), adjust: { saturation: 0, contrast: 1.1 },
          effect: { saturation: -1, contrast: 0.1 } },
        { name: qsTr("Sepia"), sepia: 120,
          effect: { saturation: -1, colorization: 0.45, color: "#a8783c" } },
        { name: qsTr("Old Movie"), filters: ["oldmovie"],
          effect: { saturation: -1, colorization: 0.35, color: "#8c6a3c", brightness: -0.12, contrast: 0.2 } },
        { name: qsTr("VHS"), filters: ["vhs"],
          effect: { saturation: -0.35, contrast: -0.15, colorization: 0.15, color: "#4060ff", blur: 0.2 } }
    ]

    readonly property var _adjustDefaults: ({ brightness: 1, contrast: 1, saturation: 1, hue: 0, gamma: 1 })
    readonly property var _otherFilters: ["oldmovie", "vhs"]

    function apply(look) {
        const adjust = look.adjust ?? null
        for (const key of Object.keys(_adjustDefaults))
            PlayerTweaks.setVideoOption(key, adjust?.[key] ?? _adjustDefaults[key])
        if (look.sepia !== undefined)
            PlayerTweaks.setVideoOption("sepia-intensity", look.sepia)

        // one change of the chain: switching filters one by one goes through
        // chains that do not work (a filter of the graphics card, "adjust",
        // before one that only takes pictures in memory, "oldmovie"), and the
        // picture stays frozen
        const enable = []
        const disable = []
        ;(adjust !== null ? enable : disable).push("adjust")
        ;(look.sepia !== undefined ? enable : disable).push("sepia")
        for (const name of _otherFilters)
            ((look.filters ?? []).includes(name) ? enable : disable).push(name)
        PlayerTweaks.setVideoFilters(enable, disable)
    }

    // the look the filters are set to (if any)
    function _matches(look) {
        root._rev
        const adjustOn = PlayerTweaks.videoFilter("adjust")
        const adjust = look.adjust ?? null
        for (const key of Object.keys(_adjustDefaults)) {
            const want = adjust?.[key] ?? _adjustDefaults[key]
            const have = adjustOn ? Number(PlayerTweaks.videoOption(key)) : _adjustDefaults[key]
            if (Math.abs(want - have) > 0.01)
                return false
        }
        if (PlayerTweaks.videoFilter("sepia") !== (look.sepia !== undefined))
            return false
        for (const name of _otherFilters) {
            if (PlayerTweaks.videoFilter(name) !== (look.filters ?? []).includes(name))
                return false
        }
        return true
    }

    // the picture where the media is, from the thumbnailer (so without the
    // filters already applied)
    property url _frame: ""
    property bool _waiting: false

    function refreshFrame() {
        if (!Player.isStarted || !Player.hasVideoOutput) {
            _frame = ""
            return
        }
        _waiting = true
        PlayerTweaks.requestSeekPreview(Player.url, Player.position)
    }

    Connections {
        target: PlayerTweaks
        function onSeekPreviewChanged() {
            if (!root._waiting)
                return
            root._waiting = false
            root._frame = PlayerTweaks.seekPreview
        }
    }

    Connections {
        target: Player
        function onUrlChanged() { root.refreshFrame() }
        function onHasVideoOutputChanged() { root.refreshFrame() }
    }

    Component.onCompleted: refreshFrame()
    onVisibleChanged: if (visible) refreshFrame()

    Widgets.PanelRow {
        label: qsTr("Looks")
    }

    GridLayout {
        Layout.fillWidth: true

        columns: 3
        columnSpacing: VLCStyle.dp(8, VLCStyle.scale)
        rowSpacing: VLCStyle.dp(10, VLCStyle.scale)

        Repeater {
            model: root.looks

            delegate: T.AbstractButton {
                id: tile

                required property var modelData

                readonly property bool current: root._matches(modelData)
                readonly property var effect: modelData.effect ?? ({})

                Layout.fillWidth: true
                Layout.preferredWidth: 1

                implicitWidth: VLCStyle.dp(100, VLCStyle.scale)
                implicitHeight: picture.height + VLCStyle.dp(6, VLCStyle.scale) + label.implicitHeight

                hoverEnabled: true
                focusPolicy: Qt.StrongFocus

                text: modelData.name

                onClicked: root.apply(modelData)

                Item {
                    id: picture

                    width: tile.width
                    height: Math.round(width * 9 / 16)

                    Image {
                        id: frameImage

                        anchors.fill: parent
                        visible: false
                        source: root._frame
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: VLCStyle.dp(200, VLCStyle.scale)
                    }

                    // without a picture (it is still being made): colors to
                    // show the look on
                    Rectangle {
                        id: standIn

                        anchors.fill: parent
                        visible: false
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#2f6fb0" }
                            GradientStop { position: 0.5; color: "#d8a040" }
                            GradientStop { position: 1.0; color: "#3a8a4a" }
                        }
                    }

                    Item {
                        id: roundMask

                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Rectangle {
                            anchors.fill: parent
                            radius: VLCStyle.dp(6, VLCStyle.scale)
                        }
                    }

                    MultiEffect {
                        anchors.fill: parent

                        source: frameImage.status === Image.Ready ? frameImage : standIn

                        saturation: tile.effect.saturation ?? 0
                        contrast: tile.effect.contrast ?? 0
                        brightness: tile.effect.brightness ?? 0
                        colorization: tile.effect.colorization ?? 0
                        colorizationColor: tile.effect.color ?? "white"
                        blurEnabled: (tile.effect.blur ?? 0) > 0
                        blur: tile.effect.blur ?? 0
                        blurMax: 8

                        maskEnabled: true
                        maskSource: roundMask
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        border.width: tile.current ? VLCStyle.dp(2, VLCStyle.scale) : VLCStyle.border
                        border.color: tile.current ? theme.accent
                                                   : (tile.hovered || tile.visualFocus ? root._c.separatorBright
                                                                                       : root._c.fieldBorder)
                    }
                }

                Text {
                    id: label

                    anchors.top: picture.bottom
                    anchors.topMargin: VLCStyle.dp(6, VLCStyle.scale)
                    width: tile.width

                    text: tile.text
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    color: tile.current ? theme.accent
                                        : (tile.hovered ? root._c.bright : root._c.label)
                }

                Accessible.role: Accessible.Button
                Accessible.name: text
            }
        }
    }
}
