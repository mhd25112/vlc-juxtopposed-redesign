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
import VLC.Dialogs
import VLC.Style
import VLC.Widgets as Widgets

// The settings of the redesign: App, Media and System categories, each page
// with its common settings, written as plain words, and the rest folded
// under "Advanced Options". Every setting is a VLC option, so changes apply
// to the next media (or right away when VLC can) and are saved as usual.
Widgets.PanelDialog {
    id: root

    // name of the page to show, see _pages
    property var argument: undefined
    property string page: "global"

    title: _search !== "" ? qsTr("Search Results") : (_currentPage?.title ?? "")
    preferredWidth: VLCStyle.dp(1048, VLCStyle.scale)
    preferredHeight: VLCStyle.dp(865, VLCStyle.scale)
    showHeader: false

    onArgumentChanged: {
        if (typeof argument === "string" && argument !== "")
            page = argument
    }

    property string _search: ""
    readonly property var _currentPage: _pages.find((p) => p.name === root.page)

    readonly property var _sliderPercent: [
        { value: 0, text: "0%" }, { value: 0.5, text: "50%" }, { value: 1, text: "100%" }
    ]

    // --- the pages ---------------------------------------------------------

    readonly property var _pages: [
        { group: qsTr("App"), name: "global", icon: "preferences", title: qsTr("Global Settings"), sections: [
            { title: qsTr("Appearance"), rows: [
                { type: "dropdown", label: qsTr("Interface language"), option: "language" },
                { type: "theme", label: qsTr("Theme") },
                { type: "accent", label: qsTr("Accent color") } ] },
            { title: qsTr("Startup"), rows: [
                { type: "toggle", label: qsTr("Show confirmation and error dialogs"), option: "qt-error-dialogs" },
                { type: "toggle", label: qsTr("Check for updates automatically"), option: "qt-updates-notif" } ] },
            { title: qsTr("Diagnostics"), rows: [
                { type: "uiflag", label: qsTr("Developer mode"), option: "developerMode",
                  info: qsTr("Shows the options meant for developers in the advanced settings") },
                { type: "toggle", label: qsTr("Save a log"), option: "file-logging" },
                { type: "folder", label: qsTr("Log file"), option: "logfile" },
                { type: "dropdown", label: qsTr("Log details"), option: "log-verbose" } ] } ],
          advanced: [
            { title: "", rows: [
                { type: "dropdown", label: qsTr("Show minor warnings"), option: "verbose",
                  choices: [{ text: qsTr("Errors only"), value: 0 }, { text: qsTr("Warnings"), value: 1 }, { text: qsTr("Everything"), value: 2 }] },
                { type: "dropdown", label: qsTr("Log format"), option: "logmode" },
                { type: "toggle", label: qsTr("Collect playback statistics"), option: "stats" },
                { type: "button", label: qsTr("Open configurations folder"), button: qsTr("Open"),
                  action: () => Qt.openUrlExternally(PlayerTweaks.configFolder()) },
                { type: "button", label: qsTr("Reset all settings"), button: qsTr("Reset"), accent: true,
                  action: () => PlayerTweaks.resetAllSettings() } ] },
            { title: qsTr("Developer Options"), developer: true, rows: [
                { type: "toggle", label: qsTr("Write to the system log"), option: "syslog" },
                { type: "toggle", label: qsTr("Include debug messages in the system log"), option: "syslog-debug" },
                { type: "text", label: qsTr("System log identity"), option: "syslog-ident" },
                { type: "dropdown", label: qsTr("System log facility"), option: "syslog-facility" } ] } ] },

        { group: qsTr("App"), name: "interface", icon: "layout", title: qsTr("Interface Settings"), sections: [
            { title: qsTr("Window"), rows: [
                { type: "toggle", label: qsTr("Play video inside main window"), option: "embedded-video" },
                { type: "dropdown", label: qsTr("Resize window to fit video"), option: "qt-video-autoresize",
                  choices: [{ text: qsTr("Never"), value: false }, { text: qsTr("Always"), value: true }] },
                { type: "toggle", label: qsTr("Keep window above other windows"), option: "video-on-top" },
                { type: "toggle", label: qsTr("Show window decorations"), option: "qt-titlebar" },
                { type: "toggle", label: qsTr("Show the file name in the title bar"), option: "qt-name-in-title" },
                { type: "number", label: qsTr("Open fullscreen on screen"), option: "qt-fullscreen-screennumber", from: -1, to: 16 } ] },
            { title: qsTr("Playback Controls"), rows: [
                { type: "toggle", label: qsTr("Start in compact mode"), option: "qt-minimal-view" },
                { type: "dropdown", label: qsTr("Auto-hide the controls"), option: "qt-pin-controls",
                  choices: [{ text: qsTr("In fullscreen only"), value: true }, { text: qsTr("Always"), value: false }] },
                { type: "slider", label: qsTr("Hide after"), option: "mouse-hide-timeout", from: 0, to: 10, step: 0.5,
                  scale: 1000, integer: true,
                  labels: [{ value: 0, text: "0 s" }, { value: 5, text: "5 s" }, { value: 10, text: "10 s" }] },
                { type: "toggle", label: qsTr("Show controls in fullscreen"), option: "qt-fs-controller" } ] },
            { title: qsTr("Notifications and System Tray"), rows: [
                { type: "toggle", label: qsTr("Show a system tray icon"), option: "qt-system-tray" },
                { type: "toggle", label: qsTr("Start minimized to the tray"), option: "qt-start-minimized" },
                { type: "dropdown", label: qsTr("Show a popup when the track changes"), option: "qt-notification" } ] } ],
          advanced: [
            { title: "", rows: [
                { type: "slider", label: qsTr("Window opacity"), option: "qt-opacity", from: 0.1, to: 1, step: 0.05,
                  labels: [{ value: 0.1, text: "10%" }, { value: 1, text: "100%" }] },
                { type: "toggle", label: qsTr("Pause video when window is minimized"), option: "qt-pause-minimized" },
                { type: "toggle", label: qsTr("Allow the app icon to change"), option: "qt-icon-change" },
                { type: "slider", label: qsTr("Fullscreen controls opacity"), option: "qt-fs-opacity", from: 0.1, to: 1, step: 0.05,
                  labels: [{ value: 0.1, text: "10%" }, { value: 1, text: "100%" }] },
                { type: "slider", label: qsTr("Fullscreen controls sensitivity"), option: "qt-fs-sensitivity", from: 0, to: 4000, step: 100,
                  integer: true, labels: [{ value: 0, text: qsTr("High") }, { value: 2000, text: qsTr("Medium") }, { value: 4000, text: qsTr("Low") }] } ] } ] },

        { group: qsTr("App"), name: "privacy", icon: "eye_off", title: qsTr("Privacy Settings"), sections: [
            { title: qsTr("History"), rows: [
                { type: "toggle", label: qsTr("Save recently played items"), option: "save-recentplay" },
                { type: "toggle", label: qsTr("Remember the playback state"), option: "restore-playback-states" },
                { type: "text", label: qsTr("Never remember items matching"), option: "qt-recentplay-filter",
                  placeholder: qsTr("Words or patterns") },
                { type: "button", label: qsTr("Clear history now"), button: qsTr("Clear"), accent: true,
                  action: () => PlayerTweaks.clearHistory() } ] },
            { title: qsTr("Network"), rows: [
                { type: "toggle", label: qsTr("Fetch titles and cover art from the internet"), option: "metadata-network-access" },
                { type: "module", label: qsTr("Submit played tracks to last.fm"), option: "control", module: "audioscrobbler" },
                { type: "text", label: qsTr("Last.fm username"), option: "lastfm-username" },
                { type: "text", label: qsTr("Last.fm password"), option: "lastfm-password", password: true },
                { type: "text", label: qsTr("Last.fm submission URL"), option: "scrobbler-url" } ] } ],
          advanced: [] },

        { group: qsTr("App"), name: "controls", icon: "keyboard", title: qsTr("Mouse, Keyboard & Remote Controls"), short: qsTr("Mouse & Keyboard"), sections: [
            { title: qsTr("Keyboard Shortcuts"), rows: [
                { type: "button", label: qsTr("Defaults"), button: qsTr("Edit Keyboard Shortcuts"),
                  action: () => PlayerTweaks.requestDialog("shortcuts") },
                { type: "button", label: qsTr("Reset all shortcuts"), button: qsTr("Reset"), accent: true,
                  action: () => PlayerTweaks.resetShortcuts() } ] },
            { title: qsTr("Skip Amounts"), rows: [
                { type: "number", label: qsTr("Very short skip"), option: "extrashort-jump-size", unit: " s", from: 1, to: 3600 },
                { type: "number", label: qsTr("Short skip"), option: "short-jump-size", unit: " s", from: 1, to: 3600 },
                { type: "number", label: qsTr("Medium skip"), option: "medium-jump-size", unit: " s", from: 1, to: 3600 },
                { type: "number", label: qsTr("Long skip"), option: "long-jump-size", unit: " s", from: 1, to: 36000 } ] },
            { title: qsTr("Mouse"), rows: [
                { type: "dropdown", ui: true, label: qsTr("Single click on the video"), option: "videoSingleClick",
                  uiDefault: "pause", choices: [{ text: qsTr("Play / Pause"), value: "pause" }, { text: qsTr("Nothing"), value: "none" }] },
                { type: "dropdown", ui: true, label: qsTr("Double click on the video"), option: "videoDoubleClick",
                  uiDefault: "fullscreen", choices: [{ text: qsTr("Toggle fullscreen"), value: "fullscreen" }, { text: qsTr("Nothing"), value: "none" }] },
                { type: "dropdown", label: qsTr("Scroll wheel"), option: "hotkeys-y-wheel-mode" },
                { type: "dropdown", label: qsTr("Horizontal scroll"), option: "hotkeys-x-wheel-mode" } ] },
            { title: qsTr("Remotes"), rows: [
                { type: "module", label: qsTr("Web remote control"), option: "extraintf", module: "http" },
                { type: "number", label: qsTr("Port"), option: "http-port", from: 1, to: 65535 } ] } ],
          advanced: [] },

        { group: qsTr("Media"), name: "playback", icon: "playback", title: qsTr("Playback Preferences"), sections: [
            { title: qsTr("Startup"), rows: [
                { type: "dropdown", label: qsTr("Continue where you left off"), option: "restore-playback-pos" },
                { type: "toggle", label: qsTr("Start playing as soon as a file opens"), option: "start-paused", invert: true },
                { type: "slider", label: qsTr("Default playback speed"), option: "rate", from: 0.25, to: 2, step: 0.05, ticks: [0.5, 0.75, 1, 1.25, 1.5, 1.75],
                  labels: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map((v) => ({ value: v, text: String(v) })) } ] },
            { title: qsTr("Tracks"), rows: [
                { type: "dropdown", label: qsTr("Preferred video quality"), option: "preferred-resolution" },
                { type: "text", label: qsTr("Preferred menu language"), option: "menu-language", placeholder: qsTr("Automatic") },
                { type: "number", label: qsTr("Default audio track"), option: "audio-track", from: 0, to: 99, offset: 1 },
                { type: "number", label: qsTr("Default subtitle track"), option: "sub-track", from: 0, to: 99, offset: 1 } ] },
            { title: qsTr("Order"), rows: [
                { type: "segmented", label: qsTr("Repeat"),
                  choices: [{ text: qsTr("Off"), value: "off" }, { text: qsTr("One"), value: "one" }, { text: qsTr("All"), value: "all" }],
                  get: () => { root._rev; return PlayerTweaks.option("repeat") ? "one" : (PlayerTweaks.option("loop") ? "all" : "off") },
                  set: (v) => { PlayerTweaks.setOption("repeat", v === "one"); PlayerTweaks.setOption("loop", v === "all") } },
                { type: "toggle", label: qsTr("Shuffle"), option: "random" },
                { type: "toggle", label: qsTr("Stop after each item"), option: "play-and-stop" },
                { type: "dropdown", label: qsTr("When playback finishes"), option: "play-and-exit",
                  choices: [{ text: qsTr("Stop"), value: false }, { text: qsTr("Quit VLC"), value: true }] } ] },
            { title: qsTr("Seeking"), rows: [
                { type: "toggle", label: qsTr("Seek precisely"), option: "input-fast-seek", invert: true },
                { type: "uiflag", label: qsTr("Show thumbnail while scrubbing"), option: "seekThumbnails", default: true,
                  info: qsTr("Shows a picture of the video above the seek bar where the pointer is") } ] },
            { title: qsTr("Files & Discs"), rows: [
                { type: "text", label: qsTr("Default optical drive"), option: "dvd" },
                { type: "dropdown", label: qsTr("Repair damaged AVI files"), option: "avi-index" },
                { type: "toggle", label: qsTr("Load matching .mkv files from the same folder"), option: "mkv-preload-local-dir" } ] } ],
          advanced: [
            { title: "", rows: [
                { type: "folder", label: qsTr("Time-shift buffer folder"), option: "input-timeshift-path" },
                { type: "number", label: qsTr("Time-shift buffer size"), option: "input-timeshift-granularity", unit: " B" } ] } ] },

        { group: qsTr("Media"), name: "video", icon: "video", title: qsTr("Video Defaults"), sections: [
            { title: qsTr("Output"), rows: [
                { type: "toggle", label: qsTr("Enable video"), option: "video" },
                { type: "toggle", label: qsTr("Start videos in fullscreen"), option: "fullscreen" },
                { type: "toggle", label: qsTr("Stop the screensaver during playback"), option: "disable-screensaver" },
                { type: "toggle", label: qsTr("Play video as desktop wallpaper"), option: "video-wallpaper" } ] },
            { title: qsTr("Picture"), rows: [
                { type: "slider", label: qsTr("Hue"), option: "hue", from: -180, to: 180, step: 1, origin: 0, onChange: () => PlayerTweaks.setVideoFilter("adjust", true) },
                { type: "slider", label: qsTr("Brightness"), option: "brightness", from: 0, to: 2, step: 0.01, origin: 1, onChange: () => PlayerTweaks.setVideoFilter("adjust", true) },
                { type: "slider", label: qsTr("Contrast"), option: "contrast", from: 0, to: 2, step: 0.01, origin: 1, onChange: () => PlayerTweaks.setVideoFilter("adjust", true) },
                { type: "slider", label: qsTr("Saturation"), option: "saturation", from: 0, to: 3, step: 0.01, origin: 1, onChange: () => PlayerTweaks.setVideoFilter("adjust", true) },
                { type: "slider", label: qsTr("Gamma"), option: "gamma", from: 0.01, to: 10, step: 0.01, origin: 1, onChange: () => PlayerTweaks.setVideoFilter("adjust", true) },
                { type: "button", label: qsTr("Reset picture"), button: qsTr("Reset"), accent: true,
                  action: () => { for (const o of ["hue", "brightness", "contrast", "saturation", "gamma"]) PlayerTweaks.resetOption(o)
                                  PlayerTweaks.setVideoFilter("adjust", false) } } ] },
            { title: qsTr("Deinterlacing"), rows: [
                { type: "dropdown", label: qsTr("Deinterlacing"), option: "deinterlace" },
                { type: "dropdown", label: qsTr("Method"), option: "deinterlace-mode" } ] },
            { title: qsTr("Framing"), rows: [
                { type: "text", label: qsTr("Aspect ratio"), option: "aspect-ratio", placeholder: qsTr("Automatic") },
                { type: "text", label: qsTr("Crop"), option: "crop", placeholder: qsTr("None") },
                { type: "toggle", label: qsTr("Scale video to the window"), option: "autoscale" },
                { type: "dropdown", label: qsTr("Position in the window"), option: "align" } ] },
            { title: qsTr("Snapshots"), rows: [
                { type: "folder", label: qsTr("Save to"), option: "snapshot-path" },
                { type: "text", label: qsTr("File name prefix"), option: "snapshot-prefix" },
                { type: "dropdown", label: qsTr("Format"), option: "snapshot-format" },
                { type: "toggle", label: qsTr("Number files sequentially"), option: "snapshot-sequential" },
                { type: "toggle", label: qsTr("Show a preview after capture"), option: "snapshot-preview" } ] } ],
          advanced: [
            { title: "", rows: [
                { type: "text", label: qsTr("Custom aspect ratios"), option: "custom-aspect-ratios" },
                { type: "text", label: qsTr("Custom crop ratios"), option: "custom-crop-ratios" },
                { type: "text", label: qsTr("Monitor pixel aspect ratio"), option: "monitor-par" } ] } ] },

        { group: qsTr("Media"), name: "audio", icon: "audio", title: qsTr("Audio Defaults"), sections: [
            { title: qsTr("Output"), rows: [
                { type: "toggle", label: qsTr("Enable audio"), option: "audio" },
                { type: "dropdown", label: qsTr("Output module"), option: "aout" },
                { type: "dropdown", label: qsTr("Speaker setup"), option: "force-dolby-surround" } ] },
            { title: qsTr("Volume"), rows: [
                { type: "slider", label: qsTr("Maximum volume"), option: "qt-max-volume", from: 100, to: 300, step: 5, integer: true,
                  labels: [{ value: 100, text: "100%" }, { value: 200, text: "200%" }, { value: 300, text: "300%" }] },
                { type: "slider", label: qsTr("Startup volume"), option: "volume", from: 0, to: 2, step: 0.01,
                  labels: [{ value: 0, text: "0%" }, { value: 1, text: "100%" }, { value: 2, text: "200%" }] },
                { type: "number", label: qsTr("Volume step"), option: "volume-step", decimals: 0 } ] },
            { title: qsTr("Loudness"), rows: [
                { type: "audiofilter", label: qsTr("Normalize loudness"), module: "normvol", option: "norm-max-level" },
                { type: "number", label: qsTr("Target level"), option: "norm-max-level", decimals: 1, step: 0.5 },
                { type: "audiofilter", label: qsTr("Night mode"), module: "compressor", option: "compressor-ratio",
                  info: qsTr("Evens out loud and quiet sounds, with the compressor") },
                { type: "dropdown", label: qsTr("Replay gain"), option: "audio-replay-gain-mode" },
                { type: "number", label: qsTr("Replay gain preamp"), option: "audio-replay-gain-preamp", decimals: 1, step: 0.5, unit: " dB" } ] },
            { title: qsTr("Effects"), rows: [
                { type: "audiofilter", label: qsTr("Equalizer"), module: "equalizer", option: "equalizer-preset" },
                { type: "eq", label: qsTr("Equalizer preset"), option: "equalizer-preset" },
                { type: "toggle", label: qsTr("Two-pass"), option: "equalizer-2pass" },
                { type: "audiofilter", label: qsTr("Spatial audio"), module: "spatializer", option: "spatializer-roomsize" },
                { type: "audiofilter", label: qsTr("Headphone virtualization"), module: "headphone_channel_mixer", option: "headphone-dim" },
                { type: "audiofilter", label: qsTr("Stereo widening"), module: "stereo_widen", option: "stereowiden-delay" },
                { type: "audiofilter", label: qsTr("Compressor"), module: "compressor", option: "compressor-ratio" },
                { type: "number", label: qsTr("Pitch shift"), option: "pitch-shift", decimals: 2, step: 0.5, unit: qsTr(" semitones"),
                  info: qsTr("Applies with the pitch shifter of the player sidebar") },
                { type: "audiofilter", label: qsTr("Chorus/flanger"), module: "chorus_flanger", option: "delay-time" },
                { type: "audiofilter", label: qsTr("Karaoke"), module: "karaoke", option: "audio-filter" } ] },
            { title: qsTr("Tracks"), rows: [
                { type: "text", label: qsTr("Preferred audio language"), option: "audio-language", placeholder: qsTr("System language") },
                { type: "number", label: qsTr("Audio delay"), option: "audio-desync", unit: " ms" } ] },
            { title: qsTr("Visualization"), rows: [
                { type: "dropdown", label: qsTr("Visualizer"), option: "audio-visual" } ] } ],
          advanced: [
            { title: "", rows: [
                { type: "dropdown", label: qsTr("Pass compressed audio to the receiver"), option: "mmdevice-passthrough" },
                { type: "dropdown", label: qsTr("Resampling quality"), option: "speex-resampler-quality" },
                { type: "dropdown", label: qsTr("Media role"), option: "role" } ] } ] },

        { group: qsTr("Media"), name: "subtitles", icon: "subtitles", title: qsTr("Subtitle Defaults"), sections: [
            { title: qsTr("Tracks & Languages"), rows: [
                { type: "toggle", label: qsTr("Enable subtitles"), option: "spu" },
                { type: "text", label: qsTr("Preferred language"), option: "sub-language", placeholder: qsTr("System language") },
                { type: "dropdown", label: qsTr("Text encoding"), option: "subsdec-encoding" } ] },
            { title: qsTr("Loading Subtitles"), rows: [
                { type: "toggle", label: qsTr("Load subtitle files automatically"), option: "sub-autodetect-file" },
                { type: "dropdown", label: qsTr("File name matching"), option: "sub-autodetect-fuzzy" } ] },
            { title: qsTr("Appearance"), rows: [
                { type: "text", label: qsTr("Font"), option: "freetype-font" },
                { type: "number", label: qsTr("Font size in pixels"), option: "freetype-fontsize", unit: " px", from: 0, to: 400,
                  info: qsTr("0 makes the text follow the size of the video") },
                { type: "slider", label: qsTr("Text size"), option: "sub-text-scale", from: 25, to: 300, step: 5, integer: true,
                  labels: [{ value: 25, text: "25%" }, { value: 100, text: "100%" }, { value: 300, text: "300%" }] },
                { type: "toggle", label: qsTr("Bold"), option: "freetype-bold" },
                { type: "color", label: qsTr("Text color"), option: "freetype-color" },
                { type: "slider", label: qsTr("Text opacity"), option: "freetype-opacity", from: 0, to: 1, step: 0.01, scale: 255, integer: true, labels: root._sliderPercent },
                { type: "dropdown", label: qsTr("Outline thickness"), option: "freetype-outline-thickness" },
                { type: "color", label: qsTr("Outline color"), option: "freetype-outline-color" },
                { type: "slider", label: qsTr("Shadow"), option: "freetype-shadow-opacity", from: 0, to: 1, step: 0.01, scale: 255, integer: true, labels: root._sliderPercent },
                { type: "color", label: qsTr("Shadow color"), option: "freetype-shadow-color" },
                { type: "slider", label: qsTr("Shadow distance"), option: "freetype-shadow-distance", from: 0, to: 0.3, step: 0.01,
                  labels: [{ value: 0, text: qsTr("None") }, { value: 0.06, text: qsTr("Small") }, { value: 0.3, text: qsTr("Large") }] },
                { type: "color", label: qsTr("Background color"), option: "freetype-background-color" },
                { type: "slider", label: qsTr("Background opacity"), option: "freetype-background-opacity", from: 0, to: 1, step: 0.01, scale: 255, integer: true, labels: root._sliderPercent },
                { type: "number", label: qsTr("Distance from the bottom"), option: "sub-margin", unit: " px" } ] },
            { title: qsTr("On-Screen Messages"), rows: [
                { type: "toggle", label: qsTr("Show feedback for shortcuts"), option: "osd" },
                { type: "toggle", label: qsTr("Show the key of the shortcut"), option: "osd-show-key" },
                { type: "toggle", label: qsTr("Show filename when a video starts"), option: "video-title-show" },
                { type: "slider", label: qsTr("Show filename for"), option: "video-title-timeout", from: 1, to: 10, step: 0.5, scale: 1000, integer: true,
                  labels: [{ value: 1, text: "1 s" }, { value: 10, text: "10 s" }] } ] } ],
          advanced: [
            { title: "", rows: [
                { type: "text", label: qsTr("Load subtitles from these folders"), option: "sub-autodetect-path" },
                { type: "toggle", label: qsTr("Use the styling of the subtitles"), option: "subsdec-formatting" },
                { type: "number", label: qsTr("Shadow angle"), option: "freetype-shadow-angle", unit: "°", decimals: 0 },
                { type: "dropdown", label: qsTr("Text direction"), option: "freetype-text-direction" },
                { type: "text", label: qsTr("Monospace font"), option: "freetype-monofont" } ] } ] },

        { group: qsTr("Media"), name: "library", icon: "folder", title: qsTr("Playlists, Folders & Files"), short: qsTr("Playlists & Files"), sections: [
            { title: qsTr("Opening Files"), rows: [
                { type: "toggle", label: qsTr("Only allow one VLC window"), option: "one-instance" },
                { type: "toggle", label: qsTr("Apply to files opened from the file manager"), option: "one-instance-when-started-from-file" },
                { type: "toggle", label: qsTr("Add to the playlist instead of replacing it"), option: "playlist-enqueue" },
                { type: "dropdown", label: qsTr("When opening a folder"), option: "recursive" },
                { type: "toggle", label: qsTr("Show hidden files"), option: "show-hiddenfiles" } ] },
            { title: qsTr("Metadata & Artwork"), rows: [
                { type: "dropdown", label: qsTr("Fetch titles and artwork"), option: "metadata-network-access",
                  choices: [{ text: qsTr("From the file only"), value: false }, { text: qsTr("From the internet too"), value: true }] },
                { type: "toggle", label: qsTr("Use the media library"), option: "media-library" },
                { type: "button", label: qsTr("Library folders"), button: qsTr("Add a Folder"),
                  action: () => MainCtx.addLibraryFolder() } ] } ],
          advanced: [] },

        { group: qsTr("System"), name: "network", icon: "network", title: qsTr("Network Connections & Security"), short: qsTr("Network & Security"), sections: [
            { title: qsTr("Buffering"), rows: [
                { type: "number", label: qsTr("Local files"), option: "file-caching", unit: " ms", from: 0, to: 60000 },
                { type: "number", label: qsTr("Discs"), option: "disc-caching", unit: " ms", from: 0, to: 60000 },
                { type: "number", label: qsTr("Network streams"), option: "network-caching", unit: " ms", from: 0, to: 60000 },
                { type: "number", label: qsTr("Live capture"), option: "live-caching", unit: " ms", from: 0, to: 60000 } ] },
            { title: qsTr("Proxy"), rows: [
                { type: "text", label: qsTr("HTTP proxy"), option: "http-proxy", placeholder: qsTr("System proxy") },
                { type: "text", label: qsTr("HTTP proxy password"), option: "http-proxy-pwd", password: true } ] },
            { title: qsTr("Security"), rows: [
                { type: "toggle", label: qsTr("Verify certificates against the system trust store"), option: "gnutls-system-trust" },
                { type: "dropdown", label: qsTr("Cipher preference"), option: "gnutls-priorities" } ] } ],
          advanced: [] },

        { group: qsTr("System"), name: "performance", icon: "speed", title: qsTr("Performance Settings"), sections: [
            { title: qsTr("Decoding"), rows: [
                { type: "toggle", label: qsTr("Hardware-accelerated decoding"), option: "hw-dec" },
                { type: "dropdown", label: qsTr("Decoding device"), option: "dec-dev" },
                { type: "number", label: qsTr("Video post-processing"), option: "postproc-q", from: 0, to: 6 },
                { type: "dropdown", label: qsTr("Skip the H.264 loop filter"), option: "avcodec-skiploopfilter" },
                { type: "number", label: qsTr("Decoding threads"), option: "avcodec-threads", from: 0, to: 64,
                  info: qsTr("0 lets VLC decide") } ] },
            { title: qsTr("Smooth Playback"), rows: [
                { type: "toggle", label: qsTr("Drop frames when the system can't keep up"), option: "drop-late-frames" },
                { type: "toggle", label: qsTr("Give VLC real-time priority"), option: "rt-priority" },
                { type: "number", label: qsTr("Process priority"), option: "rt-offset" } ] } ],
          advanced: [
            { title: qsTr("Developer"), developer: true, rows: [
                { type: "dropdown", label: qsTr("Encoder"), option: "encoder" },
                { type: "dropdown", label: qsTr("Decoder"), option: "codec" },
                { type: "dropdown", label: qsTr("Clock synchronisation"), option: "clock-synchro" },
                { type: "number", label: qsTr("Clock jitter"), option: "clock-jitter", unit: " ms" } ] } ] },

        { group: qsTr("System"), name: "recording", icon: "record", title: qsTr("Recording, Casting & Streaming Out"), short: qsTr("Recording & Casting"), sections: [
            { title: qsTr("Recording"), rows: [
                { type: "folder", label: qsTr("Save recordings to"), option: "input-record-path", placeholder: "~/Videos" } ] },
            { title: qsTr("Casting"), rows: [
                { type: "dropdown", label: qsTr("Cast quality"), option: "sout-chromecast-conversion-quality" } ] },
            { title: qsTr("Streaming"), rows: [
                { type: "toggle", label: qsTr("Play locally while streaming"), option: "sout-display" },
                { type: "toggle", label: qsTr("Include audio"), option: "sout-audio" },
                { type: "toggle", label: qsTr("Include video"), option: "sout-video" },
                { type: "toggle", label: qsTr("Include subtitles"), option: "sout-spu" },
                { type: "dropdown", label: qsTr("Encoding preset"), option: "sout-x264-preset" },
                { type: "dropdown", label: qsTr("Tuning"), option: "sout-x264-tune" } ] } ],
          advanced: [] },

        { group: qsTr("System"), name: "extensions", icon: "sliders", title: qsTr("Add-ons & Scripts"), sections: [
            { title: qsTr("Add-ons"), rows: [
                { type: "button", label: qsTr("Installed add-ons and extensions"), button: qsTr("Manage"),
                  action: () => DialogsProvider.pluginDialog() },
                { type: "button", label: qsTr("Find more extensions"), button: qsTr("Browse"),
                  action: () => Qt.openUrlExternally("https://addons.videolan.org") } ] } ],
          advanced: [] }
    ]

    readonly property int _rev: PlayerTweaks.revision

    // [{ page, title, row }] matching the search
    readonly property var _results: {
        if (_search === "")
            return []
        const needle = _search.toLowerCase()
        const results = []
        for (const p of _pages)
            for (const section of p.sections.concat(p.advanced))
                for (const r of section.rows)
                    if ((r.label ?? "").toLowerCase().includes(needle))
                        results.push({ page: p, row: r })
        return results
    }

    // --- layout ------------------------------------------------------------

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // navigation
        Rectangle {
            Layout.preferredWidth: VLCStyle.dp(216, VLCStyle.scale)
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                spacing: VLCStyle.dp(8, VLCStyle.scale)

                Widgets.PanelSearchField {
                    Layout.fillWidth: true
                    onPatternChanged: root._search = pattern.trim()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root._c.raised
                    radius: VLCStyle.dp(8, VLCStyle.scale)

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                        contentHeight: navColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: navColumn

                            width: parent.width

                            Repeater {
                                model: root._pages

                                delegate: Column {
                                    required property int index
                                    required property var modelData

                                    width: navColumn.width

                                    Text {
                                        visible: index === 0 || root._pages[index - 1].group !== modelData.group
                                        leftPadding: VLCStyle.dp(10, VLCStyle.scale)
                                        topPadding: VLCStyle.dp(index === 0 ? 6 : 14, VLCStyle.scale)
                                        bottomPadding: VLCStyle.dp(6, VLCStyle.scale)
                                        text: modelData.group
                                        font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                                        color: root._c.dim
                                    }

                                    T.AbstractButton {
                                        id: navItem

                                        readonly property bool current: root._search === "" && root.page === modelData.name

                                        width: parent.width
                                        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

                                        onClicked: {
                                            root._search = ""
                                            root.page = modelData.name
                                        }

                                        background: Rectangle {
                                            radius: VLCStyle.dp(6, VLCStyle.scale)
                                            color: navItem.current ? PanelStyle.accentFill(theme.accent, (theme.palette?.isDark ?? true))
                                                                   : (navItem.hovered ? root._c.hover : "transparent")
                                        }

                                        contentItem: Row {
                                            leftPadding: VLCStyle.dp(10, VLCStyle.scale)
                                            spacing: VLCStyle.dp(10, VLCStyle.scale)

                                            Widgets.PanelIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: modelData.icon
                                                size: VLCStyle.dp(18, VLCStyle.scale)
                                                color: navItem.current ? theme.accent : root._c.label
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: navItem.width - VLCStyle.dp(48, VLCStyle.scale)
                                                // a shorter name for the long titles, which show on the page
                                                text: modelData.short ?? modelData.title
                                                elide: Text.ElideRight
                                                font.pixelSize: VLCStyle.dp(13.5, VLCStyle.scale)
                                                color: navItem.current ? root._c.bright : root._c.text
                                            }
                                        }

                                        Accessible.name: modelData.title
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // title and close
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)
                Layout.leftMargin: VLCStyle.dp(24, VLCStyle.scale)
                Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                    font.weight: Font.DemiBold
                    color: root._c.bright
                    elide: Text.ElideRight
                }

                T.AbstractButton {
                    implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
                    implicitHeight: implicitWidth
                    onClicked: root.close()

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: parent.hovered ? root._c.hover : "transparent"
                    }
                    contentItem: Widgets.PanelIcon {
                        name: "close"
                        size: VLCStyle.dp(18, VLCStyle.scale)
                        color: root._c.label
                    }
                    Accessible.name: qsTr("Close")
                }
            }

            Flickable {
                id: pageFlickable

                Layout.fillWidth: true
                Layout.fillHeight: true

                contentHeight: pageColumn.implicitHeight + VLCStyle.dp(24, VLCStyle.scale)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                T.ScrollBar.vertical: Widgets.ScrollBarExt { }

                Connections {
                    target: root
                    function onPageChanged() { pageFlickable.contentY = 0; advanced.expanded = false }
                }

                ColumnLayout {
                    id: pageColumn

                    width: pageFlickable.width - VLCStyle.dp(48, VLCStyle.scale)
                    x: VLCStyle.dp(24, VLCStyle.scale)
                    spacing: VLCStyle.dp(4, VLCStyle.scale)

                    // search results
                    Repeater {
                        model: root._results

                        delegate: ColumnLayout {
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
                                text: modelData.page.title
                                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                                color: root._c.dim
                            }

                            SettingsRow {
                                row: modelData.row
                            }
                        }
                    }

                    Text {
                        visible: root._search !== "" && root._results.length === 0
                        Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
                        text: qsTr("No setting matches \"%1\".").arg(root._search)
                        color: root._c.label
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    }

                    // the page
                    Repeater {
                        model: root._search === "" ? (root._currentPage?.sections ?? []) : []

                        delegate: SettingsSection {
                            required property var modelData
                            section: modelData
                        }
                    }

                    // advanced options, folded
                    Widgets.PanelExpander {
                        id: advanced

                        Layout.topMargin: VLCStyle.dp(12, VLCStyle.scale)
                        visible: root._search === ""
                        expandText: qsTr("Advanced Options")
                        collapseText: qsTr("Advanced Options")

                        Repeater {
                            model: (root._currentPage?.advanced ?? []).filter(
                                       (s) => !s.developer || String(PlayerTweaks.uiOption("developerMode", false)) === "true")

                            delegate: SettingsSection {
                                required property var modelData
                                section: modelData
                            }
                        }

                        Widgets.PanelButton {
                            Layout.alignment: Qt.AlignRight
                            flat: true
                            iconName: "sliders"
                            text: qsTr("All advanced preferences...")
                            onClicked: DialogsProvider.prefsDialog()
                        }
                    }
                }
            }
        }
    }

    ColorContext {
        id: theme
        colorSet: ColorContext.View
        palette: VLCStyle.palette
    }

    component SettingsSection: ColumnLayout {
        property var section

        Layout.fillWidth: true
        spacing: VLCStyle.dp(2, VLCStyle.scale)

        Text {
            visible: (section?.title ?? "") !== ""
            Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(6, VLCStyle.scale)
            text: section?.title ?? ""
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.DemiBold
            color: PanelStyle.colors(VLCStyle.palette.isDark).heading
        }

        Repeater {
            model: section?.rows ?? []

            delegate: SettingsRow {
                required property var modelData
                row: modelData
            }
        }
    }
}
