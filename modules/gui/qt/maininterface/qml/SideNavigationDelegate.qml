/*****************************************************************************
 * Copyright (C) 2025 VLC authors and VideoLAN
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
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

T.ItemDelegate {
    id: control

    // Properties

    property string iconTxt: ""
    // line icon of the redesign (pixmaps/redesign), preferred to iconTxt
    property string iconName: ""
    // indentation of the sub entries
    property int depth: 0

    property bool showText: true

    property real radius: VLCStyle.button_radius

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: VLCStyle.margin_xxsmall

    leftInset: implicitLeftInset
    rightInset: implicitRightInset

    topInset: implicitTopInset
    bottomInset: implicitBottomInset

    property real implicitLeftInset: VLCStyle.margin_xxsmall
    property real implicitRightInset: VLCStyle.margin_xxsmall

    property real implicitTopInset: VLCStyle.margin_xxxsmall
    property real implicitBottomInset: VLCStyle.margin_xxxsmall

    // Accessible

    Accessible.onPressAction: control.clicked()
    AccessibleCompat.id: {
        if (model.depth !== 0 || !model.uri || model.uri.length === 0) return "";
        const navBarIds = {
            "home": "homeNavBar",
            "video": "videoNavBar",
            "music": "musicNavBar",
            "network": "browseNavBar",
            "discover": "discoverNavBar"
        }
        const id = navBarIds[model.uri[0]]
        if (id !== undefined)
            return id
        else
            return ""
    }

    // Tooltip

    T.ToolTip.visible: (showText === false && T.ToolTip.text && (hovered || visualFocus))

    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    T.ToolTip.text: text

    // Childs

    ColorContext {
        id: theme
        colorSet: ColorContext.TabButton

        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
        enabled: control.enabled
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    background: Rectangle {
        color: control.hovered || control.visualFocus ? control._c.hover : "transparent"
        border.width: control.visualFocus ? VLCStyle.border : 0
        border.color: theme.accent
        radius: VLCStyle.dp(6, VLCStyle.scale)

        Behavior on color { ColorAnimation { duration: VLCStyle.duration_veryShort } }
    }

    contentItem: RowLayout {
        spacing: VLCStyle.margin_xsmall

        Item {
            Layout.preferredWidth: VLCStyle.icon_banner
            Layout.leftMargin: control.depth * VLCStyle.dp(14, VLCStyle.scale)
            Layout.fillHeight: true

            Widgets.PanelIcon {
                anchors.centerIn: parent

                visible: control.iconName !== ""
                size: VLCStyle.dp(22, VLCStyle.scale)

                readonly property bool active: control.highlighted || control.checked

                // the current page shows a filled icon in the accent color
                name: active && ["home", "videos", "music"].includes(control.iconName)
                      ? control.iconName + "_filled" : control.iconName
                color: active ? theme.accent : control._c.label
                secondaryColor: control._c.raised
            }

            Widgets.IconLabel {
                id: iconLabel

                visible: text.length > 0 && control.iconName === ""

                anchors.centerIn: parent

                text: control.iconTxt

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                color: (control.highlighted || control.checked) ? theme.accent : theme.fg.primary

                font.pixelSize: VLCStyle.icon_banner
            }
        }

        T.Label {
            id: label

            Layout.fillWidth: true
            Layout.fillHeight: true

            text: control.text

            verticalAlignment: Text.AlignVCenter

            color: (control.highlighted || control.checked) ? control._c.bright
                                                            : (control.hovered ? control._c.text : control._c.label)

            elide: Text.ElideRight

            visible: control.showText

            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)

            //button text is already exposed
            Accessible.ignored: true

            Behavior on color {
                enabled: theme.initialized

                ColorAnimation {
                    duration: VLCStyle.duration_short
                }
            }
        }
    }
}
