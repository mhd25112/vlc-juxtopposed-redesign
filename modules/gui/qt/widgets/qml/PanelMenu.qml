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

import VLC.Style

// Menu of the redesign: rows with an icon, a name and their keyboard
// shortcut, or an arrow to a submenu.
//
// Entries: { text, icon, shortcut, checked, enabled, separator,
//            action: function, submenu: [entries] }
T.Popup {
    id: root

    property var model: []
    property real menuWidth: VLCStyle.dp(300, VLCStyle.scale)
    // the menu this one is a submenu of
    property var parentMenu: null

    signal triggered(int index)

    // where it was asked to open; kept inside the window as its size
    // becomes known (the rows are laid out after the model is set)
    property point _requested
    // above the point (opened from the control bar)
    property bool _above: false

    x: Math.max(0, Math.min(_requested.x, (parent?.width ?? 0) - width))
    y: Math.max(0, Math.min(_above ? _requested.y - height : _requested.y, (parent?.height ?? 0) - height))

    // closed by the press of the click that would open it again at the same
    // place: the button it opens from was clicked to close it
    property real _closedAt: 0

    function _isToggle(p) {
        return (Date.now() - _closedAt) < 300
                && Math.abs(p.x - _requested.x) < 3 && Math.abs(p.y - _requested.y) < 3
    }

    // opens at a point given in global coordinates
    function popup(globalPoint) {
        const p = parent.mapFromGlobal(globalPoint.x, globalPoint.y)
        if (_isToggle(p))
            return
        _above = false
        _requested = p
        open()
    }

    // opens above an item
    function popupAbove(item) {
        const m = item.mapToItem(parent, 0, -VLCStyle.dp(4, VLCStyle.scale))
        const p = Qt.point(m.x, m.y)
        if (_isToggle(p))
            return
        _above = true
        _requested = p
        open()
    }

    // opens below an item, or above it in the lower half of the window
    function popupFrom(item) {
        const m = item.mapToItem(parent, 0, 0)
        if (m.y > parent.height / 2)
            popupAbove(item)
        else
            popupNextTo(item, false)
    }

    // opens next to an item, below it or on its right for a submenu
    function popupNextTo(item, onRight) {
        const m = item.mapToItem(parent, onRight ? item.width : 0, onRight ? 0 : item.height)
        const p = Qt.point(m.x, m.y - (onRight ? topPadding : 0))
        if (!onRight && _isToggle(p))
            return
        _above = false
        _requested = p
        open()
    }

    function closeAll() {
        close()
        if (parentMenu)
            parentMenu.closeAll()
    }

    parent: T.Overlay.overlay

    width: menuWidth
    implicitHeight: column.implicitHeight + topPadding + bottomPadding
    padding: VLCStyle.dp(4, VLCStyle.scale)

    // a press outside closes it and still reaches what is under it (another
    // item's menu opens at once); presses in a submenu stay in the submenu
    modal: false
    focus: true
    // in the overlay of the window: its "parent" is the whole window
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

    // popups live in the overlay, outside of any colored item
    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    readonly property var _c: PanelStyle.colors((theme.palette?.isDark ?? true))

    property var _submenu: null
    property int _submenuIndex: -1

    function _openSubmenu(index, item) {
        if (_submenu && _submenuIndex === index && _submenu.visible)
            return
        if (!_submenu) {
            const component = Qt.createComponent("PanelMenu.qml")
            _submenu = component.createObject(root.parent, { parentMenu: root })
        }
        _submenuIndex = index
        _submenu.model = root.model[index].submenu
        _submenu.menuWidth = VLCStyle.dp(260, VLCStyle.scale)
        _submenu.popupNextTo(item, true)
    }

    onClosed: {
        _closedAt = Date.now()
        PanelStyle.lastMenuClosedAt = _closedAt
        if (_submenu)
            _submenu.close()
    }

    background: Rectangle {
        color: root._c.popup
        radius: VLCStyle.dp(8, VLCStyle.scale)
        border.width: VLCStyle.border
        border.color: root._c.controlBorder

        // a soft shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: VLCStyle.dp(6, VLCStyle.scale)
            anchors.margins: -VLCStyle.dp(2, VLCStyle.scale)
            radius: parent.radius + VLCStyle.dp(2, VLCStyle.scale)
            color: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    contentItem: ColumnLayout {
        id: column

        spacing: 0

        Repeater {
            model: root.model

            delegate: Item {
                id: row

                required property int index
                required property var modelData

                readonly property bool isSeparator: modelData?.separator === true
                readonly property bool hasSubmenu: !!modelData?.submenu

                Layout.fillWidth: true
                implicitHeight: isSeparator ? VLCStyle.dp(9, VLCStyle.scale) : VLCStyle.dp(44, VLCStyle.scale)

                Rectangle {
                    visible: row.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    x: VLCStyle.dp(12, VLCStyle.scale)
                    width: parent.width - 2 * x
                    height: VLCStyle.border
                    color: root._c.separator
                }

                T.AbstractButton {
                    id: button

                    anchors.fill: parent
                    visible: !row.isSeparator
                    enabled: row.modelData?.enabled !== false
                    focusPolicy: Qt.StrongFocus
                    hoverEnabled: true

                    onHoveredChanged: {
                        if (hovered && row.hasSubmenu)
                            submenuTimer.restart()
                        else
                            submenuTimer.stop()
                    }

                    Timer {
                        id: submenuTimer
                        interval: 250
                        onTriggered: root._openSubmenu(row.index, row)
                    }

                    onClicked: {
                        if (row.hasSubmenu) {
                            root._openSubmenu(row.index, row)
                            return
                        }
                        const action = row.modelData.action
                        root.triggered(row.index)
                        root.closeAll()
                        if (typeof action === "function")
                            action()
                    }

                    Keys.onRightPressed: { if (row.hasSubmenu) root._openSubmenu(row.index, row) }
                    Keys.onLeftPressed: { if (root.parentMenu) root.close() }

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: button.hovered || button.visualFocus || (row.hasSubmenu && root._submenuIndex === row.index && root._submenu?.visible)
                               ? root._c.hover : "transparent"
                    }

                    contentItem: RowLayout {
                        spacing: VLCStyle.dp(10, VLCStyle.scale)

                        Item {
                            Layout.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                            implicitWidth: VLCStyle.dp(22, VLCStyle.scale)
                            implicitHeight: implicitWidth

                            PanelIcon {
                                anchors.centerIn: parent
                                visible: !!row.modelData?.icon || row.modelData?.checked === true
                                name: row.modelData?.checked === true ? "check" : (row.modelData?.icon ?? "")
                                size: VLCStyle.dp(20, VLCStyle.scale)
                                color: row.modelData?.checked === true ? theme.accent
                                                                      : (button.enabled ? root._c.label : root._c.faint)
                                accentColor: button.enabled ? theme.accent : root._c.faint
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData?.text ?? ""
                            font.pixelSize: VLCStyle.dp(13.5, VLCStyle.scale)
                            color: !button.enabled ? root._c.faint
                                   : (button.hovered ? root._c.bright : root._c.text)
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                            visible: !row.hasSubmenu && !!row.modelData?.shortcut
                            text: row.modelData?.shortcut ?? ""
                            font.pixelSize: VLCStyle.dp(12.5, VLCStyle.scale)
                            color: root._c.dim
                        }

                        PanelIcon {
                            Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                            visible: row.hasSubmenu
                            name: "chevron_right"
                            size: VLCStyle.dp(18, VLCStyle.scale)
                            color: root._c.label
                        }
                    }
                }
            }
        }
    }
}
