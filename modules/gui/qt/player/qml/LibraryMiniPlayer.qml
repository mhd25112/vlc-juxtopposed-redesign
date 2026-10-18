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
import VLC.Playlist
import VLC.Player
import VLC.Util

// The mini player of the library: a card in a bottom corner with the video
// (or the cover) of what plays, its progress, its name and folder, and the
// queue under a button. Dragged, it goes to the closest bottom corner; a
// double click on the picture goes back to the player.
T.Control {
    id: root

    // in the bottom left corner instead of the right one
    property bool atLeft: String(PlayerTweaks.uiOption("miniPlayerLeft", false)) === "true"
    property bool expanded: false
    property real margin: VLCStyle.dp(8, VLCStyle.scale)

    readonly property bool _showVideo: MainCtx.canShowVideoPIP && MainCtx.hasEmbededVideo
                                       && Player.hasVideoOutput
    readonly property bool _isAudio: !Player.hasVideoOutput

    readonly property string _fileName: {
        const url = decodeURIComponent(String(Player.url))
        const parts = url.split(/[\\/]/).filter((p) => p !== "")
        return parts.length > 0 ? parts[parts.length - 1] : ""
    }
    readonly property string _folder: {
        const url = decodeURIComponent(String(Player.url))
        const parts = url.split(/[\\/]/).filter((p) => p !== "")
        return parts.length > 1 && !parts[parts.length - 2].endsWith(":") ? parts[parts.length - 2] : ""
    }

    width: VLCStyle.dp(391, VLCStyle.scale)
    padding: VLCStyle.dp(8, VLCStyle.scale)
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    x: atLeft ? margin : (parent ? parent.width - width - margin : 0)
    y: parent ? parent.height - height - margin : 0

    visible: Player.isStarted

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    readonly property var _c: PanelStyle.colors(theme.palette?.isDark ?? true)

    function _snap() {
        const left = root.x + root.width / 2 < root.parent.width / 2
        root.atLeft = left
        PlayerTweaks.setUiOption("miniPlayerLeft", left)
        root.x = Qt.binding(() => root.atLeft ? root.margin : root.parent.width - root.width - root.margin)
        root.y = Qt.binding(() => root.parent.height - root.height - root.margin)
    }

    readonly property bool _dragging: dragHandler.active || previewMouse.drag.active

    Behavior on x {
        enabled: !root._dragging
        NumberAnimation { duration: VLCStyle.duration_short; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        enabled: !root._dragging
        NumberAnimation { duration: VLCStyle.duration_short; easing.type: Easing.OutCubic }
    }

    DragHandler {
        id: dragHandler

        target: root
        dragThreshold: VLCStyle.dp(6, VLCStyle.scale)
        cursorShape: active ? Qt.DragMoveCursor : Qt.ArrowCursor

        xAxis.minimum: 0
        xAxis.maximum: root.parent ? root.parent.width - root.width : 0
        yAxis.minimum: 0
        yAxis.maximum: root.parent ? root.parent.height - root.height : 0

        onActiveChanged: {
            if (!active)
                root._snap()
        }
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root._c.raised
        border.width: VLCStyle.border
        border.color: root._c.separatorBright

        Widgets.DefaultShadow { }
    }

    contentItem: ColumnLayout {
        id: column

        spacing: 0

        // the picture: the video, or the cover of a song
        Rectangle {
            id: preview

            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(width * 208 / 374)

            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: root._c.card
            border.width: VLCStyle.border
            border.color: root._c.separatorBright
            clip: true

            Loader {
                anchors.fill: parent
                anchors.margins: VLCStyle.border
                active: root._showVideo
                sourceComponent: VideoSurface {
                    videoSurfaceProvider: MainCtx.videoSurfaceProvider
                }
            }

            Image {
                anchors.fill: parent
                anchors.margins: VLCStyle.border
                visible: !root._showVideo && status === Image.Ready
                source: root._showVideo ? "" : (Player.artwork ?? "")
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Widgets.PanelIcon {
                anchors.centerIn: parent
                visible: !root._showVideo && !(Player.artwork && String(Player.artwork) !== "")
                name: root._isAudio ? "music" : "video"
                size: VLCStyle.dp(40, VLCStyle.scale)
                color: root._c.dim
            }

            // over the video: the video gets no mouse events here
            MouseArea {
                id: previewMouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                // moved by the picture too, then to the closest corner
                drag.target: root
                drag.threshold: VLCStyle.dp(6, VLCStyle.scale)
                drag.minimumX: 0
                drag.maximumX: root.parent ? root.parent.width - root.width : 0
                drag.minimumY: 0
                drag.maximumY: root.parent ? root.parent.height - root.height : 0
                drag.onActiveChanged: {
                    if (!drag.active)
                        root._snap()
                }

                onDoubleClicked: MainCtx.playerView = true

                readonly property bool active: containsMouse || playButton.hovered
                                               || openButton.hovered || stopButton.hovered

                // controls over the picture, faded in on hover
                Item {
                    id: overlay

                    anchors.fill: parent
                    opacity: previewMouse.active && !previewMouse.drag.active ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.4)
                        radius: preview.radius
                    }

                    OverlayButton {
                        id: playButton
                        anchors.centerIn: parent
                        size: VLCStyle.dp(52, VLCStyle.scale)
                        iconName: Player.playingState === Player.PLAYING_STATE_PLAYING ? "pause" : "play_filled"
                        description: qsTr("Play/Pause")
                        onClicked: MainPlaylistController.togglePlayPause()
                    }

                    OverlayButton {
                        id: openButton
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                        iconName: "popout"
                        description: qsTr("Open the player")
                        onClicked: MainCtx.playerView = true
                    }

                    OverlayButton {
                        id: stopButton
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                        iconName: "close"
                        description: qsTr("Stop")
                        onClicked: MainPlaylistController.stop()
                    }
                }
            }
        }

        // the progress, a click or a drag seeks
        Rectangle {
            id: progress

            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.dp(6, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.dp(14, VLCStyle.scale)

            radius: height / 2
            color: root._c.field
            border.width: VLCStyle.border
            border.color: root._c.separator

            Rectangle {
                x: VLCStyle.border
                y: VLCStyle.border
                height: parent.height - 2 * VLCStyle.border
                width: Math.max(height, (parent.width - 2 * VLCStyle.border) * Helpers.clamp(Player.position, 0, 1))
                visible: Player.position > 0
                radius: height / 2
                color: progressMouse.containsMouse ? theme.accent
                                                   : PanelStyle.accentFill(theme.accent, theme.palette?.isDark ?? true)
            }

            MouseArea {
                id: progressMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: Player.seekable

                function seek(mouseX) {
                    Player.position = Helpers.clamp(mouseX / width, 0, 1)
                }
                onPressed: (mouse) => seek(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) seek(mouse.x) }
            }

            T.ToolTip {
                visible: progressMouse.containsMouse
                x: Helpers.clamp(progressMouse.mouseX - width / 2, 0, progress.width - width)
                y: -height - VLCStyle.dp(6, VLCStyle.scale)
                padding: VLCStyle.dp(6, VLCStyle.scale)
                contentItem: Text {
                    text: Player.length.scale(Helpers.clamp(progressMouse.mouseX / progress.width, 0, 1)).formatHMS()
                          + " / " + Player.length.formatHMS()
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    color: root._c.text
                }
                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: root._c.popup
                    border.width: VLCStyle.border
                    border.color: root._c.separatorBright
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)

            text: root._isAudio ? (Player.title || root._fileName) : (root._fileName || Player.title)
            elide: Text.ElideMiddle
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            color: root._c.text
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(2, VLCStyle.scale)
            spacing: VLCStyle.dp(4, VLCStyle.scale)

            Chip {
                iconName: "folder"
                text: root._folder
                visible: text !== "" && !root._isAudio
                description: qsTr("Open %1 in the library").arg(text)
                onClicked: PlayerTweaks.locateFolder(Player.url)
            }

            Chip {
                iconName: root._isAudio ? "artist" : "video"
                text: root._isAudio ? Player.artist : (Player.title !== root._fileName ? Player.title : "")
                visible: text !== ""
                interactive: false
            }

            Item { Layout.fillWidth: true }

            Widgets.SvgToolButton {
                iconName: "queue"
                checked: root.expanded
                description: root.expanded ? qsTr("Hide the queue") : qsTr("Show the queue")
                onClicked: root.expanded = !root.expanded
            }
        }

        // the queue, under the button
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.preferredHeight: VLCStyle.border
            visible: root.expanded
            color: root._c.separator
        }

        ListView {
            id: queue

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(320, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(4, VLCStyle.scale)
            visible: root.expanded

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            model: root.expanded ? queueModel : null

            PlaylistListModel {
                id: queueModel
                playlist: MainPlaylistController.playlist
            }

            onVisibleChanged: {
                if (visible)
                    positionViewAtIndex(queueModel.currentIndex, ListView.Contain)
            }

            delegate: T.AbstractButton {
                id: entry

                required property int index
                required property string title
                required property var duration
                required property bool isCurrent

                width: queue.width
                implicitHeight: VLCStyle.dp(38, VLCStyle.scale)

                onClicked: MainPlaylistController.goTo(index, true)

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: entry.isCurrent ? PanelStyle.accentFill(theme.accent, theme.palette?.isDark ?? true)
                                           : (entry.hovered ? root._c.hover : "transparent")
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.dp(10, VLCStyle.scale)

                    Widgets.PanelIcon {
                        Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                        name: entry.isCurrent ? "play_filled" : "file"
                        size: VLCStyle.dp(16, VLCStyle.scale)
                        color: entry.isCurrent ? theme.accent : root._c.label
                    }

                    Text {
                        Layout.fillWidth: true
                        text: entry.title
                        elide: Text.ElideMiddle
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        color: entry.isCurrent ? theme.accent : root._c.text
                    }

                    Text {
                        Layout.rightMargin: VLCStyle.dp(10, VLCStyle.scale)
                        text: entry.duration?.formatHMS() ?? ""
                        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                        color: root._c.dim
                    }
                }

                Accessible.name: title
            }
        }
    }

    // a round dark button over the picture
    component OverlayButton: T.AbstractButton {
        id: overlayButton

        property string iconName
        property string description
        property real size: VLCStyle.dp(32, VLCStyle.scale)

        implicitWidth: size
        implicitHeight: size

        scale: overlayButton.down ? 0.94 : (overlayButton.hovered ? 1.06 : 1)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        background: Rectangle {
            radius: width / 2
            color: overlayButton.hovered ? Qt.rgba(0, 0, 0, 0.78) : Qt.rgba(0, 0, 0, 0.5)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        contentItem: Widgets.PanelIcon {
            name: overlayButton.iconName
            size: overlayButton.size * 0.5
            color: overlayButton.hovered ? "#ffffff" : "#eaeaea"
        }

        T.ToolTip.visible: hovered && description !== ""
        T.ToolTip.text: description
        T.ToolTip.delay: VLCStyle.delayToolTipAppear

        Accessible.name: description
    }

    // icon and name, a button when interactive
    component Chip: T.AbstractButton {
        id: chip

        property string iconName
        property string description
        property bool interactive: true

        Layout.maximumWidth: VLCStyle.dp(150, VLCStyle.scale)
        implicitWidth: chipRow.implicitWidth + VLCStyle.dp(12, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
        enabled: interactive
        hoverEnabled: interactive

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: chip.hovered ? root._c.hover : "transparent"
        }

        contentItem: Item {
            RowLayout {
                id: chipRow

                anchors.verticalCenter: parent.verticalCenter
                x: VLCStyle.dp(6, VLCStyle.scale)
                width: Math.min(implicitWidth, chip.width - VLCStyle.dp(12, VLCStyle.scale))
                spacing: VLCStyle.dp(8, VLCStyle.scale)

                Widgets.PanelIcon {
                    name: chip.iconName
                    size: VLCStyle.dp(20, VLCStyle.scale)
                    color: root._c.label
                }

                Text {
                    Layout.fillWidth: true
                    text: chip.text
                    elide: Text.ElideRight
                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                    color: chip.hovered ? root._c.bright : root._c.text
                }
            }
        }

        T.ToolTip.visible: hovered && description !== ""
        T.ToolTip.text: description
        T.ToolTip.delay: VLCStyle.delayToolTipAppear

        Accessible.name: description || text
    }
}
