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

// Which track plays by default: its number, or its language. These are the
// "audio-track"/"sub-track" and "audio-language"/"sub-language" options,
// hidden in the advanced preferences until now.
ColumnLayout {
    id: root

    property string trackOption
    property string languageOption
    property string trackLabel
    property string languageLabel

    readonly property int _rev: PlayerTweaks.revision

    Layout.fillWidth: true
    spacing: VLCStyle.dp(10, VLCStyle.scale)

    Widgets.PanelRow {
        label: root.trackLabel
        info: qsTr("Number of the track to play first, empty for the default one")

        Widgets.PanelTextField {
            id: trackField

            placeholderText: qsTr("Auto")
            validator: IntValidator { bottom: 1; top: 99 }

            Binding on text {
                when: !trackField.activeFocus
                value: {
                    root._rev
                    const track = Number(PlayerTweaks.option(root.trackOption))
                    return track >= 0 ? String(track + 1) : ""
                }
            }

            onEditingFinished: {
                const n = parseInt(text)
                PlayerTweaks.setOption(root.trackOption, isNaN(n) ? -1 : n - 1)
            }
        }
    }

    Widgets.PanelRow {
        label: root.languageLabel
        info: qsTr("Languages to prefer, such as \"English\" or \"en,fr\"")

        Widgets.PanelTextField {
            id: languageField

            placeholderText: qsTr("Auto")

            Binding on text {
                when: !languageField.activeFocus
                value: { root._rev; return String(PlayerTweaks.option(root.languageOption) ?? "") }
            }

            onEditingFinished: PlayerTweaks.setOption(root.languageOption, text.trim())
        }
    }
}
