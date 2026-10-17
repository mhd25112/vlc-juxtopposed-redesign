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

// Subtitle presets: "New Custom Preset" saves the current timing and look
// under a name, picking a preset applies it again.
ColumnLayout {
    id: root

    spacing: VLCStyle.dp(8, VLCStyle.scale)

    property bool _naming: false

    readonly property var _entries: [qsTr("New Custom Preset"), qsTr("Default Preset")].concat(PlayerTweaks.subtitlePresets)

    Widgets.PanelComboBox {
        Layout.fillWidth: true

        black: true
        model: root._entries
        displayText: PlayerTweaks.subtitlePreset !== "" ? PlayerTweaks.subtitlePreset : qsTr("Default Preset")
        selectedIndex: {
            const i = PlayerTweaks.subtitlePresets.indexOf(PlayerTweaks.subtitlePreset)
            return i >= 0 ? i + 2 : 1
        }
        onActivated: (index) => {
            if (index === 0) {
                root._naming = true
                nameField.text = ""
                nameField.forceActiveFocus()
            } else if (index === 1) {
                PlayerTweaks.resetSubtitlePreset()
            } else {
                PlayerTweaks.applySubtitlePreset(root._entries[index])
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root._naming
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        Widgets.PanelTextField {
            id: nameField

            Layout.fillWidth: true
            placeholderText: qsTr("Preset name, such as \"Anime\"")

            onAccepted: saveButton.clicked()
            Keys.onEscapePressed: root._naming = false
        }

        Widgets.PanelButton {
            id: saveButton

            text: qsTr("Save")
            accent: true
            enabled: nameField.text.trim() !== ""
            onClicked: {
                PlayerTweaks.saveSubtitlePreset(nameField.text)
                root._naming = false
            }
        }
    }

    Widgets.PanelButton {
        Layout.alignment: Qt.AlignRight
        visible: PlayerTweaks.subtitlePreset !== "" && !root._naming
        flat: true
        iconName: "trash"
        text: qsTr("Remove \"%1\"").arg(PlayerTweaks.subtitlePreset)
        onClicked: PlayerTweaks.removeSubtitlePreset(PlayerTweaks.subtitlePreset)
    }
}
