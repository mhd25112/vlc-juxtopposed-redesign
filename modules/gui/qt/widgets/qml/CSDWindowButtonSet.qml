/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
import QtQuick.Window


import VLC.MainInterface
import VLC.Style

Row {
    id: windowButtonGroup

    spacing: 0
    padding: 0

    width: implicitWidth

    property color color: theme.fg.primary
    property color hoverColor: PanelStyle.colors((theme.palette?.isDark ?? true)).hover

    readonly property bool useWinIcons: ((MainCtx.osName === MainCtx.Windows)&&(MainCtx.osVersion >= 10))

    // shown between the other buttons and Close
    property Component beforeClose: null

    readonly property bool buttonHovered: {
        let h = false
        for (let i = 0; i < repeater.count; ++i) {
            const button = repeater.itemAt(i)
            h = h || button.hovered || button.showHovered
        }
        for (let i = 0; i < closeRepeater.count; ++i) {
            const button = closeRepeater.itemAt(i)
            h = h || button.hovered || button.showHovered
        }

        return h
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Repeater {
        id: repeater

        model: Array.from(MainCtx.csdButtonModel.windowCSDButtons).filter((b) => b.type !== CSDButton.Close)
        delegate: buttonDelegate
    }

    Loader {
        height: windowButtonGroup.height
        active: !!windowButtonGroup.beforeClose
        visible: active
        sourceComponent: windowButtonGroup.beforeClose
    }

    Repeater {
        id: closeRepeater

        model: Array.from(MainCtx.csdButtonModel.windowCSDButtons).filter((b) => b.type === CSDButton.Close)
        delegate: buttonDelegate
    }

    Component {
        id: buttonDelegate

        CSDWindowButton {
            required property var modelData

            height: windowButtonGroup.height

            showHovered: modelData.showHovered

            externalPressed: modelData.externalPressed

            color: (modelData.type === CSDButton.Close && (hovered || modelData.showHovered))
                   ? "white"
                   : windowButtonGroup.color

            hoverColor: (modelData.type === CSDButton.Close) ? "red" : windowButtonGroup.hoverColor

            isThemeDark: (theme.palette?.isDark ?? true)

            width: VLCStyle.dp(36, VLCStyle.scale)

            iconName: {
                switch (modelData.type) {
                case CSDButton.Minimize:
                    return "minimize"
                case CSDButton.MaximizeRestore:
                    return (MainCtx.intfMainWindow.visibility === Window.Maximized) ? "restore" : "maximize"
                case CSDButton.Close:
                    return "close"
                }
                return ""
            }

            iconTxt:{
                switch (modelData.type) {
                case CSDButton.Minimize:
                {
                    if (useWinIcons)
                        return "\uE921"

                    else
                        return VLCIcons.window_minimize
                }

                case CSDButton.MaximizeRestore:
                {
                    if (useWinIcons)
                        return (MainCtx.intfMainWindow.visibility === Window.Maximized)
                                ? "\uE923"
                                : "\uE922"

                    else
                        return (MainCtx.intfMainWindow.visibility === Window.Maximized)
                                ? VLCIcons.window_restore
                                : VLCIcons.window_maximize
                }

                case CSDButton.Close:
                {
                    if (useWinIcons)
                        return "\uE8BB"

                    else
                        return VLCIcons.window_close
                }
                }
                console.assert(false, "unreachable")
            }

            onClicked: modelData.click()

            // handles VLCStyle.scale changes
            onWidthChanged: Qt.callLater(updateRect)
            onHeightChanged: Qt.callLater(updateRect)

            Connections {
                target: VLCStyle

                // handle window resize
                function onAppWidthChanged() { Qt.callLater(updateRect) }
                function onAppHeightChanged() { Qt.callLater(updateRect) }
            }

            function updateRect() {
                const point = mapToItem(null, 0, 0)
                const rect = Qt.rect(point.x, point.y, width, height)

                modelData.rect = rect
            }
        }
    }
}
