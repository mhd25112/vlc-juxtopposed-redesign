/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQml.Models


import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Player
import VLC.Util

T.Pane {
    id: root

    enum TimeTextPosition {
        Hide,
        AboveSlider,
        LeftRightSlider
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topInset: sliderY

    bottomPadding: VLCStyle.margin_xsmall

    // NOTE: With the slider at the bottom, sliderY is the top of the controls,
    //       popups and the play queue are positioned against it.
    readonly property real sliderY: mapFromItem(contentItem, 0, contentItem.sliderY).y
    property int textPosition: ControlBar.TimeTextPosition.AboveSlider
    // Place the position slider under the buttons, as a thick bar running along
    // the bottom edge, instead of above them:
    property bool sliderAtBottom: false
    // Place the position slider between the left and right buttons, making the
    // whole control bar a single row. Layouts with center controls have no room
    // for it, they fall back to sliderAtBottom.
    property bool sliderInline: false
    readonly property bool _sliderInline: sliderInline && (contentItem?.playerControlLayout?.canHostFillItem ?? false)
    readonly property bool _sliderOutsideTop: sliderAtBottom || _sliderInline
    property int identifier: -1
    property real sliderHeight: VLCStyle.heightBar_xxsmall
    // flat seek bar of the redesign, see SliderBar.flatStyle
    property bool flatSlider: false

    // "Customize Player": the controls in frames, to be moved around
    property bool editMode: false
    property real bookmarksHeight: VLCStyle.controlBarBookmarksHeight
    property bool showRemainingTime: true

    property var menu: undefined

    signal requestLockUnlockAutoHide(bool lock)

    ///incomming signal to request all menu and popup to close
    signal forceUnlock()

    enabled: visible

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => root.Navigation.defaultKeyAction(event)
    Navigation.cancelAction: function() { History.previous(Qt.BacktabFocusReason) }

    Accessible.name: qsTr("Player controls")
    AccessibleCompat.id: "playerControlBar"

    function showChapterMarks() {
        if (contentItem.trackPositionSlider)
            contentItem.trackPositionSlider.showChapterMarks()
    }

    function applyMenu(menu) {
        if (root.menu === menu)
            return

        // NOTE: When applying a new menu we hide the previous one.
        if (menu)
            dismiss()

        root.menu = menu
    }

    function dismiss() {
        if ((typeof menu === undefined) || !menu)
            return
        if (menu.hasOwnProperty("dismiss"))
            menu.dismiss()
        else if (menu.hasOwnProperty("close"))
            menu.close()
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    // the redesign's times, always with the hours: 00:02:10
    function _hms(tick) {
        if (!tick.valid())
            return "--:--:--"
        const total = Math.max(0, tick.toSeconds())
        const pad = (n) => String(n).padStart(2, "0")
        return pad(Math.floor(total / 3600)) + ":" + pad(Math.floor(total / 60) % 60) + ":" + pad(total % 60)
    }

    TextMetrics {
        id: timeTextMetrics
        font.pixelSize: root.flatSlider ? VLCStyle.dp(14, VLCStyle.scale)
                                        : (textPosition === ControlBar.TimeTextPosition.LeftRightSlider) ? VLCStyle.fontSize_small
                                                                                                         : VLCStyle.fontSize_normal
        text: {
            // This text metrics is used for both the time and length, as we want them to have the same width.
            // Length might not be reported in some cases, for that reason we should check both and use the bigger one.

            // Some extra space to compensate non-monospaced fonts ("-" takes more space than ":", double "-" for guarantee)
            return (!root.flatSlider && Player.time.isSubHour() && Player.length.isSubHour()) ? "00--00" : "00--00--00"
        }
    }

    background: Rectangle {
        color: theme.bg.primary
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.margin_xsmall

        readonly property real sliderY: {
            if (!root._sliderOutsideTop)
                return row2.y
            if (root._sliderInline)
                return playerControlLayout.y
            return playerControlLayout.visible ? playerControlLayout.y : bottomRow.y
        }

        // Items of the row holding the position slider, the time labels
        // go on its sides unless they are hidden or shown above it:
        function sliderRowItems() {
            switch (textPosition) {
            case ControlBar.TimeTextPosition.Hide:
                return [trackPositionSlider]
            case ControlBar.TimeTextPosition.AboveSlider:
                // There is no "above" when the slider is not the top row
                return root._sliderOutsideTop ? [mediaTime, trackPositionSlider, mediaRemainingTime]
                                              : [trackPositionSlider]
            case ControlBar.TimeTextPosition.LeftRightSlider:
                return [mediaTime, trackPositionSlider, mediaRemainingTime]
            default:
                return []
            }
        }

        property alias trackPositionSlider: trackPositionSlider

        property alias mediaRemainingTime: mediaRemainingTime

        property alias playerControlLayout: playerControlLayout

        readonly property list<Item> strayItems: [
            T.Label {
                id: mediaTime

                Layout.preferredWidth: (textPosition === ControlBar.TimeTextPosition.LeftRightSlider) ? timeTextMetrics.width : -1

                text: {
                    if (root.flatSlider)
                        return root._hms(Player.time)
                    const length = Player.length
                    return Player.time.formatHMS(length.isSubSecond() ? VLCTick.SubSecondFormattedAsMS : 0)
                }
                color: theme.fg.primary
                font: timeTextMetrics.font
                horizontalAlignment: Text.AlignHCenter

                // TODO: Do not use `Binding` when minimum Qt is 6.12:
                Binding {
                    target: mediaTime
                    property: "mutabilityGroup"
                    when: (mediaTime.mutabilityGroup !== undefined)
                    value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.ModerateMutabilityGroup
                                                                                  : Item.StaticMutabilityGroup
                }

                anchors.left: (parent === pseudoRow) ? parent.left : undefined
                anchors.verticalCenter: (parent === pseudoRow) ? parent.verticalCenter : undefined
            },
            T.Label {
                id: mediaRemainingTime

                Layout.preferredWidth: (textPosition === ControlBar.TimeTextPosition.LeftRightSlider) ? timeTextMetrics.width : -1

                readonly property bool showRemainingTime: (MainCtx.showRemainingTime && Player.remainingTime.valid())

                text: root.flatSlider
                      ? (showRemainingTime ? "-" + root._hms(Player.remainingTime) : root._hms(Player.length))
                      : showRemainingTime
                        ? "-" + Player.remainingTime.formatHMS()
                        : Player.length.formatHMS()
                color: mediaTime.color
                font: timeTextMetrics.font
                horizontalAlignment: Text.AlignHCenter

                visible: root.showRemainingTime

                // TODO: Do not use `Binding` when minimum Qt is 6.12:
                Binding {
                    target: mediaRemainingTime
                    property: "mutabilityGroup"
                    when: (mediaRemainingTime.mutabilityGroup !== undefined)
                    value: ((Player.playingState === Player.PLAYING_STATE_PLAYING) &&
                            mediaRemainingTime.showRemainingTime) ? Item.ModerateMutabilityGroup
                                                                  : Item.StaticMutabilityGroup
                }

                anchors.right: (parent === pseudoRow) ? parent.right : undefined
                anchors.verticalCenter: (parent === pseudoRow) ? parent.verticalCenter : undefined

                TapHandler {
                    onTapped: (eventPoint, button) => {
                        MainCtx.showRemainingTime = !MainCtx.showRemainingTime
                    }
                }

                HoverHandler {
                    id: mediaRemainingTimeHover
                }

                Widgets.ToolTipExt {
                    colorContext.palette: theme.palette

                    visible: mediaRemainingTimeHover.hovered && MainCtx.showRemainingTime && Player.rate !== 1
                    delay: VLCStyle.delayToolTipAppear
                    text: {
                        if (!visible)
                            return ""

                        const playbackSpeed = Math.abs(Player.rate)
                        const adjustedRemainingTime = Player.remainingTime.scale(1 / playbackSpeed)
                            ? Player.remainingTime.scale(1 / playbackSpeed)
                            : Player.remainingTime

                        return qsTr("%1 (%2x)")
                            .arg(adjustedRemainingTime.formatHMS())
                            .arg(+Player.rate.toFixed(2))
                    }

                    x: (parent.width - width) / 2
                }
            },
            SliderBar {
                id: trackPositionSlider

                barHeight: root.sliderHeight
                flatStyle: root.flatSlider

                Accessible.role: Accessible.Slider
                Accessible.name: qsTr("Progress")
                AccessibleCompat.id: "progressSlider"

                Layout.fillWidth: true
                enabled: Player.playingState === Player.PLAYING_STATE_PLAYING || Player.playingState === Player.PLAYING_STATE_PAUSED

                Navigation.parentItem: root
                Navigation.upItem: (root.sliderAtBottom && !root._sliderInline) ? playerControlLayout : null
                Navigation.downItem: root._sliderOutsideTop ? null : playerControlLayout

                activeFocusOnTab: true

                focus: true

                Keys.onPressed: (event) => {
                    Navigation.defaultKeyAction(event)
                }
            },
            Loader {
                id: bookmarksLoader

                parent: root
                active: MainCtx.mediaLibraryAvailable
                source: "qrc:///qt/qml/VLC/MediaLibrary/Bookmarks.qml"

                readonly property Item sliderRow: root._sliderInline ? inlineRow
                                                                     : (root.sliderAtBottom ? bottomRow : row2)

                // Position of the slider in the control bar, it is nested in the
                // controls when it is inline:
                readonly property point sliderPos: {
                    // dependencies of the mapping:
                    void(root.width); void(root.height); void(playerControlLayout.y)
                    void(trackPositionSlider.x); void(trackPositionSlider.y); void(trackPositionSlider.parent)
                    return root.mapFromItem(trackPositionSlider, 0, 0)
                }

                // NOTE: Bookmarks go between the slider and the buttons, which
                //       is above the slider when it is not the top row.
                x: sliderPos.x
                y: root._sliderOutsideTop ? (sliderPos.y - root.bookmarksHeight - VLCStyle.margin_xxsmall)
                                          : (row2.y + row2.height + VLCStyle.margin_xxsmall)
                width: trackPositionSlider.width

                onLoaded: {
                   item.barHeight = Qt.binding(function() { return bookmarksHeight })
                   item.controlBarHovered = Qt.binding(function() { return root.hovered })
                   item.yShift = Qt.binding(function() {
                       return root._sliderOutsideTop ? 0 : row2.height + VLCStyle.margin_xxsmall
                   })
                }
            },
            // Row of the slider when it is inline, hosted by playerControlLayout
            RowLayout {
                id: inlineRow

                children: root._sliderInline ? root.contentItem.sliderRowItems() : []

                spacing: VLCStyle.margin_small

                width: parent ? parent.width : 0
                y: parent ? Math.round((parent.height - height) / 2) : 0
            }
        ]

        Item {
            // BUG: RowLayout can not be used here
            // because of a Qt bug. (Height is
            // incorrectly determined. Could be
            // about nested layouting).

            id: pseudoRow
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.leftMargin: VLCStyle.margin_normal
            Layout.rightMargin: VLCStyle.margin_normal

            implicitHeight: visible ? Math.max(mediaTime.implicitHeight, mediaRemainingTime.implicitHeight) : 0

            visible: children.length > 0

            children: {
                switch (textPosition) {
                case ControlBar.TimeTextPosition.AboveSlider:
                    return root._sliderOutsideTop ? [] : [mediaTime, mediaRemainingTime]
                case ControlBar.TimeTextPosition.Hide:
                case ControlBar.TimeTextPosition.LeftRightSlider:
                default:
                    return []
                }
            }
        }

        RowLayout {
            id: row2

            children: root._sliderOutsideTop ? [] : parent.sliderRowItems()

            visible: children.length > 0

            spacing: VLCStyle.margin_xsmall

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.leftMargin: (textPosition === ControlBar.TimeTextPosition.LeftRightSlider) ? VLCStyle.margin_xsmall
                                                                                              : 0

            Layout.rightMargin: Layout.leftMargin
        }

        PlayerControlLayout {
            id: playerControlLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: VLCStyle.margin_large
            Layout.rightMargin: VLCStyle.margin_large

            identifier: root.identifier
            editMode: root.editMode

            implicitHeight: MainCtx.pinVideoControls ? VLCStyle.controlLayoutHeightPinned
                                                     : VLCStyle.controlLayoutHeight

            visible: root.editMode || (!model?.empty ?? false)

            fillItem: root._sliderInline ? inlineRow : null

            Navigation.upItem: (trackPositionSlider.enabled && !root._sliderOutsideTop) ? trackPositionSlider
                                                                                        : root.Navigation.upItem
            Navigation.downItem: (trackPositionSlider.enabled && root.sliderAtBottom && !root._sliderInline) ? trackPositionSlider
                                                                                                             : null

            onRequestLockUnlockAutoHide: (lock) => root.requestLockUnlockAutoHide(lock)

            onMenuOpened: (menu) => root.applyMenu(menu)

            Component.onCompleted: {
                root.forceUnlock.connect(playerControlLayout.forceUnlock)
            }
        }

        RowLayout {
            id: bottomRow

            children: (root.sliderAtBottom && !root._sliderInline) ? parent.sliderRowItems() : []

            visible: children.length > 0

            spacing: VLCStyle.margin_small

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.leftMargin: VLCStyle.margin_large
            Layout.rightMargin: Layout.leftMargin
        }
    }
}
