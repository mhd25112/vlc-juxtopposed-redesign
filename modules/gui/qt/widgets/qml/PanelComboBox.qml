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
import QtQuick.Controls as QQC2

import VLC.Style

// Drop down list of the redesigned panels. The open list marks the current
// entry with a check mark; "curveFor" can give each entry a small curve
// (equalizer presets), "black" makes the button as dark as the input fields.
T.ComboBox {
    id: control

    // function (index) returning a list of values between -1 and 1, or null
    property var curveFor: null
    property bool black: false
    // maximum number of entries visible without scrolling
    property int visibleEntries: 8
    // index of the current value of the setting: picking an entry only asks
    // for a change, the list follows this once the setting changed
    property int selectedIndex: -1

    Binding on currentIndex {
        value: control.selectedIndex
    }

    implicitWidth: VLCStyle.dp(200, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
    rightPadding: VLCStyle.dp(36, VLCStyle.scale)

    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)

    focusPolicy: Qt.StrongFocus

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    function _textAt(index) {
        if (index < 0)
            return ""
        return control.textAt(index)
    }

    background: Rectangle {
        radius: VLCStyle.dp(5, VLCStyle.scale)
        color: control.black ? control._c.field
                             : (control.hovered ? control._c.hover : control._c.control)
        border.width: VLCStyle.border
        border.color: control.visualFocus || control.popup.visible ? theme.accent
                                                                  : (control.black ? control._c.fieldBorder : control._c.controlBorder)
    }

    contentItem: Text {
        text: control.displayText
        font: control.font
        color: control._c.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: PanelIcon {
        x: control.width - width - VLCStyle.dp(12, VLCStyle.scale)
        y: (control.height - height) / 2
        size: VLCStyle.dp(16, VLCStyle.scale)
        name: control.popup.visible ? "chevron_up" : "chevron_down"
        color: control._c.text
    }

    delegate: T.ItemDelegate {
        id: entry

        required property int index

        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)

        highlighted: control.highlightedIndex === index

        background: Rectangle {
            color: entry.highlighted || entry.hovered ? control._c.hover : "transparent"
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }

        contentItem: Item {
            implicitHeight: entryText.implicitHeight

            Canvas {
                id: curve

                readonly property var values: control.curveFor ? control.curveFor(entry.index) : null
                readonly property color stroke: theme.accent

                visible: !!values
                width: visible ? VLCStyle.dp(22, VLCStyle.scale) : 0
                height: VLCStyle.dp(12, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter

                onValuesChanged: requestPaint()
                onStrokeChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    if (!values || values.length < 2)
                        return
                    ctx.strokeStyle = stroke
                    ctx.lineWidth = 1.5
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    for (let i = 0; i < values.length; ++i) {
                        const x = i * (width - 2) / (values.length - 1) + 1
                        const y = height / 2 - values[i] * (height / 2 - 1.5)
                        if (i === 0)
                            ctx.moveTo(x, y)
                        else
                            ctx.lineTo(x, y)
                    }
                    ctx.stroke()
                }
            }

            Text {
                id: entryText

                anchors.left: curve.right
                anchors.leftMargin: curve.visible ? VLCStyle.dp(10, VLCStyle.scale) : 0
                anchors.right: check.left
                anchors.verticalCenter: parent.verticalCenter

                text: control._textAt(entry.index)
                font: control.font
                color: control.currentIndex === entry.index ? control._c.text : control._c.label
                elide: Text.ElideRight
            }

            PanelIcon {
                id: check

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                size: VLCStyle.dp(16, VLCStyle.scale)
                name: "check"
                color: theme.accent
                visible: control.currentIndex === entry.index
            }
        }
    }

    popup: T.Popup {
        y: control.height + VLCStyle.dp(4, VLCStyle.scale)
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight,
                                 control.visibleEntries * VLCStyle.dp(34, VLCStyle.scale)) + topPadding + bottomPadding
        padding: VLCStyle.dp(4, VLCStyle.scale)

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds

            QQC2.ScrollIndicator.vertical: QQC2.ScrollIndicator { }
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: control._c.popup
            border.width: VLCStyle.border
            border.color: control._c.controlBorder
        }
    }
}
