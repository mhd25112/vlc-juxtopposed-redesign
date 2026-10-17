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

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets

// One setting of the settings window, described by "row":
//   { type, label, info, option, ... }
// The control depends on the type: toggle, dropdown, text, number, slider,
// folder, color, button, theme, accent, uiflag, module, audiofilter, eq.
// Settings bound to an option that this build does not have are hidden.
ColumnLayout {
    id: root

    property var row: ({})

    readonly property int rev: PlayerTweaks.revision
    // "ui": a setting of the interface rather than a VLC option
    readonly property bool _ui: row.type === "uiflag" || row.ui === true
    readonly property bool available: !row.option || _ui || PlayerTweaks.optionExists(row.option)
    readonly property real controlWidth: VLCStyle.dp(320, VLCStyle.scale)

    visible: available

    Layout.fillWidth: true
    spacing: VLCStyle.dp(6, VLCStyle.scale)

    function value() {
        root.rev
        if (row.type === "uiflag")
            return String(PlayerTweaks.uiOption(row.option, row.default ?? false)) === "true"
        if (row.ui === true)
            return PlayerTweaks.uiOption(row.option, row.uiDefault)
        if (row.type === "module")
            return PlayerTweaks.moduleInList(row.option, row.module)
        if (row.type === "audiofilter")
            return PlayerTweaks.audioFilter(row.module)
        let v = PlayerTweaks.option(row.option)
        if (row.invert)
            v = !v
        return v
    }

    function setValue(v) {
        if (row.ui === true) {
            PlayerTweaks.setUiOption(row.option, v)
            return
        }
        switch (row.type) {
        case "uiflag":
            PlayerTweaks.setUiOption(row.option, v)
            return
        case "module":
            PlayerTweaks.setModuleInList(row.option, row.module, v)
            return
        case "audiofilter":
            PlayerTweaks.setAudioFilter(row.module, v)
            return
        }
        if (row.invert)
            v = !v
        PlayerTweaks.setOption(row.option, v)
    }

    function choices() {
        root.rev
        if (row.choices)
            return row.choices
        return PlayerTweaks.optionChoices(row.option)
    }

    readonly property var _c: PanelStyle.colors(VLCStyle.palette.isDark)
    readonly property string _info: row.info ?? (row.option && !_ui ? PlayerTweaks.optionInfo(row.option) : "")

    Widgets.PanelRow {
        Layout.minimumHeight: VLCStyle.dp(40, VLCStyle.scale)
        label: root.row.label ?? ""
        info: root._info

        // the control of each type, only one of them is shown
        Loader {
            sourceComponent: {
                switch (root.row.type) {
                case "toggle":
                case "uiflag":
                case "module":
                case "audiofilter":
                    return toggleComponent
                case "dropdown":
                case "eq":
                    return dropdownComponent
                case "text":
                    return textComponent
                case "number":
                    return numberComponent
                case "folder":
                    return folderComponent
                case "color":
                    return colorComponent
                case "button":
                    return buttonComponent
                case "theme":
                    return themeComponent
                case "accent":
                    return accentComponent
                case "segmented":
                    return segmentedComponent
                default:
                    return null
                }
            }
        }
    }

    // sliders sit under their label, with their scale
    Widgets.PanelSlider {
        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(2, VLCStyle.scale)
        visible: root.row.type === "slider"
        enabled: visible

        readonly property real scale: root.row.scale ?? 1

        from: root.row.from ?? 0
        to: root.row.to ?? 1
        stepSize: root.row.step ?? 0.01
        origin: root.row.origin ?? from
        labels: root.row.labels ?? []
        ticks: root.row.ticks ?? []
        boundValue: root.row.type === "slider" ? Number(root.value()) / scale : 0

        onMoved: {
            let v = value * scale
            if (root.row.integer)
                v = Math.round(v)
            root.setValue(v)
            if (root.row.onChange)
                root.row.onChange(v)
        }
    }

    Component {
        id: toggleComponent

        Widgets.PanelToggle {
            implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
            checked: root.value() === true || root.value() === 1
            onSwitched: (on) => root.setValue(on)
        }
    }

    Component {
        id: dropdownComponent

        Widgets.PanelComboBox {
            readonly property var entries: root.choices()

            implicitWidth: root.controlWidth
            model: entries.map((c) => c.text)
            curveFor: root.row.type === "eq" ? (index) => PlayerTweaks.equalizerPresetCurve(
                                                          PlayerTweaks.equalizerPresets.indexOf(entries[index].text)) : null
            selectedIndex: {
                const v = root.value()
                return entries.findIndex((c) => String(c.value) === String(v))
            }
            displayText: currentIndex >= 0 ? currentText : String(root.value() ?? "")
            onActivated: (index) => {
                root.setValue(entries[index].value)
                if (root.row.onChange)
                    root.row.onChange(entries[index].value)
            }
        }
    }

    Component {
        id: textComponent

        Widgets.PanelTextField {
            id: field

            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            placeholderText: root.row.placeholder ?? ""
            echoMode: root.row.password ? TextInput.Password : TextInput.Normal

            Binding on text {
                when: !field.activeFocus
                value: String(root.value() ?? "")
            }
            onEditingFinished: root.setValue(text)
        }
    }

    Component {
        id: numberComponent

        Widgets.PanelTextField {
            readonly property real scale: root.row.scale ?? 1

            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            numeric: true
            value: Number(root.value() ?? 0) / scale + (root.row.offset ?? 0)
            from: root.row.from ?? -1e9
            to: root.row.to ?? 1e9
            stepSize: root.row.step ?? 1
            decimals: root.row.decimals ?? 0
            unit: root.row.unit ?? ""
            onValueModified: (v) => {
                v = (v - (root.row.offset ?? 0)) * scale
                root.setValue(root.row.decimals ? v : Math.round(v))
            }
        }
    }

    Component {
        id: folderComponent

        RowLayout {
            spacing: VLCStyle.dp(8, VLCStyle.scale)

            Widgets.PanelTextField {
                id: folderField

                Layout.preferredWidth: root.controlWidth - browse.implicitWidth - VLCStyle.dp(8, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                placeholderText: root.row.placeholder ?? ""

                Binding on text {
                    when: !folderField.activeFocus
                    value: String(root.value() ?? "")
                }
                onEditingFinished: root.setValue(text)
            }

            Widgets.PanelButton {
                id: browse

                text: qsTr("Browse")
                onClicked: {
                    const url = PlayerTweaks.chooseFolder(root.row.label)
                    if (url.toString() !== "")
                        root.setValue(decodeURIComponent(url.toString().replace(/^file:\/\/\/?/, "")))
                }
            }
        }
    }

    Component {
        id: colorComponent

        Widgets.PanelColorField {
            implicitWidth: VLCStyle.dp(160, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            colorValue: { root.rev; return PlayerTweaks.colorOption(root.row.option) }
            onColorModified: (v) => PlayerTweaks.setColorOption(root.row.option, v)
        }
    }

    Component {
        id: buttonComponent

        Widgets.PanelButton {
            text: root.row.button ?? ""
            accent: root.row.accent === true
            implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
            onClicked: root.row.action()
        }
    }

    Component {
        id: segmentedComponent

        Widgets.PanelSegmented {
            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            model: root.row.choices.map((c) => c.text)
            currentIndex: {
                const v = root.row.get ? root.row.get() : root.value()
                return root.row.choices.findIndex((c) => String(c.value) === String(v))
            }
            onActivated: (index) => {
                if (root.row.set)
                    root.row.set(root.row.choices[index].value)
                else
                    root.setValue(root.row.choices[index].value)
            }
        }
    }

    Component {
        id: themeComponent

        Widgets.PanelSegmented {
            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            // ColorSchemeModel: System 0, Day 1, Night 2
            readonly property var schemes: [1, 2, 0]
            model: [qsTr("Light"), qsTr("Dark"), qsTr("System")]
            currentIndex: schemes.indexOf(MainCtx.colorScheme.scheme)
            onActivated: (index) => MainCtx.colorScheme.setScheme(schemes[index])
        }
    }

    Component {
        id: accentComponent

        Row {
            spacing: VLCStyle.dp(4, VLCStyle.scale)

            Repeater {
                model: ["default", "#D84343", "#D8437E", "#9B59D8", "#3F7FD8", "#2BB3C0", "#3FAE5A", "#D8B23F", "#8F8F8F"]

                delegate: AccentSwatch {
                    required property string modelData
                    value: modelData
                }
            }
        }
    }
}
