/*****************************************************************************
 * player_tweaks.hpp: settings of the player sidebar
 *****************************************************************************
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
#ifndef PLAYER_TWEAKS_HPP
#define PLAYER_TWEAKS_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QAbstractItemModel>
#include <QStringList>
#include <QUrl>
#include <QTimer>
#include <QVariant>
#include <QElapsedTimer>
#include <QHash>
#include <QSet>

#include "qt.hpp"

// Backend of the player sidebar (Playback, Video, Audio and Subtitles tabs).
//
// Audio and video options apply to the current outputs right away, like the
// "Adjustments and Effects" dialog does, and are also written to the VLC
// configuration so that the next media starts with them. Text rendering
// options are read by the text renderer for every subtitle it draws, so they
// only go to the configuration.
class PlayerTweaks : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList equalizerPresets READ equalizerPresets CONSTANT FINAL)
    Q_PROPERTY(QStringList equalizerBands READ equalizerBands CONSTANT FINAL)

    // Incremented whenever a value may have changed, bindings read it to refresh
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged FINAL)

    Q_PROPERTY(QStringList subtitlePresets READ subtitlePresets NOTIFY subtitlePresetsChanged FINAL)
    Q_PROPERTY(QString subtitlePreset READ subtitlePreset NOTIFY subtitlePresetsChanged FINAL)

    // Minutes before pausing the playback, 0 when the sleep timer is off
    Q_PROPERTY(int sleepTimer READ sleepTimer WRITE setSleepTimer NOTIFY sleepTimerChanged FINAL)
    Q_PROPERTY(int sleepTimerRemaining READ sleepTimerRemaining NOTIFY sleepTimerRemainingChanged FINAL)

    // where the media was left the last time, in ms, 0 if unknown; set while
    // the player offers to continue from there
    Q_PROPERTY(qint64 resumeTime READ resumeTime NOTIFY resumeTimeChanged FINAL)

    // The sidebar of the player and its current tab (Playback, Video, Audio, Subtitles)
    Q_PROPERTY(bool sidebarVisible READ sidebarVisible WRITE setSidebarVisible NOTIFY sidebarChanged FINAL)
    Q_PROPERTY(int sidebarPage READ sidebarPage WRITE setSidebarPage NOTIFY sidebarChanged FINAL)

public:
    explicit PlayerTweaks(qt_intf_t *intf, QObject *parent = nullptr);

    int revision() const { return m_revision; }

    // Equalizer
    QStringList equalizerPresets() const;
    QStringList equalizerBands() const;
    // band gains of a preset, -1.0 to 1.0, to draw its curve
    Q_INVOKABLE QVariantList equalizerPresetCurve(int index) const;
    // preset in use, -1 when the equalizer is off
    Q_INVOKABLE int equalizerPreset() const;
    // enable the equalizer with a preset, -1 turns it off
    Q_INVOKABLE void setEqualizerPreset(int index);
    Q_INVOKABLE QVariantList equalizerBandValues() const;
    Q_INVOKABLE void setEqualizerBand(int band, double gain);

    // Audio filters ("equalizer", "compressor"...) and their options
    Q_INVOKABLE bool audioFilter(const QString &name) const;
    Q_INVOKABLE void setAudioFilter(const QString &name, bool enabled);
    Q_INVOKABLE QVariant audioOption(const QString &name) const;
    Q_INVOKABLE void setAudioOption(const QString &name, const QVariant &value);
    // [{value, text}] of an audio output variable such as "stereo-mode" or "visual"
    Q_INVOKABLE QVariantList audioChoices(const QString &name) const;

    // Video filters ("transform", "adjust"...) and video output options
    Q_INVOKABLE bool videoFilter(const QString &name) const;
    Q_INVOKABLE void setVideoFilter(const QString &name, bool enabled);
    Q_INVOKABLE QVariant videoOption(const QString &name) const;
    Q_INVOKABLE void setVideoOption(const QString &name, const QVariant &value);
    Q_INVOKABLE QVariantList videoChoices(const QString &name) const;

    // Configuration options, such as text rendering or default languages
    Q_INVOKABLE QVariant option(const QString &name) const;
    Q_INVOKABLE void setOption(const QString &name, const QVariant &value);
    Q_INVOKABLE QVariantList optionChoices(const QString &name) const;
    // whether the option exists in this build, and VLC's help text for it
    Q_INVOKABLE bool optionExists(const QString &name) const;
    Q_INVOKABLE QString optionInfo(const QString &name) const;
    Q_INVOKABLE void resetOption(const QString &name);
    // a module named in a list option, such as "audioscrobbler" in "control"
    Q_INVOKABLE bool moduleInList(const QString &option, const QString &module) const;
    Q_INVOKABLE void setModuleInList(const QString &option, const QString &module, bool enabled);
    // back to the defaults: everything, or the keyboard shortcuts only
    Q_INVOKABLE void resetAllSettings();
    Q_INVOKABLE void resetShortcuts();
    // keyboard shortcuts of VLC: [{ group, action, option, key, globalKey }]
    Q_INVOKABLE QVariantList hotkeys() const;
    // VLC's name of a key press, such as "Ctrl+Shift+A", empty if none
    Q_INVOKABLE QString keyName(int key, int modifiers, const QString &text) const;
    // option name -> key name, for "key-..." and "global-key-..." options
    Q_INVOKABLE void setHotkeys(const QVariantMap &keys);

    // forgets what was played
    Q_INVOKABLE void clearHistory();
    // the folder of vlcrc
    Q_INVOKABLE QUrl configFolder() const;

    // "#RRGGBB" for an RGB option
    Q_INVOKABLE QString colorOption(const QString &name) const;
    Q_INVOKABLE void setColorOption(const QString &name, const QString &color);

    // Where the media plays: -1 on this computer, else a renderer (Chromecast...)
    Q_INVOKABLE QStringList renderers() const;
    Q_INVOKABLE int renderer() const;
    Q_INVOKABLE void setRenderer(int index);
    Q_INVOKABLE void scanRenderers();

    // Plays a short tone on the left, then on the right speaker, with the
    // stereo mode of the player
    Q_INVOKABLE void testStereo();

    // Media and folders in a local folder, for the compact library:
    // [{ name, url, isDir, isVideo }], folders first
    Q_INVOKABLE QVariantList folderItems(const QUrl &folder) const;
    // the folder of a local media, empty otherwise
    Q_INVOKABLE QUrl parentFolder(const QUrl &media) const;

    // entries of a list model with a check state (tracks, devices, aspect
    // ratios...): [{ text, checked }], and selecting one of them
    Q_INVOKABLE QVariantList modelEntries(QAbstractItemModel *model) const;
    Q_INVOKABLE void checkModelEntry(QAbstractItemModel *model, int row);

    // Subtitles for the Add Subtitles dialog
    // subtitle files of a local folder and its "Subs" folders: [{ name, url }]
    Q_INVOKABLE QVariantList subtitleFiles(const QUrl &folder) const;
    // what the queue holds: [{ name, url }]
    Q_INVOKABLE QVariantList queueItems() const;
    // remembers a subtitle for a media, loaded whenever the media plays (and
    // right away if it plays now); an empty subtitle forgets it
    Q_INVOKABLE void setSubtitleFor(const QUrl &media, const QUrl &subtitle);
    Q_INVOKABLE QUrl subtitleFor(const QUrl &media) const;

    // creates a playlist of the library with these files or streams (local
    // files are added to the library as external media, URLs as streams),
    // and plays them if asked
    Q_INVOKABLE void createPlaylist(const QString &name, const QVariantList &urls, bool play);
    // the library's folder of a file, or this folder: answered with folderLocated()
    Q_INVOKABLE void locateFolder(const QUrl &url, bool isFolder = false);

    // Native pickers for the redesigned dialogs, empty when cancelled
    Q_INVOKABLE QUrl chooseFolder(const QString &title) const;
    Q_INVOKABLE QList<QUrl> chooseFiles(const QString &title, const QString &filter) const;

    // Asks the main interface to show one of the redesigned dialogs:
    // "settings", "shortcuts", "customize", "onboarding", "subtitles"...
    Q_INVOKABLE void requestDialog(const QString &name, const QVariant &argument = {})
    { emit dialogRequested(name, argument); }

    // Settings of the interface itself, such as what the seek bar shows
    Q_INVOKABLE QVariant uiOption(const QString &name, const QVariant &defaultValue = {}) const;
    Q_INVOKABLE void setUiOption(const QString &name, const QVariant &value);

    // Subtitle presets: timing and look, saved under a name to reuse them
    QStringList subtitlePresets() const;
    QString subtitlePreset() const { return m_subtitlePreset; }
    Q_INVOKABLE void saveSubtitlePreset(const QString &name);
    Q_INVOKABLE void applySubtitlePreset(const QString &name);
    Q_INVOKABLE void removeSubtitlePreset(const QString &name);
    // back to the default timing and look
    Q_INVOKABLE void resetSubtitlePreset();

    int sleepTimer() const { return m_sleepMinutes; }
    void setSleepTimer(int minutes);
    int sleepTimerRemaining() const;

    qint64 resumeTime() const { return m_resumeTime; }

    bool sidebarVisible() const { return m_sidebarVisible; }
    void setSidebarVisible(bool visible);
    int sidebarPage() const { return m_sidebarPage; }
    void setSidebarPage(int page);
    // show the sidebar on a tab, or hide it when it already shows that tab
    Q_INVOKABLE void toggleSidebar(int page);

    // the loudness of a song along its length (values from 0 to 1), for the
    // seek bar: read in the background by decoding the file, see waveform
    Q_PROPERTY(QVariantList waveform READ waveform NOTIFY waveformChanged FINAL)
    QVariantList waveform() const { return m_waveform; }
    Q_INVOKABLE void loadWaveform(const QUrl &url);

    // what the media library knows of files (by url): their "thumbnail" and
    // "progress", asked with requestMediaInfo()
    Q_PROPERTY(QVariantMap mediaInfo READ mediaInfo NOTIFY mediaInfoChanged FINAL)
    QVariantMap mediaInfo() const { return m_mediaInfo; }
    Q_INVOKABLE void requestMediaInfo(const QVariantList &urls);

    // a picture of a video at a position, shown over the seek bar: asked
    // with requestSeekPreview(), seekPreview is its file once made and
    // seekPreviewPosition the position it is of
    Q_PROPERTY(QUrl seekPreview READ seekPreview NOTIFY seekPreviewChanged FINAL)
    Q_PROPERTY(double seekPreviewPosition READ seekPreviewPosition NOTIFY seekPreviewChanged FINAL)
    QUrl seekPreview() const { return m_seekPreview; }
    double seekPreviewPosition() const { return m_seekPreviewPosition; }
    Q_INVOKABLE void requestSeekPreview(const QUrl &media, double position);

    // "Show Subtitle Timeline on Seekbar": the start and end (in seconds,
    // one after the other) of the lines of the subtitle file of a media:
    // the one chosen for it, or the one next to it with its name
    Q_INVOKABLE QVariantList subtitleCues(const QUrl &media) const;

    // "Show Metadata": what plays, in words (title, video, audio, size)
    Q_INVOKABLE QVariantMap mediaDetails() const;
    // from the thumbnailer, see startSeekPreview()
    void seekPreviewDone(const QString &key, const QString &file, double position);

    // the player's controls being arranged ("Customize Player")
    Q_PROPERTY(bool customizing READ customizing WRITE setCustomizing NOTIFY customizingChanged FINAL)
    bool customizing() const { return m_customizing; }
    void setCustomizing(bool customizing)
    {
        if (customizing == m_customizing)
            return;
        m_customizing = customizing;
        emit customizingChanged();
    }

signals:
    void revisionChanged();
    void subtitlePresetsChanged();
    void sleepTimerChanged();
    void sleepTimerRemainingChanged();
    void sidebarChanged();
    void resumeTimeChanged();
    void dialogRequested(const QString &name, const QVariant &argument);
    void folderLocated(const QVariant &parentId, const QString &title);
    void waveformChanged();
    void customizingChanged();
    void mediaInfoChanged();
    void seekPreviewChanged();

public:
    ~PlayerTweaks() override;

private:
    void startWaveform(const QUrl &url);
    void startSeekPreview();
    void finishWaveform();
    void touch();
    void scheduleSave();
    void updateResumeTime();
    void loadRememberedSubtitle();

    qt_intf_t *p_intf;
    int m_revision = 0;
    QString m_subtitlePreset;

    int m_sleepMinutes = 0;
    QTimer m_sleepTimer;
    QTimer m_sleepTick;
    QElapsedTimer m_sleepClock;

    QTimer m_saveTimer;

    vlc_player_t *m_testPlayer = nullptr;
    qint64 m_resumeTime = 0;

    bool m_sidebarVisible = false;
    int m_sidebarPage = 0;

    // waveform: the player decoding the song into m_waveFile
    vlc_player_t *m_wavePlayer = nullptr;
    QTimer m_waveTimer;
    QElapsedTimer m_waveClock;
    QString m_waveFile;
    QUrl m_waveUrl;
    QUrl m_wantedWaveUrl;
    QHash<QString, QVariantList> m_waveCache;
    // the files tried again after reading nothing (at startup, see finishWaveform)
    QSet<QString> m_waveRetried;
    QVariantList m_waveform;

    bool m_customizing = false;

    QVariantMap m_mediaInfo;

    // seek preview: the thumbnailer, what is wanted, the pictures made
    struct vlc_preparser_t *m_previewParser = nullptr;
    bool m_previewBusy = false;
    QUrl m_previewMedia;
    int m_previewBucket = -1;
    QHash<QString, QString> m_previewFiles;
    QUrl m_seekPreview;
    double m_seekPreviewPosition = -1.;
};

#endif // PLAYER_TWEAKS_HPP
