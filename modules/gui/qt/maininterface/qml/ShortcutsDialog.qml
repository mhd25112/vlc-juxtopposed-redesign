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
import VLC.Style
import VLC.Widgets as Widgets

// Keyboard shortcuts on their own: every action of VLC with its key and its
// global key, grouped like the preferences, searchable, edited by pressing
// the new key.
Widgets.PanelDialog {
    id: root

    title: qsTr("Keyboard Shortcuts")
    preferredWidth: VLCStyle.dp(1048, VLCStyle.scale)
    preferredHeight: VLCStyle.dp(800, VLCStyle.scale)

    // [{ group, action, option, key, globalKey }]
    property var _hotkeys: []
    // option -> key, not saved yet
    property var _changes: ({})
    property int _changeCount: 0
    property string _search: ""
    property int _searchField: 0 // all, actions, keys

    // option being edited ("key-..." or "global-key-...")
    property string _editing: ""

    // groups of her design, by action
    function groupOf(option) {
        const name = option.replace(/^key-/, "")
        if (/^(toggle-fullscreen|leave-fullscreen|position|intf-show|intf-boss|intf-popup-menu|quit|wallpaper)$/.test(name))
            return qsTr("Basic")
        if (/^(play|pause|play-pause|stop|next|prev|faster|slower|rate-|frame-|loop|random|record|clear-playlist)/.test(name))
            return qsTr("Playback")
        if (/^jump/.test(name))
            return qsTr("Seeking")
        if (/^(vol-|audio|audiodevice)/.test(name))
            return qsTr("Audio")
        if (/^(sub|subtitle)/.test(name))
            return qsTr("Subtitles")
        if (/^(aspect|crop|uncrop|zoom|unzoom|deinterlace|snapshot|toggle-autoscale|incr-scalefactor|decr-scalefactor|viewpoint|projection)/.test(name))
            return qsTr("Video")
        if (/^(nav-|disc-menu|title-|chapter-|program-)/.test(name))
            return qsTr("Menus & Navigation")
        return qsTr("Other")
    }

    function _load() {
        const order = [qsTr("Basic"), qsTr("Playback"), qsTr("Seeking"), qsTr("Audio"), qsTr("Subtitles"),
                       qsTr("Video"), qsTr("Menus & Navigation"), qsTr("Other")]
        return PlayerTweaks.hotkeys()
            .filter((h) => h.action !== "")
            .map((h, i) => Object.assign({}, h, { group: root.groupOf(h.option), index: i }))
            // keep VLC's order inside a group
            .sort((a, b) => (order.indexOf(a.group) - order.indexOf(b.group)) || (a.index - b.index))
    }

    // "Ctrl+Up" -> "Ctrl + Up", "f" -> "F"
    function pretty(key) {
        if (key === "")
            return ""
        return key.split("+").map((part) => part.length === 1 ? part.toUpperCase() : part).join(" + ")
    }

    onOpened: {
        _hotkeys = _load()
        _changes = {}
        _changeCount = 0
        _editing = ""
    }

    function keyOf(option, saved) {
        return (root._changes[option] !== undefined) ? root._changes[option] : saved
    }

    function setKey(option, key) {
        const changes = root._changes
        changes[option] = key
        root._changes = changes
        root._changeCount = Object.keys(changes).length
        root._editing = ""
    }

    // the actions that already use a key
    function users(key, except) {
        if (key === "")
            return []
        return root._hotkeys.filter((h) => h.option !== except && root.keyOf(h.option, h.key) === key)
                            .map((h) => h.action)
    }

    readonly property var _visible: {
        const needle = _search.toLowerCase()
        if (needle === "")
            return _hotkeys
        return _hotkeys.filter((h) => {
            const inAction = h.action.toLowerCase().includes(needle)
            const inKey = (keyOf(h.option, h.key) + " " + keyOf("global-" + h.option, h.globalKey)).toLowerCase().includes(needle)
            return _searchField === 1 ? inAction : (_searchField === 2 ? inKey : (inAction || inKey))
        })
    }

    // [{ group, items }] in the order of VLC's preferences
    readonly property var _groups: {
        const groups = []
        for (const h of _visible) {
            if (groups.length === 0 || groups[groups.length - 1].group !== h.group)
                groups.push({ group: h.group, items: [] })
            groups[groups.length - 1].items.push(h)
        }
        return groups
    }

    ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // search
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(10, VLCStyle.scale)
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.PanelSearchField {
                Layout.fillWidth: true
                placeholderText: qsTr("Search Keyboard Shortcuts...")
                onPatternChanged: root._search = pattern.trim()
            }

            Widgets.PanelComboBox {
                implicitWidth: VLCStyle.dp(160, VLCStyle.scale)
                model: [qsTr("All Fields"), qsTr("Actions"), qsTr("Keys")]
                selectedIndex: root._searchField
                onActivated: (index) => root._searchField = index
            }
        }

        // column titles
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
            spacing: 0

            Heading { Layout.fillWidth: true; text: qsTr("Action") }
            Heading { Layout.preferredWidth: VLCStyle.dp(330, VLCStyle.scale); text: qsTr("Hotkey") }
            Heading { Layout.preferredWidth: VLCStyle.dp(190, VLCStyle.scale); text: qsTr("Global Hotkey") }
        }

        Flickable {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: VLCStyle.dp(6, VLCStyle.scale)

            clip: true
            contentHeight: groupsColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            Column {
                id: groupsColumn

                width: list.width

                Repeater {
                    model: root._groups

                    delegate: Column {
                        required property var modelData

                        width: groupsColumn.width

                        Text {
                            width: parent.width
                            leftPadding: VLCStyle.dp(20, VLCStyle.scale)
                            topPadding: VLCStyle.dp(18, VLCStyle.scale)
                            bottomPadding: VLCStyle.dp(8, VLCStyle.scale)
                            text: modelData.group !== "" ? modelData.group : qsTr("Other")
                            font.pixelSize: VLCStyle.dp(17, VLCStyle.scale)
                            font.weight: Font.DemiBold
                            color: root._c.heading
                        }

                        Repeater {
                            model: modelData.items

                            delegate: ShortcutRow { }
                        }
                    }
                }
            }
        }

        // footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border
            color: root._c.separator
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(70, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)

            Widgets.PanelButton {
                text: qsTr("Cancel")
                flat: true
                onClicked: root.close()
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                visible: root._changeCount > 0
                text: qsTr("%n change(s), applied the next time VLC starts", "", root._changeCount)
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: root._c.label
            }

            Item { Layout.fillWidth: root._changeCount === 0 }

            Widgets.PanelButton {
                text: qsTr("Reset All")
                flat: true
                onClicked: {
                    PlayerTweaks.resetShortcuts()
                    root._hotkeys = root._load()
                    root._changes = {}
                    root._changeCount = 0
                }
            }

            Widgets.PanelButton {
                text: qsTr("Save")
                accent: true
                implicitWidth: VLCStyle.dp(96, VLCStyle.scale)
                onClicked: {
                    PlayerTweaks.setHotkeys(root._changes)
                    root.close()
                }
            }
        }
    }

    component ShortcutRow: Item {
        id: row

        required property var modelData

        readonly property string key: root.keyOf(modelData.option, modelData.key)
        readonly property string globalOption: "global-" + modelData.option
        readonly property string globalKey: root.keyOf(globalOption, modelData.globalKey)
        readonly property var conflicts: root.users(key, modelData.option)

        width: list.width
        height: VLCStyle.dp(conflicts.length > 0 ? 54 : 42, VLCStyle.scale)

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(10, VLCStyle.scale)
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: rowHover.hovered ? root._c.hover : "transparent"
        }

        HoverHandler { id: rowHover }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
            spacing: 0

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    width: parent.width
                    text: row.modelData.action
                    elide: Text.ElideRight
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: root._c.text
                }

                Text {
                    visible: row.conflicts.length > 0
                    text: qsTr("Also used by %1").arg(row.conflicts.join(", "))
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    color: theme.accent
                }
            }

            KeyEditor {
                Layout.preferredWidth: VLCStyle.dp(330, VLCStyle.scale)
                option: row.modelData.option
                value: row.key
            }

            KeyEditor {
                Layout.preferredWidth: VLCStyle.dp(190, VLCStyle.scale)
                option: row.globalOption
                value: row.globalKey
            }
        }
    }

    component Heading: Text {
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        font.weight: Font.DemiBold
        color: root._c.label
    }

    // a key cap with its edit button; clicking waits for the new key:
    // Escape cancels, Backspace or Delete removes the key
    component KeyEditor: Item {
        id: editor

        property string option
        property string value

        readonly property bool editing: root._editing === option

        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: editor.editing || editor.value !== ""
                implicitWidth: Math.max(VLCStyle.dp(34, VLCStyle.scale), capText.implicitWidth + VLCStyle.dp(18, VLCStyle.scale))
                implicitHeight: VLCStyle.dp(28, VLCStyle.scale)
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: editor.editing ? PanelStyle.accentFill(theme.accent, (theme.palette?.isDark ?? true)) : root._c.raised
                border.width: VLCStyle.border
                border.color: editor.editing ? theme.accent : root._c.separatorBright

                Text {
                    id: capText
                    anchors.centerIn: parent
                    text: editor.editing ? qsTr("Press a key...") : root.pretty(editor.value)
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                    font.weight: Font.DemiBold
                    color: editor.editing ? theme.accent : root._c.bright
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !editor.editing && editor.value === ""
                text: "-"
                color: root._c.dim
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }

            T.AbstractButton {
                id: editButton

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: VLCStyle.dp(28, VLCStyle.scale)
                implicitHeight: implicitWidth

                onClicked: {
                    root._editing = editor.option
                    keyCatcher.forceActiveFocus()
                }

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: editButton.hovered ? root._c.hover : "transparent"
                }
                contentItem: Widgets.PanelIcon {
                    name: "pencil"
                    size: VLCStyle.dp(18, VLCStyle.scale)
                    color: editButton.hovered ? root._c.text : root._c.dim
                }

                Accessible.name: qsTr("Change the key")
            }
        }

        Item {
            id: keyCatcher

            focus: editor.editing

            Keys.onPressed: (event) => {
                event.accepted = true
                if (event.key === Qt.Key_Escape) {
                    root._editing = ""
                    return
                }
                if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                    root.setKey(editor.option, "")
                    return
                }
                const name = PlayerTweaks.keyName(event.key, event.modifiers, event.text)
                if (name !== "")
                    root.setKey(editor.option, name)
            }
        }
    }
}
