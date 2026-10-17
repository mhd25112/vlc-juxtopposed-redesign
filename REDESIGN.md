# VLC redesign, based on Juxtopposed's concept

This branch implements the VLC redesign by **Juxtopposed**, presented in her
video **[I Redesigned VLC After 25 Years](https://youtu.be/ERFeOgqk324)** and
detailed in her Figma file *VLC Redesign (Community)*, in the VLC 4 (Qt/QML)
interface.

**All credit for the design goes to [Juxtopposed](https://juxtopposed.com).**
Go watch the video: it explains the reasoning behind every screen far better
than this page.

This is an unofficial, experimental fork. It is not affiliated with or endorsed
by Juxtopposed or by VideoLAN. The screenshots below were made with generated
test media.

![Home](doc/redesign/home.png)

## The library

- A rounded navigation panel (Home, Videos, Music, Network, Playlists, Recent),
  with "Add item" (a folder, a network stream or a new playlist) and Settings at
  the bottom.
- **Home**: Continue Watching, Listen Again (title and artist), Frequently
  Visited Folders, then the newest videos and music.
- A header with back/forward, the path, the item count, sorting (including
  *Unwatched First* and *Watched First*), the grid/list switch, search, "+" and
  "...".
- **Grid** cards show the name only; what was watched is dimmed, with its
  progress as an accent line under the picture. Videos are listed by name.
- **List** view: the compact list of the design, in columns, with small
  pictures.
- **Mini player**: a card in a bottom corner with the video itself (or the
  cover), its progress (click or drag to seek, the time shows on hover), the
  file name, its folder (a click opens it in the library), and the queue under a
  button. Drag it to the other corner; double click the picture to go back to
  the player.
- **Right-click menus** in the style of the design, with its items: Play, Mark
  as Watched, Favorite, Stream, Convert, Add to Queue, Add to Playlist, Show in
  File Explorer, Go to Source, Add Subtitle Tracks, Properties & Metadata.

![Library, grid and mini player](doc/redesign/library-grid.png)
![Library, list](doc/redesign/library-list.png)
![Library menu](doc/redesign/library-menu.png)

## The player

- **Title bar**: the "..." menu (open media, recent files, profiles, keyboard
  shortcuts, Customize Player, settings), the library button, the folder of
  what plays, picture-in-picture and fullscreen.
- **Control bar**: one thin row with previous/play/next, the time as
  `00:02:10`, a thick flat seek bar, the volume cone, audio, subtitles,
  settings and queue.
- **Seek preview**: hovering the seek bar shows the frame at that time, made in
  the background by VLC's thumbnailer.
- **Settings sidebar** with Playback, Video, Audio and Subtitles tabs: speed,
  sleep timer, audio visualizer; video filters, colors, crop and zoom; the equalizer
  with its curves, compressor, spatializer, stereo widener and an audio test;
  subtitle delay, speed, size, colors, outline and saved presets.
- **Show Waveform on Seekbar**, **Show Subtitle Timeline on Seekbar** and
  **Show Metadata**: the loudness of the audio along the seek bar, marks where
  the subtitle lines are, and the format, codecs and size of what plays over the
  video.
- **Compact library** next to the video: the folder of what plays, the videos,
  music, playlists and recent files, with their pictures and progress.
- **Continue watching**: for a video left halfway, "You've watched till
  00:12:34 already." with a Continue Watching button, above the control bar.
- The right-click menu of the video, a click on the video to pause and a double
  click for fullscreen (both can be turned off in Settings), and *Hide UI*,
  which keeps only the video in the window frame.

![Player and settings sidebar](doc/redesign/player-sidebar.png)
![Waveform, subtitle timeline and metadata](doc/redesign/player-overlays.png)
![Seek preview](doc/redesign/seek-preview.png)
![Compact library](doc/redesign/player-library.png)
![Video menu](doc/redesign/player-menu.png)

## Music

A large rounded cover over a blurred copy of it, "title - artist" under it, the
skip buttons in the control bar (their icons show the configured skip length),
and the waveform of the song in the seek bar. The waveform is the real one: the
song is decoded in the background into a small mono file, faster than it plays.

![Music](doc/redesign/music.png)

## Customize Player

The control bar is arranged in place: every control gets a dashed frame and
can be dragged within the bar, between its left, middle and right groups, from
the list of controls, or onto the list to take it away. With controls in the
middle the seek bar goes on a line of its own above them. Save keeps the
arrangement in the current **profile** ("..." > Profile, with "New" to start
from a copy).

![Customize Player](doc/redesign/customize.png)

## Dialogs

- **Onboarding**: a media folder, the theme and the accent color, and the basic
  keyboard shortcuts.
- **Settings**: thirteen pages (App, Media, System) with search, the options of
  the design, advanced options folded, and the full preferences one click away.
- **Keyboard Shortcuts**: grouped, with conflicts shown and Reset All.
- **Add Subtitles**: to a file, a folder or the queue, from the computer,
  OpenSubtitles or a link, matched by name or episode number, and remembered for
  the next time the media plays.
- **Open Network Stream** (several links, saved as a playlist when named) and
  **New Playlist** (drop files or pick them).

![Settings](doc/redesign/settings.png)

## Themes

The dark and light themes of the design, with its greys, and nine accent
colors that apply everywhere at once.

![Light theme](doc/redesign/light.png)

## Where it differs from the design

- Customize Player arranges the control bar; the title bar keeps its layout.
  The list offers VLC's controls, so some items of the design that have no
  control behind them (Go Home, File Name, Favorite, Replay...) are not there.
- The subtitle timeline reads subtitle files (next to the video or chosen in
  Add Subtitles), not subtitles inside the video file.
- The waveform shows for songs; for videos it is off by default ("Show
  Waveform on Seekbar"), since it reads the whole file.
- The path in the header is the library's (Videos > All > S01), not the folders
  on the disk.
- Searching OpenSubtitles opens the site in the browser.
- Developed and tested on Windows only.

## Fixes found along the way

- Writing a stream to a file stopped at the first empty block, so converting or
  saving some media gave an empty file (`modules/access_output/file.c`).
- The volume on-screen display was never flushed (`src/player/osd.c`).
- `VLC_LIBEXEC_PATH` dropped the file name on Windows, so `vlc-preparser.exe`
  could not be started from a custom location (`src/win32/dirs-common.c`).
- The Qt plugin did not link `winmm`, needed by disc ejection, with Meson
  (`modules/gui/qt/meson.build`).

Also new outside the interface: on-screen messages caused by a keyboard
shortcut show the key (`--osd-show-key`), and the FreeType text renderer
applies font, colors, outline and a size in pixels (`--freetype-fontsize`)
while the video plays.

## Building

Build VLC as usual. This branch was developed with Meson on Windows (MSYS2
UCRT64, GCC 16, Qt 6.11). With MSYS2's shared libraries rather than VLC's
contribs:

- VLC's DirectComposition compositor needs Qt's `QRhi::implementation()`, which
  VLC adds with `contrib/src/qt/0001-Expose-QRhiImplementation-in-QRhi.patch`;
  apply the same change to the installed `rhi/qrhi.h`, and provide
  `D3D12MemAlloc.h` on the include path.
- VLC loads plugins with `LOAD_LIBRARY_SEARCH_SYSTEM32` only, so with shared
  libraries the plugins' dependencies (Qt, FFmpeg...) must be loaded before
  them, in `vlc.exe` and in `vlc-preparser.exe` (which reads files for the
  media library, the playlist and the thumbnails).

## License

Same as VLC: see [COPYING](COPYING) and [COPYING.LIB](COPYING.LIB).
