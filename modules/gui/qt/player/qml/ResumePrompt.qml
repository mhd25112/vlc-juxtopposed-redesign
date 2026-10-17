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
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets

// "You've watched till 00:45:08 already. [Continue Watching]": the offer to
// continue where the media was left, right above the playback controls
// instead of the far corner of the window.
T.Control {
    id: root

    readonly property bool shown: Player.canRestorePlayback && _pending

    property bool _pending: false

    signal lockAutoHide(bool lock)

    function dismiss() {
        _pending = false
        timeout.stop()
        Player.acknowledgeRestoreCallback()
    }

    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: VLCStyle.duration_short } }

    onShownChanged: lockAutoHide(shown)

    padding: VLCStyle.dp(10, VLCStyle.scale)
    leftPadding: VLCStyle.dp(20, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    Connections {
        target: Player
        function onCanRestorePlaybackChanged() {
            if (Player.canRestorePlayback) {
                root._pending = true
                timeout.restart()
            }
        }
    }

    Component.onCompleted: {
        if (Player.canRestorePlayback) {
            _pending = true
            timeout.restart()
        }
    }

    Timer {
        id: timeout
        interval: 12000
        onTriggered: root.dismiss()
    }

    function _time(ms) {
        const s = Math.floor(ms / 1000)
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const pad = (v) => (v < 10 ? "0" : "") + v
        return pad(h) + ":" + pad(m) + ":" + pad(s % 60)
    }

    background: Rectangle {
        radius: VLCStyle.dp(8, VLCStyle.scale)
        color: root._c.raised
        border.width: VLCStyle.border
        border.color: root._c.separator
    }

    contentItem: RowLayout {
        spacing: VLCStyle.dp(16, VLCStyle.scale)

        Text {
            text: PlayerTweaks.resumeTime > 0
                  ? qsTr("You've watched till %1 already.").arg(root._time(PlayerTweaks.resumeTime))
                  : qsTr("Continue where you left off?")
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: root._c.text
        }

        Widgets.PanelButton {
            text: qsTr("Continue Watching")
            accent: true
            onClicked: {
                Player.restorePlaybackPos()
                root.dismiss()
            }
        }

        T.AbstractButton {
            implicitWidth: VLCStyle.dp(26, VLCStyle.scale)
            implicitHeight: implicitWidth
            onClicked: root.dismiss()

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: parent.hovered ? root._c.hover : "transparent"
            }
            contentItem: Widgets.PanelIcon {
                name: "close"
                size: VLCStyle.dp(16, VLCStyle.scale)
                color: root._c.label
            }

            Accessible.name: qsTr("Dismiss")
        }
    }
}
