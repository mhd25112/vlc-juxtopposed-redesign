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

// First start: a media folder for the library, the theme and accent color,
// then the keyboard shortcuts worth knowing.
Widgets.PanelDialog {
    id: root

    property int step: 0

    // accent colors offered in onboarding and settings
    readonly property var accents: ["default", "#D84343", "#D8437E", "#9B59D8", "#3F7FD8",
                                    "#2BB3C0", "#3FAE5A", "#D8B23F", "#8F8F8F"]

    showHeader: false
    preferredWidth: VLCStyle.dp(1090, VLCStyle.scale)
    preferredHeight: VLCStyle.dp(759, VLCStyle.scale)
    closePolicy: T.Popup.NoAutoClose

    function finish() {
        if (folderField.text.trim() !== "")
            MainCtx.addLibraryFolderPath(folderField.text)
        PlayerTweaks.setUiOption("onboardingDone", true)
        close()
    }

    // "Alt+Left" -> "Alt + Left", "f" -> "F"
    function _key(option) {
        const key = String(PlayerTweaks.option(option) ?? "")
        if (key === "")
            return "-"
        return key.split("+").map((part) => part.length === 1 ? part.toUpperCase() : part).join(" + ")
    }

    ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    StackLayout {
        anchors.fill: parent
        anchors.bottomMargin: VLCStyle.dp(70, VLCStyle.scale)

        currentIndex: root.step

        // 1. Welcome and a media folder
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - VLCStyle.dp(80, VLCStyle.scale), VLCStyle.dp(595, VLCStyle.scale))
                spacing: VLCStyle.dp(16, VLCStyle.scale)

                Widgets.BannerCone {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: VLCStyle.dp(96, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(96, VLCStyle.scale)
                    sourceSize.width: VLCStyle.dp(96, VLCStyle.scale)
                    sourceSize.height: VLCStyle.dp(96, VLCStyle.scale)
                    color: theme.accent
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: VLCStyle.dp(12, VLCStyle.scale)
                    text: qsTr("Welcome to VLC!")
                    font.pixelSize: VLCStyle.dp(32, VLCStyle.scale)
                    font.weight: Font.DemiBold
                    color: root._c.bright
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("VLC is a free and open source cross-platform multimedia player and framework that plays most multimedia files as well as DVDs, Audio CDs, VCDs, and various streaming protocols.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                    lineHeight: 1.3
                    color: root._c.label
                }

                Text {
                    Layout.topMargin: VLCStyle.dp(40, VLCStyle.scale)
                    text: qsTr("Choose a Media Folder to get started with")
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: root._c.text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(12, VLCStyle.scale)

                    Widgets.PanelTextField {
                        id: folderField

                        Layout.fillWidth: true
                        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
                        text: "~/Videos"
                        placeholderText: qsTr("A folder with your videos or music")
                    }

                    Widgets.PanelButton {
                        text: qsTr("Browse")
                        accent: true
                        onClicked: {
                            const url = PlayerTweaks.chooseFolder(qsTr("Choose a Media Folder"))
                            if (url.toString() !== "")
                                folderField.text = decodeURIComponent(url.toString().replace(/^file:\/\/\/?/, ""))
                        }
                    }
                }
            }
        }

        // 2. Theme and accent color
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: VLCStyle.dp(28, VLCStyle.scale)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Select your preferred theme and color.")
                    font.pixelSize: VLCStyle.dp(28, VLCStyle.scale)
                    font.weight: Font.DemiBold
                    color: root._c.bright
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: VLCStyle.dp(40, VLCStyle.scale)

                    Repeater {
                        model: [
                            // ColorSchemeModel: System 0, Day 1, Night 2
                            { text: qsTr("Light"), scheme: 1, dark: false },
                            { text: qsTr("Dark"), scheme: 2, dark: true },
                            { text: qsTr("System"), scheme: 0, dark: null }
                        ]

                        delegate: T.AbstractButton {
                            id: themeCard

                            required property var modelData

                            readonly property bool current: MainCtx.colorScheme.scheme === modelData.scheme

                            implicitWidth: VLCStyle.dp(200, VLCStyle.scale)
                            implicitHeight: VLCStyle.dp(150, VLCStyle.scale)

                            onClicked: MainCtx.colorScheme.setScheme(modelData.scheme)

                            background: null

                            contentItem: Column {
                                spacing: VLCStyle.dp(12, VLCStyle.scale)

                                ThemePreview {
                                    width: themeCard.width
                                    height: VLCStyle.dp(116, VLCStyle.scale)
                                    dark: themeCard.modelData.dark
                                    accent: theme.accent
                                    selected: themeCard.current
                                    hovered: themeCard.hovered
                                }

                                Text {
                                    width: themeCard.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: themeCard.modelData.text
                                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                                    color: themeCard.current ? theme.accent : root._c.text
                                }
                            }

                            Accessible.name: modelData.text
                            Accessible.checked: current
                        }
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: VLCStyle.dp(12, VLCStyle.scale)

                    Repeater {
                        model: root.accents

                        delegate: AccentSwatch {
                            required property string modelData

                            value: modelData
                        }
                    }
                }
            }
        }

        // 3. Shortcuts
        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(60, VLCStyle.scale)
                spacing: VLCStyle.dp(40, VLCStyle.scale)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Learn the basic keyboard shortcuts.")
                    font.pixelSize: VLCStyle.dp(28, VLCStyle.scale)
                    font.weight: Font.DemiBold
                    color: root._c.bright
                }

                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 2
                    columnSpacing: VLCStyle.dp(120, VLCStyle.scale)
                    rowSpacing: VLCStyle.dp(18, VLCStyle.scale)

                    Repeater {
                        // "keys": hotkey options of VLC, "fixed": shortcuts of the interface
                        model: [
                            { text: qsTr("Play / Pause"), keys: ["key-play-pause"] },
                            { text: qsTr("Toggle Fullscreen"), keys: ["key-toggle-fullscreen"] },
                            { text: qsTr("Seek Backward / Forward"), keys: ["key-jump-short", "key-jump+short"] },
                            { text: qsTr("Increase / Decrease Volume"), keys: ["key-vol-up", "key-vol-down"] },
                            { text: qsTr("Previous / Next Item"), keys: ["key-prev", "key-next"] },
                            { text: qsTr("Show / Hide Queue"), fixed: ["Ctrl + L"] },
                            { text: qsTr("Previous / Next Frame"), keys: ["key-frame-previous", "key-frame-next"] },
                            { text: qsTr("Take a Snapshot"), keys: ["key-snapshot"] },
                            { text: qsTr("Cycle Subtitle Track"), keys: ["key-subtitle-track"] },
                            { text: qsTr("Record"), keys: ["key-record"] },
                            { text: qsTr("Cycle Audio Track"), keys: ["key-audio-track"] },
                            { text: qsTr("Hide the Interface"), fixed: ["Ctrl + H"] }
                        ]

                        delegate: RowLayout {
                            required property var modelData

                            spacing: VLCStyle.dp(24, VLCStyle.scale)

                            Text {
                                Layout.preferredWidth: VLCStyle.dp(230, VLCStyle.scale)
                                text: modelData.text
                                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                                color: root._c.text
                            }

                            Row {
                                Layout.preferredWidth: VLCStyle.dp(170, VLCStyle.scale)
                                spacing: VLCStyle.dp(8, VLCStyle.scale)

                                Repeater {
                                    model: modelData.keys ?? modelData.fixed

                                    delegate: Row {
                                        required property int index
                                        required property string modelData

                                        spacing: VLCStyle.dp(8, VLCStyle.scale)

                                        Text {
                                            visible: index > 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "/"
                                            color: root._c.dim
                                            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                                        }

                                        KeyCap {
                                            text: modelData.startsWith("key-") ? root._key(modelData) : modelData
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    // bottom row: the step dots, "Back" and "Next"
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: VLCStyle.dp(24, VLCStyle.scale)
        height: VLCStyle.dp(40, VLCStyle.scale)
        spacing: VLCStyle.dp(12, VLCStyle.scale)

        Text {
            visible: root.step === 2
            text: qsTr("Find the full list in the menu.")
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            color: root._c.label
        }

        Item { Layout.fillWidth: true }

        Row {
            spacing: VLCStyle.dp(6, VLCStyle.scale)
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: index === root.step ? VLCStyle.dp(18, VLCStyle.scale) : VLCStyle.dp(6, VLCStyle.scale)
                    height: VLCStyle.dp(6, VLCStyle.scale)
                    radius: height / 2
                    color: index === root.step ? theme.accent : root._c.faint
                    Behavior on width { NumberAnimation { duration: VLCStyle.duration_short } }
                }
            }
        }

        Item { Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale) }

        Widgets.PanelButton {
            visible: root.step > 0
            text: qsTr("Back")
            flat: true
            onClicked: root.step -= 1
        }

        Widgets.PanelButton {
            text: root.step === 2 ? qsTr("Finish") : qsTr("Next")
            accent: true
            implicitWidth: VLCStyle.dp(96, VLCStyle.scale)
            onClicked: {
                if (root.step === 2)
                    root.finish()
                else
                    root.step += 1
            }
        }
    }

    component KeyCap: Rectangle {
        property alias text: keyText.text

        implicitWidth: Math.max(VLCStyle.dp(34, VLCStyle.scale), keyText.implicitWidth + VLCStyle.dp(18, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: PanelStyle.colors(VLCStyle.palette.isDark).raised
        border.width: VLCStyle.border
        border.color: PanelStyle.colors(VLCStyle.palette.isDark).separatorBright

        Text {
            id: keyText
            anchors.centerIn: parent
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            font.weight: Font.DemiBold
            color: PanelStyle.colors(VLCStyle.palette.isDark).bright
        }
    }
}
