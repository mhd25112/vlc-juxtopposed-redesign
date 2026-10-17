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

import VLC.MainInterface
import VLC.Dialogs

// Opens the dialogs of the redesign when asked through
// PlayerTweaks.requestDialog(), each created the first time it is needed.
Item {
    id: root

    // name -> component
    readonly property var _components: ({
        "onboarding": onboardingComponent,
        "settings": settingsComponent,
        "shortcuts": shortcutsComponent,
        "subtitles": subtitlesComponent,
        "network": networkComponent,
        "playlist": playlistComponent
    })

    property var _instances: ({})

    function open(name, argument) {
        if (name === "customize") {
            // arranged in place, in the player (CustomizePlayer)
            MainCtx.playerView = true
            PlayerTweaks.customizing = true
            return
        }

        if (name === "bookmark") {
            if (quickBookmark.item)
                quickBookmark.item.add()
            return
        }

        const component = _components[name]
        if (!component)
            return

        let dialog = _instances[name]
        if (!dialog) {
            dialog = component.createObject(root)
            _instances[name] = dialog
        }
        if (dialog.hasOwnProperty("argument"))
            dialog.argument = argument
        dialog.open()
    }

    Connections {
        target: PlayerTweaks
        function onDialogRequested(name, argument) {
            root.open(name, argument)
        }
        // PlayerTweaks.locateFolder(): show the videos of that folder
        function onFolderLocated(parentId, title) {
            History.push(["video", "all", "group"], { parentId: parentId, title: title },
                         Qt.MouseFocusReason)
        }
    }

    Component.onCompleted: {
        if (String(PlayerTweaks.uiOption("onboardingDone", false)) !== "true")
            Qt.callLater(() => root.open("onboarding"))
    }

    Loader {
        id: quickBookmark
        active: MainCtx.mediaLibraryAvailable
        source: "qrc:///qt/qml/VLC/Player/QuickBookmark.qml"
    }

    Component {
        id: onboardingComponent
        OnboardingDialog { }
    }

    Component {
        id: settingsComponent
        SettingsDialog { }
    }

    Component {
        id: shortcutsComponent
        ShortcutsDialog { }
    }

    Component {
        id: subtitlesComponent
        AddSubtitlesDialog { }
    }

    Component {
        id: networkComponent
        NetworkStreamDialog { }
    }

    Component {
        id: playlistComponent
        NewPlaylistDialog { }
    }
}
