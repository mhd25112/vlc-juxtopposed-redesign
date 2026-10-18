/*****************************************************************************
 * player_tweaks.cpp: settings of the player sidebar
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
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "player_tweaks.hpp"

#include <QColor>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QFileDialog>
#include <QKeyEvent>
#include <QLocale>
#include <QMap>
#include <QSettings>
#include <QtEndian>

#include <algorithm>
#include <cmath>

#include <vlc_common.h>
#include <vlc_aout.h>
#include <vlc_fourcc.h>
#include <vlc_vout.h>
#include <vlc_modules.h>
#include <vlc_plugin.h>
#include <vlc_player.h>
#include <vlc_input_item.h>
#include <vlc_url.h>
#include <vlc_media_library.h>
#include <vlc_actions.h>
#include <vlc_interface.h>
#include <vlc_playlist.h>
#include <vlc_preparser.h>

#include "player/player_controller.hpp"
#include "playlist/playlist_controller.hpp"
#include "util/renderer_manager.hpp"
#include "maininterface/mainctx.hpp"
#include "medialibrary/medialib.hpp"
#include "medialibrary/mlqmltypes.hpp"
#include "util/vlchotkeyconverter.hpp"
#include "../../../audio_filter/equalizer_presets.h"

namespace {

constexpr QLatin1String SETTINGS_PRESETS {"SubtitlePresets"};
constexpr QLatin1String SETTINGS_CURRENT_PRESET {"SubtitlePresetCurrent"};
constexpr QLatin1String PRESET_DELAY {"delay"};
constexpr QLatin1String SETTINGS_UI {"Redesign"};

// What a subtitle preset remembers, besides the subtitle delay
const char *const subtitlePresetOptions[] = {
    "sub-text-scale", "sub-margin", "freetype-font", "freetype-bold", "freetype-fontsize",
    "freetype-color", "freetype-opacity",
    "freetype-outline-color", "freetype-outline-thickness",
    "freetype-background-color", "freetype-background-opacity",
};

QVariant variantFromVariable(vlc_object_t *obj, const char *name)
{
    switch (var_Type(obj, name) & VLC_VAR_CLASS)
    {
    case VLC_VAR_BOOL:
        return var_GetBool(obj, name);
    case VLC_VAR_INTEGER:
        return QVariant::fromValue<qlonglong>(var_GetInteger(obj, name));
    case VLC_VAR_FLOAT:
        return var_GetFloat(obj, name);
    case VLC_VAR_STRING:
    {
        char *str = var_GetString(obj, name);
        QString value = qfu(str);
        free(str);
        return value;
    }
    default:
        return {};
    }
}

void setVariable(vlc_object_t *obj, const char *name, const QVariant &value)
{
    switch (var_Type(obj, name) & VLC_VAR_CLASS)
    {
    case VLC_VAR_BOOL:
        var_SetBool(obj, name, value.toBool());
        break;
    case VLC_VAR_INTEGER:
        var_SetInteger(obj, name, value.toLongLong());
        break;
    case VLC_VAR_FLOAT:
        var_SetFloat(obj, name, value.toFloat());
        break;
    case VLC_VAR_STRING:
        var_SetString(obj, name, qtu(value.toString()));
        break;
    default:
        break;
    }
}

QVariant variantFromConfig(const char *name)
{
    const module_config_t *item = config_FindConfig(name);
    if (!item)
        return {};

    switch (CONFIG_CLASS(item->i_type))
    {
    case CONFIG_ITEM_BOOL:
        return config_GetInt(name) != 0;
    case CONFIG_ITEM_INTEGER:
        return QVariant::fromValue<qlonglong>(config_GetInt(name));
    case CONFIG_ITEM_FLOAT:
        return config_GetFloat(name);
    case CONFIG_ITEM_STRING:
    {
        char *str = config_GetPsz(name);
        QString value = qfu(str);
        free(str);
        return value;
    }
    default:
        return {};
    }
}

void putConfig(const char *name, const QVariant &value)
{
    const module_config_t *item = config_FindConfig(name);
    if (!item)
        return;

    switch (CONFIG_CLASS(item->i_type))
    {
    case CONFIG_ITEM_BOOL:
        config_PutInt(name, value.toBool() ? 1 : 0);
        break;
    case CONFIG_ITEM_INTEGER:
        config_PutInt(name, value.toLongLong());
        break;
    case CONFIG_ITEM_FLOAT:
        config_PutFloat(name, value.toFloat());
        break;
    case CONFIG_ITEM_STRING:
        config_PutPsz(name, qtu(value.toString()));
        break;
    default:
        break;
    }
}

QVariantList variableChoices(vlc_object_t *obj, const char *name)
{
    QVariantList choices;
    const int type = var_Type(obj, name) & VLC_VAR_CLASS;
    if (type != VLC_VAR_INTEGER && type != VLC_VAR_STRING)
        return choices;

    size_t count = 0;
    vlc_value_t *values = nullptr;
    char **texts = nullptr;
    if (var_Change(obj, name, VLC_VAR_GETCHOICES, &count, &values, &texts) != VLC_SUCCESS)
        return choices;

    for (size_t i = 0; i < count; ++i)
    {
        QVariantMap choice;
        if (type == VLC_VAR_INTEGER)
            choice[QStringLiteral("value")] = QVariant::fromValue<qlonglong>(values[i].i_int);
        else
        {
            choice[QStringLiteral("value")] = qfu(values[i].psz_string);
            free(values[i].psz_string);
        }
        choice[QStringLiteral("text")] = qfu(texts[i] ? texts[i] : "");
        free(texts[i]);
        choices.append(choice);
    }
    free(texts);
    free(values);
    return choices;
}

QStringList filterChain(const QString &chain)
{
    return chain.split(QLatin1Char(':'), Qt::SkipEmptyParts);
}

// Which filter chain a video filter module belongs to
const char *videoFilterType(const char *name)
{
    module_t *module = module_find(name);
    if (!module)
        return nullptr;
    if (module_provides(module, "video splitter"))
        return "video-splitter";
    if (module_provides(module, "video filter"))
        return "video-filter";
    if (module_provides(module, "sub source"))
        return "sub-source";
    if (module_provides(module, "sub filter"))
        return "sub-filter";
    return nullptr;
}

} // namespace

PlayerTweaks::PlayerTweaks(qt_intf_t *intf, QObject *parent)
    : QObject(parent)
    , p_intf(intf)
{
    m_waveTimer.setInterval(200);
    connect(&m_waveTimer, &QTimer::timeout, this, [this]() {
        if (!m_wavePlayer)
            return;
        vlc_player_Lock(m_wavePlayer);
        // ended, or could not read the file (it may then stay "started")
        const bool stopped = vlc_player_GetState(m_wavePlayer) == VLC_PLAYER_STATE_STOPPED
                             || vlc_player_GetError(m_wavePlayer) != VLC_PLAYER_ERROR_NONE;
        vlc_player_Unlock(m_wavePlayer);
        // a bit later than the start, the player is still stopped then;
        // and not forever, for a file that would not end
        if ((stopped && m_waveClock.elapsed() > 500) || m_waveClock.elapsed() > 120000)
            finishWaveform();
    });
    m_sleepTimer.setSingleShot(true);
    connect(&m_sleepTimer, &QTimer::timeout, this, [this]() {
        p_intf->p_mainPlaylistController->pause();
        setSleepTimer(0);
    });

    m_sleepTick.setInterval(1000);
    connect(&m_sleepTick, &QTimer::timeout, this, &PlayerTweaks::sleepTimerRemainingChanged);

    // Do not write the configuration file for every step of a slider
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(1500);
    connect(&m_saveTimer, &QTimer::timeout, this, [this]() {
        config_SaveConfigFile(p_intf);
    });

    // Outputs come and go with the media, values may change with them
    connect(THEMIM, &PlayerController::inputChanged, this, &PlayerTweaks::touch);
    connect(THEMIM, &PlayerController::hasVideoOutputChanged, this, &PlayerTweaks::touch);

    connect(THEMIM, &PlayerController::playbackRestoreQueried, this, &PlayerTweaks::updateResumeTime);
    connect(THEMIM, &PlayerController::inputChanged, this, &PlayerTweaks::loadRememberedSubtitle);
    connect(THEMIM, &PlayerController::inputChanged, this, &PlayerTweaks::updateCurrentMedia);

    RendererManager *renderers = THEMIM->getRendererManager();
    connect(renderers, &QAbstractItemModel::rowsInserted, this, &PlayerTweaks::touch);
    connect(renderers, &QAbstractItemModel::rowsRemoved, this, &PlayerTweaks::touch);
    connect(renderers, &QAbstractItemModel::modelReset, this, &PlayerTweaks::touch);
    connect(renderers, &RendererManager::useRendererChanged, this, &PlayerTweaks::touch);

    QSettings *settings = getSettings();
    m_subtitlePreset = settings->value(SETTINGS_CURRENT_PRESET).toString();
}

void PlayerTweaks::touch()
{
    ++m_revision;
    emit revisionChanged();
}

void PlayerTweaks::scheduleSave()
{
    m_saveTimer.start();
}

/* Equalizer */

QStringList PlayerTweaks::equalizerPresets() const
{
    QStringList names;
    for (const char *text : preset_list_text)
        names.append(qfut(text));
    return names;
}

QStringList PlayerTweaks::equalizerBands() const
{
    const bool vlcBands = var_InheritBool(p_intf, "equalizer-vlcfreqs");
    const float *freqs = vlcBands ? f_vlc_frequency_table_10b : f_iso_frequency_table_10b;

    QStringList bands;
    for (int i = 0; i < EQZ_BANDS_MAX; ++i)
    {
        if (freqs[i] >= 1000)
            bands.append(qtr("%1 kHz").arg(freqs[i] / 1000, 0, 'g', 3));
        else
            bands.append(qtr("%1 Hz").arg(freqs[i], 0, 'g', 3));
    }
    return bands;
}

QVariantList PlayerTweaks::equalizerPresetCurve(int index) const
{
    QVariantList curve;
    if (index < 0 || index >= NB_PRESETS)
        return curve;
    for (int i = 0; i < EQZ_BANDS_MAX; ++i)
        curve.append(qBound(-1.0, eqz_preset_10b[index].f_amp[i] / 12.0, 1.0));
    return curve;
}

int PlayerTweaks::equalizerPreset() const
{
    if (!audioFilter(QStringLiteral("equalizer")))
        return -1;

    const QString preset = audioOption(QStringLiteral("equalizer-preset")).toString();
    for (int i = 0; i < NB_PRESETS; ++i)
        if (preset == QLatin1String(preset_list[i]))
            return i;
    return -1;
}

void PlayerTweaks::setEqualizerPreset(int index)
{
    if (index < 0 || index >= NB_PRESETS)
    {
        setAudioFilter(QStringLiteral("equalizer"), false);
        return;
    }

    // Keep the bands in the configuration in sync with the preset, the
    // equalizer applies the preset itself when it is running
    QStringList bands;
    for (int i = 0; i < EQZ_BANDS_MAX; ++i)
        bands.append(QString::number(eqz_preset_10b[index].f_amp[i], 'f', 1));
    setAudioOption(QStringLiteral("equalizer-bands"), bands.join(QLatin1Char(' ')));
    setAudioOption(QStringLiteral("equalizer-preamp"), eqz_preset_10b[index].f_preamp);
    setAudioOption(QStringLiteral("equalizer-preset"), QString::fromLatin1(preset_list[index]));
    setAudioFilter(QStringLiteral("equalizer"), true);
}

QVariantList PlayerTweaks::equalizerBandValues() const
{
    QVariantList values;
    const QStringList bands = audioOption(QStringLiteral("equalizer-bands")).toString()
                                  .split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (int i = 0; i < EQZ_BANDS_MAX; ++i)
        values.append(i < bands.size() ? bands[i].toDouble() : 0.0);
    return values;
}

void PlayerTweaks::setEqualizerBand(int band, double gain)
{
    if (band < 0 || band >= EQZ_BANDS_MAX)
        return;

    QVariantList values = equalizerBandValues();
    values[band] = qBound(-20.0, gain, 20.0);

    QStringList bands;
    for (const QVariant &value : values)
        bands.append(QString::number(value.toDouble(), 'f', 1));
    setAudioOption(QStringLiteral("equalizer-bands"), bands.join(QLatin1Char(' ')));
}

/* Audio */

bool PlayerTweaks::audioFilter(const QString &name) const
{
    QString chain;
    if (SharedAOut aout = THEMIM->getAout())
    {
        char *str = var_GetNonEmptyString(aout.get(), "audio-filter");
        chain = qfu(str);
        free(str);
    }
    else
        chain = variantFromConfig("audio-filter").toString();

    return filterChain(chain).contains(name);
}

void PlayerTweaks::setAudioFilter(const QString &name, bool enabled)
{
    if (audioFilter(name) == enabled)
        return;

    if (!module_find(qtu(name)))
    {
        msg_Err(p_intf, "Unable to find filter module \"%s\".", qtu(name));
        return;
    }

    vlc_player_aout_EnableFilter(p_intf->p_player, qtu(name), enabled);

    // Remember it for the next media
    QStringList chain = filterChain(variantFromConfig("audio-filter").toString());
    chain.removeAll(name);
    if (enabled)
        chain.append(name);
    config_PutPsz("audio-filter", qtu(chain.join(QLatin1Char(':'))));
    scheduleSave();
    touch();
}

QVariant PlayerTweaks::audioOption(const QString &name) const
{
    if (SharedAOut aout = THEMIM->getAout())
        if (var_Type(aout.get(), qtu(name)) != 0)
            return variantFromVariable(VLC_OBJECT(aout.get()), qtu(name));
    return variantFromConfig(qtu(name));
}

void PlayerTweaks::setAudioOption(const QString &name, const QVariant &value)
{
    if (SharedAOut aout = THEMIM->getAout())
        setVariable(VLC_OBJECT(aout.get()), qtu(name), value);
    putConfig(qtu(name), value);
    scheduleSave();
    touch();
}

QVariantList PlayerTweaks::audioChoices(const QString &name) const
{
    if (SharedAOut aout = THEMIM->getAout())
        return variableChoices(VLC_OBJECT(aout.get()), qtu(name));
    return {};
}

/* Video */

bool PlayerTweaks::videoFilter(const QString &name) const
{
    const char *type = videoFilterType(qtu(name));
    if (!type)
        return false;

    QString chain;
    if (SharedVOutThread vout = THEMIM->getVout())
    {
        char *str = var_GetString(vout.get(), type);
        chain = qfu(str);
        free(str);
    }
    else
        chain = variantFromConfig(type).toString();

    return filterChain(chain).contains(name);
}

void PlayerTweaks::setVideoFilter(const QString &name, bool enabled)
{
    const char *type = videoFilterType(qtu(name));
    if (!type)
    {
        msg_Err(p_intf, "Unable to find video filter module \"%s\".", qtu(name));
        return;
    }

    changeVideoFilterChain(type, enabled ? QStringList{ name } : QStringList{},
                           enabled ? QStringList{} : QStringList{ name });
    scheduleSave();
    touch();
}

void PlayerTweaks::setVideoFilters(const QStringList &enable, const QStringList &disable)
{
    // by kind of filter ("video-filter", "sub-source"...)
    QMap<QByteArray, std::pair<QStringList, QStringList>> changes;
    for (const QString &name : enable)
        if (const char *type = videoFilterType(qtu(name)))
            changes[type].first.append(name);
    for (const QString &name : disable)
        if (const char *type = videoFilterType(qtu(name)))
            changes[type].second.append(name);

    for (auto it = changes.cbegin(); it != changes.cend(); ++it)
        changeVideoFilterChain(it.key().constData(), it.value().first, it.value().second);
    scheduleSave();
    touch();
}

void PlayerTweaks::changeVideoFilterChain(const char *type, const QStringList &enable,
                                          const QStringList &disable)
{
    QString current;
    if (SharedVOutThread vout = THEMIM->getVout())
    {
        char *str = var_GetString(vout.get(), type);
        current = qfu(str);
        free(str);
    }
    else
        current = variantFromConfig(type).toString();

    QStringList chain = filterChain(current);
    for (const QString &name : disable)
        chain.removeAll(name);
    for (const QString &name : enable)
    {
        chain.removeAll(name);
        chain.append(name);
    }
    const QString result = chain.join(QLatin1Char(':'));

    // Splitters can not change on the fly, they apply to the next video; the
    // chain is not rebuilt when it stays the same
    if (strcmp(type, "video-splitter") && result != current)
        for (const SharedVOutThread &vout : THEMIM->getVouts())
            var_SetString(vout.get(), type, qtu(result));

    config_PutPsz(type, qtu(result));
}

QVariant PlayerTweaks::videoOption(const QString &name) const
{
    if (SharedVOutThread vout = THEMIM->getVout())
        if (var_Type(vout.get(), qtu(name)) != 0)
            return variantFromVariable(VLC_OBJECT(vout.get()), qtu(name));
    return variantFromConfig(qtu(name));
}

void PlayerTweaks::setVideoOption(const QString &name, const QVariant &value)
{
    for (const SharedVOutThread &vout : THEMIM->getVouts())
        if (var_Type(vout.get(), qtu(name)) != 0)
            setVariable(VLC_OBJECT(vout.get()), qtu(name), value);
    putConfig(qtu(name), value);
    scheduleSave();
    touch();
}

QVariantList PlayerTweaks::videoChoices(const QString &name) const
{
    if (SharedVOutThread vout = THEMIM->getVout())
        return variableChoices(VLC_OBJECT(vout.get()), qtu(name));
    return {};
}

/* Configuration */

QVariant PlayerTweaks::option(const QString &name) const
{
    return variantFromConfig(qtu(name));
}

void PlayerTweaks::setOption(const QString &name, const QVariant &value)
{
    putConfig(qtu(name), value);
    scheduleSave();
    touch();
}

QVariantList PlayerTweaks::optionChoices(const QString &name) const
{
    QVariantList choices;
    const module_config_t *item = config_FindConfig(qtu(name));
    if (!item)
        return choices;

    if (CONFIG_CLASS(item->i_type) == CONFIG_ITEM_INTEGER)
    {
        int64_t *values = nullptr;
        char **texts = nullptr;
        const ssize_t count = config_GetIntChoices(qtu(name), &values, &texts);
        for (ssize_t i = 0; i < count; ++i)
        {
            choices.append(QVariantMap {
                { QStringLiteral("value"), QVariant::fromValue<qlonglong>(values[i]) },
                { QStringLiteral("text"), qfut(texts[i]) },
            });
            free(texts[i]);
        }
        free(values);
        free(texts);
    }
    else if (CONFIG_CLASS(item->i_type) == CONFIG_ITEM_STRING)
    {
        char **values = nullptr;
        char **texts = nullptr;
        const ssize_t count = config_GetPszChoices(qtu(name), &values, &texts);
        for (ssize_t i = 0; i < count; ++i)
        {
            choices.append(QVariantMap {
                { QStringLiteral("value"), qfu(values[i]) },
                { QStringLiteral("text"), qfut(texts[i]) },
            });
            free(values[i]);
            free(texts[i]);
        }
        free(values);
        free(texts);
    }
    return choices;
}

bool PlayerTweaks::optionExists(const QString &name) const
{
    // removed options are still known, without any description
    const module_config_t *item = config_FindConfig(qtu(name));
    return item != nullptr && item->psz_text != nullptr;
}

QString PlayerTweaks::optionInfo(const QString &name) const
{
    const module_config_t *item = config_FindConfig(qtu(name));
    if (!item)
        return {};
    if (item->psz_longtext && *item->psz_longtext)
        return qfut(item->psz_longtext);
    if (item->psz_text)
        return qfut(item->psz_text);
    return {};
}

void PlayerTweaks::resetOption(const QString &name)
{
    const module_config_t *item = config_FindConfig(qtu(name));
    if (!item)
        return;
    switch (CONFIG_CLASS(item->i_type))
    {
    case CONFIG_ITEM_BOOL:
    case CONFIG_ITEM_INTEGER:
        config_PutInt(qtu(name), item->orig.i);
        break;
    case CONFIG_ITEM_FLOAT:
        config_PutFloat(qtu(name), item->orig.f);
        break;
    case CONFIG_ITEM_STRING:
        config_PutPsz(qtu(name), item->orig.psz);
        break;
    default:
        return;
    }
    scheduleSave();
    touch();
}

bool PlayerTweaks::moduleInList(const QString &option, const QString &module) const
{
    return filterChain(variantFromConfig(qtu(option)).toString()).contains(module);
}

void PlayerTweaks::setModuleInList(const QString &option, const QString &module, bool enabled)
{
    QStringList list = filterChain(variantFromConfig(qtu(option)).toString());
    list.removeAll(module);
    if (enabled)
        list.append(module);
    config_PutPsz(qtu(option), qtu(list.join(QLatin1Char(':'))));
    scheduleSave();
    touch();
}

void PlayerTweaks::resetAllSettings()
{
    config_ResetAll();
    config_SaveConfigFile(p_intf);
    touch();
}

void PlayerTweaks::resetShortcuts()
{
    size_t count = 0;
    module_t **modules = module_list_get(&count);
    for (size_t i = 0; i < count; ++i)
    {
        unsigned confsize = 0;
        module_config_t *config = module_config_get(modules[i], &confsize);
        for (unsigned j = 0; j < confsize; ++j)
        {
            const module_config_t &item = config[j];
            if (CONFIG_CLASS(item.i_type) != CONFIG_ITEM_STRING || !item.psz_name)
                continue;
            if (strncmp(item.psz_name, "key-", 4) && strncmp(item.psz_name, "global-key-", 11))
                continue;
            config_PutPsz(item.psz_name, item.orig.psz);
        }
        module_config_free(config);
    }
    module_list_free(modules);
    scheduleSave();
    touch();
}

QVariantList PlayerTweaks::hotkeys() const
{
    QVariantList list;
    module_t *core = module_get_main();
    unsigned count = 0;
    module_config_t *config = module_config_get(core, &count);

    QString group;
    for (unsigned i = 0; i < count; ++i)
    {
        const module_config_t &item = config[i];
        if (item.i_type == CONFIG_SECTION)
        {
            group = qfut(item.psz_text);
            continue;
        }
        if (item.i_type != CONFIG_ITEM_KEY || !item.psz_name || !item.psz_text)
            continue;
        if (strncmp(item.psz_name, "key-", 4))
            continue;

        char *key = config_GetPsz(item.psz_name);
        const QString global = QStringLiteral("global-") + qfu(item.psz_name);
        char *globalKey = config_FindConfig(qtu(global)) ? config_GetPsz(qtu(global)) : nullptr;

        list.append(QVariantMap {
            { QStringLiteral("group"), group },
            { QStringLiteral("action"), qfut(item.psz_text) },
            { QStringLiteral("option"), qfu(item.psz_name) },
            { QStringLiteral("key"), qfu(key) },
            { QStringLiteral("globalKey"), qfu(globalKey) },
        });
        free(key);
        free(globalKey);
    }
    module_config_free(config);
    return list;
}

QString PlayerTweaks::keyName(int key, int modifiers, const QString &text) const
{
    switch (key)
    {
    case Qt::Key_Control:
    case Qt::Key_Shift:
    case Qt::Key_Alt:
    case Qt::Key_Meta:
    case Qt::Key_AltGr:
        return {};
    default:
        break;
    }
    QKeyEvent event(QEvent::KeyPress, key, Qt::KeyboardModifiers(modifiers), text);
    const int vlcKey = qtEventToVLCKey(&event);
    if (vlcKey == KEY_UNSET)
        return {};
    return VLCKeyToString(vlcKey, false);
}

void PlayerTweaks::setHotkeys(const QVariantMap &keys)
{
    for (auto it = keys.cbegin(); it != keys.cend(); ++it)
    {
        if (!it.key().startsWith(QLatin1String("key-")) && !it.key().startsWith(QLatin1String("global-key-")))
            continue;
        config_PutPsz(qtu(it.key()), qtu(it.value().toString()));
    }
    config_SaveConfigFile(p_intf);
    touch();
}

void PlayerTweaks::clearHistory()
{
    if (!p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;
    p_intf->p_mi->getMediaLibrary()->runOnMLThread(this,
    //ML thread
    [](vlc_medialibrary_t* ml){
        vlc_ml_clear_history(ml, VLC_ML_HISTORY_TYPE_GLOBAL);
    });
}

QUrl PlayerTweaks::configFolder() const
{
    char *dir = config_GetUserDir(VLC_CONFIG_DIR);
    const QUrl url = QUrl::fromLocalFile(qfu(dir));
    free(dir);
    return url;
}

QString PlayerTweaks::colorOption(const QString &name) const
{
    const qlonglong rgb = option(name).toLongLong();
    return QColor::fromRgb(QRgb(rgb & 0xFFFFFF)).name();
}

void PlayerTweaks::setColorOption(const QString &name, const QString &color)
{
    const QColor value(color);
    if (!value.isValid())
        return;
    setOption(name, QVariant::fromValue<qlonglong>(value.rgb() & 0xFFFFFF));
}

/* Subtitle presets */

QStringList PlayerTweaks::subtitlePresets() const
{
    QSettings *settings = getSettings();
    settings->beginGroup(SETTINGS_PRESETS);
    QStringList presets = settings->childGroups();
    settings->endGroup();
    return presets;
}

void PlayerTweaks::saveSubtitlePreset(const QString &name)
{
    const QString preset = name.trimmed();
    if (preset.isEmpty())
        return;

    QSettings *settings = getSettings();
    settings->beginGroup(SETTINGS_PRESETS);
    settings->beginGroup(preset);
    for (const char *key : subtitlePresetOptions)
        settings->setValue(QLatin1String(key), option(QLatin1String(key)));
    settings->setValue(PRESET_DELAY, THEMIM->getSubtitleDelayMS());
    settings->endGroup();
    settings->endGroup();

    m_subtitlePreset = preset;
    settings->setValue(SETTINGS_CURRENT_PRESET, m_subtitlePreset);
    emit subtitlePresetsChanged();
}

void PlayerTweaks::applySubtitlePreset(const QString &name)
{
    QSettings *settings = getSettings();
    settings->beginGroup(SETTINGS_PRESETS);
    if (!settings->childGroups().contains(name))
    {
        settings->endGroup();
        return;
    }

    settings->beginGroup(name);
    for (const char *key : subtitlePresetOptions)
    {
        const QVariant value = settings->value(QLatin1String(key));
        if (value.isValid())
            putConfig(key, value);
    }
    const QVariant delay = settings->value(PRESET_DELAY);
    settings->endGroup();
    settings->endGroup();

    if (delay.isValid())
        THEMIM->setSubtitleDelayMS(delay.toInt());

    for (const SharedVOutThread &vout : THEMIM->getVouts())
    {
        var_SetInteger(vout.get(), "sub-text-scale", config_GetInt("sub-text-scale"));
        var_SetInteger(vout.get(), "sub-margin", config_GetInt("sub-margin"));
    }

    m_subtitlePreset = name;
    settings->setValue(SETTINGS_CURRENT_PRESET, m_subtitlePreset);
    scheduleSave();
    emit subtitlePresetsChanged();
    touch();
}

void PlayerTweaks::removeSubtitlePreset(const QString &name)
{
    QSettings *settings = getSettings();
    settings->beginGroup(SETTINGS_PRESETS);
    settings->remove(name);
    settings->endGroup();

    if (m_subtitlePreset == name)
    {
        m_subtitlePreset.clear();
        settings->remove(SETTINGS_CURRENT_PRESET);
    }
    emit subtitlePresetsChanged();
}

void PlayerTweaks::resetSubtitlePreset()
{
    for (const char *key : subtitlePresetOptions)
    {
        const module_config_t *item = config_FindConfig(key);
        if (!item)
            continue;
        switch (CONFIG_CLASS(item->i_type))
        {
        case CONFIG_ITEM_BOOL:
        case CONFIG_ITEM_INTEGER:
            config_PutInt(key, item->orig.i);
            break;
        case CONFIG_ITEM_FLOAT:
            config_PutFloat(key, item->orig.f);
            break;
        case CONFIG_ITEM_STRING:
            config_PutPsz(key, item->orig.psz);
            break;
        default:
            break;
        }
    }
    // the video output has its own copy of these
    for (const SharedVOutThread &vout : THEMIM->getVouts())
    {
        var_SetInteger(vout.get(), "sub-text-scale", config_GetInt("sub-text-scale"));
        var_SetInteger(vout.get(), "sub-margin", config_GetInt("sub-margin"));
    }
    THEMIM->setSubtitleDelayMS(0);

    m_subtitlePreset.clear();
    getSettings()->remove(SETTINGS_CURRENT_PRESET);
    scheduleSave();
    emit subtitlePresetsChanged();
    touch();
}

/* Sleep timer */

void PlayerTweaks::setSleepTimer(int minutes)
{
    minutes = qMax(0, minutes);
    m_sleepMinutes = minutes;

    if (minutes > 0)
    {
        m_sleepTimer.start(minutes * 60 * 1000);
        m_sleepTick.start();
        m_sleepClock.start();
    }
    else
    {
        m_sleepTimer.stop();
        m_sleepTick.stop();
    }
    emit sleepTimerChanged();
    emit sleepTimerRemainingChanged();
}

int PlayerTweaks::sleepTimerRemaining() const
{
    if (m_sleepMinutes <= 0 || !m_sleepTimer.isActive())
        return 0;
    return qMax<int>(0, m_sleepTimer.remainingTime() / 1000);
}

/* Sidebar */

void PlayerTweaks::setSidebarVisible(bool visible)
{
    if (m_sidebarVisible == visible)
        return;
    m_sidebarVisible = visible;
    emit sidebarChanged();
}

void PlayerTweaks::setSidebarPage(int page)
{
    if (m_sidebarPage == page)
        return;
    m_sidebarPage = page;
    emit sidebarChanged();
}

void PlayerTweaks::toggleSidebar(int page)
{
    if (m_sidebarVisible && m_sidebarPage == page)
    {
        setSidebarVisible(false);
        return;
    }
    setSidebarPage(page);
    setSidebarVisible(true);
}

/* Renderers */

QStringList PlayerTweaks::renderers() const
{
    QStringList names;
    RendererManager *manager = THEMIM->getRendererManager();
    for (int i = 0; i < manager->rowCount(); ++i)
        names.append(manager->data(manager->index(i), RendererManager::NAME).toString());
    return names;
}

int PlayerTweaks::renderer() const
{
    RendererManager *manager = THEMIM->getRendererManager();
    for (int i = 0; i < manager->rowCount(); ++i)
        if (manager->data(manager->index(i), RendererManager::SELECTED).toBool())
            return i;
    return -1;
}

void PlayerTweaks::setRenderer(int index)
{
    RendererManager *manager = THEMIM->getRendererManager();
    if (index < 0 || index >= manager->rowCount())
        manager->disableRenderer();
    else
        manager->setData(manager->index(index), true, RendererManager::SELECTED);
    touch();
}

void PlayerTweaks::scanRenderers()
{
    RendererManager *manager = THEMIM->getRendererManager();
    if (manager->getStatus() != RendererManager::RUNNING)
        manager->StartScan();
}

/* Stereo test */

namespace {

// 16 bits stereo WAV: a tone on the left channel, then on the right one
QByteArray stereoTestSound()
{
    const int rate = 44100;
    const int toneFrames = rate * 7 / 10;
    const int gapFrames = rate / 5;
    const int frames = toneFrames * 2 + gapFrames;

    QByteArray samples(frames * 4, '\0');
    qint16 *data = reinterpret_cast<qint16 *>(samples.data());
    for (int i = 0; i < toneFrames; ++i)
    {
        // short fades avoid clicks
        const double fade = std::min(1.0, std::min(i, toneFrames - i) / (rate * 0.02));
        const qint16 value = qint16(std::sin(2 * M_PI * 660.0 * i / rate) * 9000 * fade);
        data[i * 2] = qToLittleEndian(value);                                  // left
        data[(toneFrames + gapFrames + i) * 2 + 1] = qToLittleEndian(value);   // right
    }

    QByteArray wav;
    auto put32 = [&wav](quint32 v) { v = qToLittleEndian(v); wav.append(reinterpret_cast<const char *>(&v), 4); };
    auto put16 = [&wav](quint16 v) { v = qToLittleEndian(v); wav.append(reinterpret_cast<const char *>(&v), 2); };
    wav.append("RIFF");
    put32(36 + samples.size());
    wav.append("WAVEfmt ");
    put32(16);
    put16(1);           // PCM
    put16(2);           // channels
    put32(rate);
    put32(rate * 4);    // bytes per second
    put16(4);           // bytes per frame
    put16(16);          // bits per sample
    wav.append("data");
    put32(samples.size());
    wav.append(samples);
    return wav;
}

} // namespace

void PlayerTweaks::testStereo()
{
    if (m_testPlayer)
        return;

    const QString path = QDir::temp().filePath(QStringLiteral("vlc-stereo-test.wav"));
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly) || file.write(stereoTestSound()) < 0)
    {
        msg_Err(p_intf, "Unable to write the stereo test sound");
        return;
    }
    file.close();

    m_testPlayer = vlc_player_New(VLC_OBJECT(p_intf), VLC_PLAYER_LOCK_NORMAL);
    if (!m_testPlayer)
        return;

    // play it the way the media plays
    int64_t stereoMode = 0;
    if (SharedAOut aout = THEMIM->getAout())
        stereoMode = var_GetInteger(aout.get(), "stereo-mode");

    char *uri = vlc_path2uri(qtu(QDir::toNativeSeparators(path)), nullptr);
    input_item_t *item = uri ? input_item_New(uri, "Stereo test") : nullptr;
    free(uri);

    vlc_player_Lock(m_testPlayer);
    if (audio_output_t *aout = vlc_player_aout_Hold(m_testPlayer))
    {
        var_SetInteger(aout, "stereo-mode", stereoMode);
        aout_Release(aout);
    }
    if (item)
    {
        vlc_player_SetCurrentMedia(m_testPlayer, item);
        vlc_player_Start(m_testPlayer);
        input_item_Release(item);
    }
    vlc_player_Unlock(m_testPlayer);

    QTimer::singleShot(2500, this, [this]() {
        vlc_player_Lock(m_testPlayer);
        vlc_player_Stop(m_testPlayer);
        vlc_player_Unlock(m_testPlayer);
        vlc_player_Delete(m_testPlayer);
        m_testPlayer = nullptr;
    });
}

/* Interface settings */

QVariant PlayerTweaks::uiOption(const QString &name, const QVariant &defaultValue) const
{
    return getSettings()->value(SETTINGS_UI + QLatin1Char('/') + name, defaultValue);
}

void PlayerTweaks::setUiOption(const QString &name, const QVariant &value)
{
    getSettings()->setValue(SETTINGS_UI + QLatin1Char('/') + name, value);
    touch();
}

/* Pickers */

QUrl PlayerTweaks::chooseFolder(const QString &title) const
{
    return QFileDialog::getExistingDirectoryUrl(nullptr, title);
}

QList<QUrl> PlayerTweaks::chooseFiles(const QString &title, const QString &filter) const
{
    return QFileDialog::getOpenFileUrls(nullptr, title, QUrl(), filter);
}

/* Resume */

void PlayerTweaks::updateResumeTime()
{
    if (m_resumeTime != 0)
    {
        m_resumeTime = 0;
        emit resumeTimeChanged();
    }

    if (!THEMIM->canRestorePlayback() || !p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    const QString mrl = THEMIM->getUrl().toString(QUrl::FullyEncoded);
    p_intf->p_mi->getMediaLibrary()->runOnMLThread<qint64>(this,
    //ML thread
    [mrl](vlc_medialibrary_t* ml, qint64& time) {
        time = 0;
        vlc_ml_media_t *media = vlc_ml_get_media_by_mrl(ml, qtu(mrl));
        if (media)
        {
            if (media->f_progress > 0 && media->i_duration > 0)
                time = qint64(media->f_progress * media->i_duration);
            vlc_ml_media_release(media);
        }
    },
    //UI thread
    [this](quint64, qint64& time) {
        m_resumeTime = time;
        emit resumeTimeChanged();
    });
}

/* Folders */

namespace {

QStringList extensionsOf(const char *list)
{
    // "*.avi;*.mkv;..." -> {"avi", "mkv", ...}
    QStringList extensions;
    for (const QString &pattern : QString::fromLatin1(list).split(QLatin1Char(';'), Qt::SkipEmptyParts))
        extensions.append(pattern.mid(2).toLower());
    return extensions;
}

} // namespace

QVariantList PlayerTweaks::folderItems(const QUrl &folder) const
{
    QVariantList items;
    if (!folder.isLocalFile())
        return items;

    static const QStringList video = extensionsOf(EXTENSIONS_VIDEO);
    static const QStringList audio = extensionsOf(EXTENSIONS_AUDIO);

    const QDir dir(folder.toLocalFile());
    const QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::Readable,
                                                    QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
    for (const QFileInfo &entry : entries)
    {
        const QString suffix = entry.suffix().toLower();
        const bool isVideo = video.contains(suffix);
        if (!entry.isDir() && !isVideo && !audio.contains(suffix))
            continue;
        items.append(QVariantMap {
            { QStringLiteral("name"), entry.fileName() },
            { QStringLiteral("url"), QUrl::fromLocalFile(entry.absoluteFilePath()) },
            { QStringLiteral("isDir"), entry.isDir() },
            { QStringLiteral("isVideo"), isVideo },
        });
    }
    return items;
}

QUrl PlayerTweaks::parentFolder(const QUrl &media) const
{
    if (!media.isLocalFile())
        return {};
    return QUrl::fromLocalFile(QFileInfo(media.toLocalFile()).absolutePath());
}

/* Models */

QVariantList PlayerTweaks::modelEntries(QAbstractItemModel *model) const
{
    QVariantList entries;
    if (!model)
        return entries;
    for (int row = 0; row < model->rowCount(); ++row)
    {
        const QModelIndex index = model->index(row, 0);
        const QVariant state = model->data(index, Qt::CheckStateRole);
        const bool checked = (state.typeId() == QMetaType::Bool) ? state.toBool()
                                                                : (state.toInt() == Qt::Checked);
        entries.append(QVariantMap {
            { QStringLiteral("text"), model->data(index, Qt::DisplayRole).toString() },
            { QStringLiteral("checked"), checked },
        });
    }
    return entries;
}

void PlayerTweaks::checkModelEntry(QAbstractItemModel *model, int row)
{
    if (!model || row < 0 || row >= model->rowCount())
        return;
    model->setData(model->index(row, 0), true, Qt::CheckStateRole);
}

/* Subtitles */

namespace {

constexpr QLatin1String SETTINGS_SUBTITLES {"Redesign/subtitleFor"};

QString subtitleKey(const QUrl &media)
{
    // QSettings keys can not hold slashes
    return QString::fromLatin1(media.toString(QUrl::FullyEncoded).toUtf8().toBase64(QByteArray::Base64UrlEncoding));
}

} // namespace

QVariantList PlayerTweaks::subtitleFiles(const QUrl &folder) const
{
    QVariantList files;
    if (!folder.isLocalFile())
        return files;

    static const QStringList extensions = extensionsOf(EXTENSIONS_SUBTITLE);

    QStringList dirs { folder.toLocalFile() };
    for (const QString &sub : { QStringLiteral("Subs"), QStringLiteral("subs"), QStringLiteral("Subtitles"), QStringLiteral("subtitles") })
    {
        const QString path = QDir(folder.toLocalFile()).filePath(sub);
        if (QFileInfo(path).isDir())
            dirs.append(path);
    }

    for (const QString &path : dirs)
    {
        const QFileInfoList entries = QDir(path).entryInfoList(QDir::Files | QDir::Readable, QDir::Name | QDir::IgnoreCase);
        for (const QFileInfo &entry : entries)
        {
            if (!extensions.contains(entry.suffix().toLower()))
                continue;
            files.append(QVariantMap {
                { QStringLiteral("name"), entry.fileName() },
                { QStringLiteral("url"), QUrl::fromLocalFile(entry.absoluteFilePath()) },
            });
        }
    }
    return files;
}

QVariantList PlayerTweaks::queueItems() const
{
    QVariantList items;
    vlc_playlist_t *playlist = p_intf->p_playlist;
    vlc_playlist_Lock(playlist);
    const size_t count = vlc_playlist_Count(playlist);
    for (size_t i = 0; i < count; ++i)
    {
        input_item_t *media = vlc_playlist_item_GetMedia(vlc_playlist_Get(playlist, i));
        vlc_mutex_lock(&media->lock);
        items.append(QVariantMap {
            { QStringLiteral("name"), qfu(media->psz_name) },
            { QStringLiteral("url"), QUrl::fromEncoded(QByteArray(media->psz_uri)) },
        });
        vlc_mutex_unlock(&media->lock);
    }
    vlc_playlist_Unlock(playlist);
    return items;
}

void PlayerTweaks::setSubtitleFor(const QUrl &media, const QUrl &subtitle)
{
    QSettings *settings = getSettings();
    settings->beginGroup(SETTINGS_SUBTITLES);
    if (subtitle.isEmpty())
        settings->remove(subtitleKey(media));
    else
        settings->setValue(subtitleKey(media), subtitle.toString(QUrl::FullyEncoded));
    settings->endGroup();

    if (!subtitle.isEmpty() && media == THEMIM->getUrl())
    {
        vlc_player_locker lock{ p_intf->p_player };
        vlc_player_AddAssociatedMedia(p_intf->p_player, SPU_ES,
                                      qtu(subtitle.toString(QUrl::FullyEncoded)), true, true, false);
    }
}

QUrl PlayerTweaks::subtitleFor(const QUrl &media) const
{
    QSettings *settings = getSettings();
    settings->beginGroup(SETTINGS_SUBTITLES);
    const QString value = settings->value(subtitleKey(media)).toString();
    settings->endGroup();
    return value.isEmpty() ? QUrl() : QUrl::fromEncoded(value.toUtf8());
}

void PlayerTweaks::loadRememberedSubtitle()
{
    const QUrl media = THEMIM->getUrl();
    if (media.isEmpty())
        return;
    const QUrl subtitle = subtitleFor(media);
    if (subtitle.isEmpty())
        return;

    vlc_player_locker lock{ p_intf->p_player };
    vlc_player_AddAssociatedMedia(p_intf->p_player, SPU_ES,
                                  qtu(subtitle.toString(QUrl::FullyEncoded)), true, false, false);
}

/* Playlists */

void PlayerTweaks::createPlaylist(const QString &name, const QVariantList &urls, bool play)
{
    QStringList mrls;
    for (const QVariant &url : urls)
    {
        const QUrl u = url.toUrl();
        if (u.isValid() && !u.isEmpty())
            mrls.append(u.toString(QUrl::FullyEncoded));
    }
    if (mrls.isEmpty())
        return;

    if (play)
    {
        QVariantList items;
        for (const QString &mrl : mrls)
            items.append(QUrl::fromEncoded(mrl.toUtf8()));
        p_intf->p_mainPlaylistController->append(items, true);
    }

    if (name.trimmed().isEmpty() || !p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    p_intf->p_mi->getMediaLibrary()->runOnMLThread(this,
    //ML thread
    [name = name.trimmed(), mrls](vlc_medialibrary_t* ml) {
        vlc_ml_playlist_t *playlist = vlc_ml_playlist_create(ml, qtu(name));
        if (!playlist)
            return;
        const int64_t playlistId = playlist->i_id;
        vlc_ml_playlist_release(playlist);

        for (const QString &mrl : mrls)
        {
            vlc_ml_media_t *media = vlc_ml_get_media_by_mrl(ml, qtu(mrl));
            if (!media)
                media = mrl.startsWith(QLatin1String("file:"))
                        ? vlc_ml_new_external_media(ml, qtu(mrl))
                        : vlc_ml_new_stream(ml, qtu(mrl));
            if (!media)
                continue;
            vlc_ml_playlist_append(ml, playlistId, &media->i_id, 1);
            vlc_ml_media_release(media);
        }
    });
}

void PlayerTweaks::locateFolder(const QUrl &url, bool isFolder)
{
    if (!p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    struct Ctx {
        int64_t id = 0;
        QString title;
        bool hasVideo = false;
    };
    const QUrl folder = isFolder ? url.adjusted(QUrl::StripTrailingSlash)
                                 : url.adjusted(QUrl::RemoveFilename | QUrl::StripTrailingSlash);

    p_intf->p_mi->getMediaLibrary()->runOnMLThread<Ctx>(this,
    [folder](vlc_medialibrary_t* ml, Ctx& ctx) {
        vlc_ml_folder_list_t *list = vlc_ml_list_folders(ml, nullptr);
        if (!list)
            return;
        for (size_t i = 0; i < list->i_nb_items; ++i)
        {
            const vlc_ml_folder_t &f = list->p_items[i];
            if (f.psz_mrl == nullptr)
                continue;
            const QUrl mrl = QUrl::fromEncoded(f.psz_mrl).adjusted(QUrl::StripTrailingSlash);
            if (mrl.matches(folder, QUrl::NormalizePathSegments))
            {
                ctx.id = f.i_id;
                ctx.title = qfu(f.psz_name);
                ctx.hasVideo = f.i_nb_video > 0;
                break;
            }
        }
        vlc_ml_folder_list_release(list);
    },
    [this, folder](quint64, Ctx& ctx) {
        if (ctx.id > 0)
            emit folderLocated(QVariant::fromValue(MLItemId(ctx.id, VLC_ML_PARENT_FOLDER)), ctx.title,
                               folder, ctx.hasVideo);
    });
}

PlayerTweaks::~PlayerTweaks()
{
    stopEmbeddedCues();
    stopOnline();

    if (m_previewParser)
        vlc_preparser_Delete(m_previewParser);
    for (const QString &file : std::as_const(m_previewFiles))
        QFile::remove(file);

    if (m_wavePlayer)
    {
        vlc_player_Lock(m_wavePlayer);
        vlc_player_Stop(m_wavePlayer);
        vlc_player_Unlock(m_wavePlayer);
        vlc_player_Delete(m_wavePlayer);
        QFile::remove(m_waveFile);
    }
}

void PlayerTweaks::loadWaveform(const QUrl &url)
{
    msg_Dbg(p_intf, "waveform of %s", qtu(url.toString()));
    m_wantedWaveUrl = url;

    const auto cached = m_waveCache.constFind(url.toString());
    m_waveform = (cached != m_waveCache.constEnd()) ? *cached : QVariantList{};
    emit waveformChanged();

    // another file is being read: not needed anymore
    if (m_wavePlayer && url != m_waveUrl)
    {
        m_waveTimer.stop();
        vlc_player_Lock(m_wavePlayer);
        vlc_player_Stop(m_wavePlayer);
        vlc_player_Unlock(m_wavePlayer);
        vlc_player_Delete(m_wavePlayer);
        m_wavePlayer = nullptr;
        QFile::remove(m_waveFile);
    }

    if (url.isEmpty() || cached != m_waveCache.constEnd() || m_wavePlayer)
        return; // nothing to do, or being read
    startWaveform(url);
}

void PlayerTweaks::startWaveform(const QUrl &url)
{
    m_wavePlayer = vlc_player_New(VLC_OBJECT(p_intf), VLC_PLAYER_LOCK_NORMAL);
    if (!m_wavePlayer)
        return;

    m_waveUrl = url;
    m_waveFile = QDir::temp().filePath(QStringLiteral("vlc-waveform-%1.wav")
                                       .arg(QCoreApplication::applicationPid()));
    QFile::remove(m_waveFile);

    input_item_t *item = input_item_New(qtu(url.toString(QUrl::FullyEncoded)), "waveform");
    if (!item)
    {
        vlc_player_Delete(m_wavePlayer);
        m_wavePlayer = nullptr;
        return;
    }

    // the sound only, mono and at a low rate: enough for its loudness, and
    // written as fast as it can be decoded
    QString path = m_waveFile;
    path.replace('\\', '/');
    const QString sout = QStringLiteral(":sout=#transcode{vcodec=none,scodec=none,acodec=s16l,"
                                        "channels=1,samplerate=4000}:std{access=file,mux=wav,dst=\"%1\"}")
                         .arg(path);
    input_item_AddOption(item, qtu(sout), VLC_INPUT_OPTION_TRUSTED);
    input_item_AddOption(item, ":no-sout-video", VLC_INPUT_OPTION_TRUSTED);
    input_item_AddOption(item, ":no-sout-spu", VLC_INPUT_OPTION_TRUSTED);

    vlc_player_Lock(m_wavePlayer);
    vlc_player_SetCurrentMedia(m_wavePlayer, item);
    vlc_player_Start(m_wavePlayer);
    vlc_player_Unlock(m_wavePlayer);
    input_item_Release(item);

    m_waveClock.start();
    m_waveTimer.start();
}

void PlayerTweaks::finishWaveform()
{
    m_waveTimer.stop();
    vlc_player_Lock(m_wavePlayer);
    vlc_player_Stop(m_wavePlayer);
    vlc_player_Unlock(m_wavePlayer);
    vlc_player_Delete(m_wavePlayer);
    m_wavePlayer = nullptr;

    // the samples: the "data" chunk of the WAV file, 16 bits, mono
    QVariantList peaks;
    QFile file(m_waveFile);
    if (file.open(QIODevice::ReadOnly))
    {
        const QByteArray wav = file.readAll();
        file.close();
        qsizetype pos = 12;
        while (pos + 8 <= wav.size())
        {
            const QByteArray id = wav.mid(pos, 4);
            quint32 size = qFromLittleEndian<quint32>(wav.constData() + pos + 4);
            pos += 8;
            if (id == "data")
            {
                // the size may not have been written when the file was not ended
                if (size == 0 || pos + size > (quint64)wav.size())
                    size = wav.size() - pos;
                const qint16 *samples = reinterpret_cast<const qint16 *>(wav.constData() + pos);
                const qsizetype count = size / 2;
                const int bars = 240;
                if (count >= bars)
                {
                    QVector<double> levels(bars);
                    double loudest = 0.;
                    for (int b = 0; b < bars; ++b)
                    {
                        const qsizetype from = count * b / bars;
                        const qsizetype to = count * (b + 1) / bars;
                        double sum = 0.;
                        for (qsizetype i = from; i < to; ++i)
                            sum += double(samples[i]) * samples[i];
                        levels[b] = std::sqrt(sum / std::max<qsizetype>(1, to - from));
                        loudest = std::max(loudest, levels[b]);
                    }
                    for (double level : levels)
                        peaks.append(loudest > 0. ? level / loudest : 0.);
                }
                break;
            }
            pos += size + (size & 1);
        }
    }
    QFile::remove(m_waveFile);

    msg_Dbg(p_intf, "waveform of %s: %lld values", qtu(m_waveUrl.toString()), (long long)peaks.size());

    // nothing read: it happens when asked as VLC starts; once more, later
    const QString key = m_waveUrl.toString();
    if (peaks.isEmpty() && !m_waveRetried.contains(key) && m_waveUrl == m_wantedWaveUrl)
    {
        m_waveRetried.insert(key);
        const QUrl url = m_waveUrl;
        QTimer::singleShot(2000, this, [this, url]() {
            if (!m_wavePlayer && url == m_wantedWaveUrl)
                startWaveform(url);
        });
        return;
    }

    m_waveCache.insert(key, peaks);
    if (m_waveUrl == m_wantedWaveUrl)
    {
        m_waveform = peaks;
        emit waveformChanged();
    }
    else if (!m_wantedWaveUrl.isEmpty() && !m_waveCache.contains(m_wantedWaveUrl.toString()))
    {
        startWaveform(m_wantedWaveUrl);
    }
}

void PlayerTweaks::requestMediaInfo(const QVariantList &urls)
{
    if (!p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    // [the key the interface looks for, the MRL of the library]
    QList<QPair<QString, QString>> mrls;
    for (const QVariant &value : urls)
    {
        const QUrl url = value.toUrl();
        const QString key = url.toString();
        if (key.isEmpty() || m_mediaInfo.contains(key))
            continue;
        // the library spells local files as VLC does, which encodes more
        // than Qt ("(" and ")" too)
        QString mrl = url.toString(QUrl::FullyEncoded);
        if (url.isLocalFile())
        {
            if (char *uri = vlc_path2uri(qtu(QDir::toNativeSeparators(url.toLocalFile())), nullptr))
            {
                mrl = qfu(uri);
                free(uri);
            }
        }
        mrls.append({ key, mrl });
    }
    if (mrls.isEmpty())
        return;

    struct Ctx {
        QVariantMap info;
    };
    p_intf->p_mi->getMediaLibrary()->runOnMLThread<Ctx>(this,
    [mrls](vlc_medialibrary_t* ml, Ctx& ctx) {
        for (const auto &entry : mrls)
        {
            vlc_ml_media_t *media = vlc_ml_get_media_by_mrl(ml, qtu(entry.second));
            if (!media)
                continue;
            const vlc_ml_thumbnail_t &thumbnail = media->thumbnails[VLC_ML_THUMBNAIL_SMALL];
            const QString thumbnailMrl = (thumbnail.i_status == VLC_ML_THUMBNAIL_STATUS_AVAILABLE && thumbnail.psz_mrl)
                                         ? qfu(thumbnail.psz_mrl) : QString();
            ctx.info.insert(entry.first, QVariantMap {
                { QStringLiteral("thumbnail"), thumbnailMrl },
                { QStringLiteral("progress"), media->f_progress },
                { QStringLiteral("playCount"), media->i_playcount },
            });
            vlc_ml_media_release(media);
        }
    },
    [this](quint64, Ctx& ctx) {
        if (ctx.info.isEmpty())
            return;
        m_mediaInfo.insert(ctx.info);
        emit mediaInfoChanged();
    });
}

/* Seek preview */

namespace {

// positions of the pictures along a video
constexpr int previewBuckets = 200;

struct PreviewRequest
{
    PlayerTweaks *tweaks;
    QString key;
    QString file;
    QByteArray path;
    double position;
};

void onSeekPreviewEnded(vlc_preparser_req *req, int status,
                        const bool *results, size_t count, void *data)
{
    auto *request = static_cast<PreviewRequest *>(data);
    const bool done = status == VLC_SUCCESS && count == 1 && results[0];
    vlc_preparser_req_Release(req);

    // back on the thread of the interface
    QMetaObject::invokeMethod(request->tweaks, [request, done]() {
        request->tweaks->seekPreviewDone(request->key, done ? request->file : QString(),
                                         request->position);
        delete request;
    }, Qt::QueuedConnection);
}

}

void PlayerTweaks::requestSeekPreview(const QUrl &media, double position)
{
    if (media.isEmpty())
        return;
    const int bucket = std::clamp(int(std::lround(position * previewBuckets)), 0, previewBuckets);
    m_previewMedia = media;
    m_previewBucket = bucket;

    const QString key = media.toString() + QLatin1Char('#') + QString::number(bucket);
    const auto found = m_previewFiles.constFind(key);
    if (found != m_previewFiles.constEnd())
    {
        m_seekPreview = QUrl::fromLocalFile(*found);
        m_seekPreviewPosition = double(bucket) / previewBuckets;
        emit seekPreviewChanged();
        return;
    }
    if (!m_previewBusy)
        startSeekPreview();
}

void PlayerTweaks::startSeekPreview()
{
    if (!m_previewParser)
    {
        const struct vlc_preparser_cfg cfg = {
            .types = VLC_PREPARSER_TYPE_THUMBNAIL_TO_FILES,
            .max_parser_threads = 0,
            .max_thumbnailer_threads = 1,
            .timeout = VLC_TICK_FROM_SEC(5),
#if defined(HAVE_VLC_EXTERNAL_PREPARSER)
            .external_process = true,
#else
            .external_process = false,
#endif
        };
        m_previewParser = vlc_preparser_New(VLC_OBJECT(p_intf), &cfg);
        if (!m_previewParser)
            return;
    }

    input_item_t *item = input_item_New(qtu(m_previewMedia.toString(QUrl::FullyEncoded)), nullptr);
    if (!item)
        return;

    auto *request = new PreviewRequest;
    request->tweaks = this;
    request->key = m_previewMedia.toString() + QLatin1Char('#') + QString::number(m_previewBucket);
    request->file = QDir::temp().filePath(QStringLiteral("vlc-seek-%1-%2.jpg")
                                          .arg(QCoreApplication::applicationPid())
                                          .arg(m_previewFiles.size()));
    request->path = request->file.toUtf8();
    request->position = double(m_previewBucket) / previewBuckets;

    struct vlc_thumbnailer_arg arg = {};
    arg.seek.type = vlc_thumbnailer_arg::seek::VLC_THUMBNAILER_SEEK_POS;
    arg.seek.pos = request->position;
    arg.seek.speed = vlc_thumbnailer_arg::seek::VLC_THUMBNAILER_SEEK_FAST;
    arg.hw_dec = false;

    struct vlc_thumbnailer_output output = {};
    output.format = VLC_THUMBNAILER_FORMAT_JPEG;
    output.width = 320;
    output.height = 180;
    output.crop = false;
    output.file_path = request->path.constData();
    output.creat_mode = 0600;

    static const struct vlc_thumbnailer_to_files_cbs cbs = {
        .on_ended = onSeekPreviewEnded,
    };

    vlc_preparser_req *req = vlc_preparser_req_NewThumbnailToFiles(m_previewParser, item, &arg,
                                                                   &output, 1, &cbs, request);
    input_item_Release(item);
    if (!req)
    {
        delete request;
        return;
    }
    if (vlc_preparser_Submit(m_previewParser, req) != VLC_SUCCESS)
    {
        vlc_preparser_req_Release(req);
        delete request;
        return;
    }
    m_previewBusy = true;
}

void PlayerTweaks::seekPreviewDone(const QString &key, const QString &file, double position)
{
    m_previewBusy = false;
    if (!file.isEmpty())
        m_previewFiles.insert(key, file);

    const QString wanted = m_previewMedia.toString() + QLatin1Char('#') + QString::number(m_previewBucket);
    if (key == wanted && !file.isEmpty())
    {
        m_seekPreview = QUrl::fromLocalFile(file);
        m_seekPreviewPosition = position;
        emit seekPreviewChanged();
    }
    else if (key != wanted && !m_previewFiles.contains(wanted))
    {
        // the pointer moved on meanwhile
        startSeekPreview();
    }
}

/* Subtitle timeline */

namespace {

// "00:01:02,500" or "0:01:02.50" (seconds may have a fraction)
double parseCueTime(const QString &text)
{
    const QStringList parts = QString(text).replace(QLatin1Char(','), QLatin1Char('.'))
                                           .trimmed().split(QLatin1Char(':'));
    double seconds = 0.;
    for (const QString &part : parts)
        seconds = seconds * 60. + part.toDouble();
    return seconds;
}

}

QVariantList PlayerTweaks::subtitleCues(const QUrl &media)
{
    QVariantList cues;
    if (!media.isLocalFile())
        return cues;

    // the subtitle chosen for the media, or one named after it
    QString path;
    const QUrl chosen = subtitleFor(media);
    if (chosen.isLocalFile() && QFileInfo::exists(chosen.toLocalFile()))
        path = chosen.toLocalFile();
    else
    {
        const QString base = QFileInfo(media.toLocalFile()).completeBaseName().toLower();
        for (const QVariant &file : subtitleFiles(parentFolder(media)))
        {
            const QString name = file.toMap().value(QStringLiteral("name")).toString().toLower();
            if (name.startsWith(base))
            {
                path = file.toMap().value(QStringLiteral("url")).toUrl().toLocalFile();
                break;
            }
        }
    }
    // none: the subtitles inside the media
    if (path.isEmpty())
        return embeddedSubtitleCues(media);

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text) || file.size() > 16 * 1024 * 1024)
        return cues;

    // SubRip and WebVTT: "start --> end"; SSA/ASS: "Dialogue: layer,start,end,..."
    while (!file.atEnd())
    {
        const QString line = QString::fromUtf8(file.readLine()).trimmed();
        const qsizetype arrow = line.indexOf(QLatin1String("-->"));
        if (arrow > 0)
        {
            const QString end = line.mid(arrow + 3).trimmed().section(QLatin1Char(' '), 0, 0);
            cues.append(parseCueTime(line.left(arrow)));
            cues.append(parseCueTime(end));
        }
        else if (line.startsWith(QLatin1String("Dialogue:"), Qt::CaseInsensitive))
        {
            const QStringList fields = line.mid(9).split(QLatin1Char(','));
            if (fields.size() > 2)
            {
                cues.append(parseCueTime(fields[1]));
                cues.append(parseCueTime(fields[2]));
            }
        }
    }
    return cues;
}

/* Metadata */

QVariantMap PlayerTweaks::mediaDetails() const
{
    QVariantMap details;
    vlc_player_t *player = p_intf->p_player;
    vlc_player_locker lock{ player };

    input_item_t *item = vlc_player_GetCurrentMedia(player);
    if (!item)
        return details;

    char *title = input_item_GetTitleFbName(item);
    details.insert(QStringLiteral("title"), qfu(title));
    free(title);

    char *uri = input_item_GetURI(item);
    const QUrl url = QUrl::fromEncoded(QByteArray(uri ? uri : ""));
    free(uri);
    if (url.isLocalFile())
    {
        const QFileInfo info(url.toLocalFile());
        details.insert(QStringLiteral("size"), QLocale().formattedDataSize(info.size()));
        details.insert(QStringLiteral("format"), info.suffix().toUpper());
    }

    // the short name of a codec: "H264 - MPEG-4 AVC (part 10)" gives "H264"
    const auto codecName = [](int cat, vlc_fourcc_t codec) {
        const char *description = vlc_fourcc_GetDescription(cat, codec);
        QString name = description ? qfu(description).section(QLatin1String(" - "), 0, 0) : QString();
        if (name.isEmpty())
        {
            char fourcc[5] = {};
            vlc_fourcc_to_char(codec, fourcc);
            name = QString::fromLatin1(fourcc).trimmed().toUpper();
        }
        return name;
    };

    const auto selected = [player](enum es_format_category_e cat) -> const struct vlc_player_track * {
        const size_t count = vlc_player_GetTrackCount(player, cat);
        for (size_t i = 0; i < count; ++i)
        {
            const struct vlc_player_track *track = vlc_player_GetTrackAt(player, cat, i);
            if (track && track->selected)
                return track;
        }
        return nullptr;
    };

    if (const struct vlc_player_track *video = selected(VIDEO_ES))
    {
        const video_format_t &v = video->fmt.video;
        QStringList parts;
        const unsigned width = v.i_visible_width ? v.i_visible_width : v.i_width;
        const unsigned height = v.i_visible_height ? v.i_visible_height : v.i_height;
        if (width && height)
            parts.append(QStringLiteral("%1 × %2").arg(width).arg(height));
        parts.append(codecName(VIDEO_ES, video->fmt.i_codec));
        if (v.i_frame_rate && v.i_frame_rate_base)
            parts.append(qtr("%1 fps").arg(QLocale().toString(double(v.i_frame_rate) / v.i_frame_rate_base, 'g', 4)));
        details.insert(QStringLiteral("video"), parts.join(QStringLiteral(" · ")));
    }

    if (const struct vlc_player_track *audio = selected(AUDIO_ES))
    {
        const audio_format_t &a = audio->fmt.audio;
        QStringList parts { codecName(AUDIO_ES, audio->fmt.i_codec) };
        if (a.i_channels == 1)
            parts.append(qtr("Mono"));
        else if (a.i_channels == 2)
            parts.append(qtr("Stereo"));
        else if (a.i_channels > 2)
            parts.append(qtr("%1 channels").arg(a.i_channels));
        if (a.i_rate)
            parts.append(qtr("%1 kHz").arg(QLocale().toString(a.i_rate / 1000., 'g', 4)));
        details.insert(QStringLiteral("audio"), parts.join(QStringLiteral(" · ")));
    }
    return details;
}

/* Controls of "Customize Player" */

void PlayerTweaks::seekBy(int seconds)
{
    vlc_player_t *player = p_intf->p_player;
    vlc_player_locker lock{ player };
    if (vlc_player_IsStarted(player))
        vlc_player_JumpTime(player, vlc_tick_from_sec(seconds));
}

void PlayerTweaks::replay()
{
    vlc_player_t *player = p_intf->p_player;
    vlc_player_locker lock{ player };
    if (!vlc_player_GetCurrentMedia(player))
        return;
    if (vlc_player_IsStarted(player))
        vlc_player_SetTime(player, VLC_TICK_0);
    else
        vlc_player_Start(player);
}

void PlayerTweaks::updateCurrentMedia()
{
    if (!p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    QString mrl;
    QStringList queue;
    {
        vlc_player_t *player = p_intf->p_player;
        vlc_player_locker lock{ player };
        if (input_item_t *item = vlc_player_GetCurrentMedia(player))
        {
            char *uri = input_item_GetURI(item);
            mrl = qfu(uri);
            free(uri);
        }
    }
    {
        vlc_playlist_t *playlist = p_intf->p_playlist;
        vlc_playlist_Lock(playlist);
        const size_t count = vlc_playlist_Count(playlist);
        for (size_t i = 0; i < count && i < 2000; ++i)
        {
            input_item_t *item = vlc_playlist_item_GetMedia(vlc_playlist_Get(playlist, i));
            char *uri = input_item_GetURI(item);
            queue.append(qfu(uri));
            free(uri);
        }
        vlc_playlist_Unlock(playlist);
    }

    struct Ctx {
        qint64 id = -1;
        bool favorite = false;
        QString playlist;
    };
    p_intf->p_mi->getMediaLibrary()->runOnMLThread<Ctx>(this,
    [mrl, queue](vlc_medialibrary_t* ml, Ctx& ctx) {
        if (mrl.isEmpty())
            return;
        if (vlc_ml_media_t *media = vlc_ml_get_media_by_mrl(ml, qtu(mrl)))
        {
            ctx.id = media->i_id;
            ctx.favorite = media->b_is_favorite;
            vlc_ml_media_release(media);
        }
        if (queue.size() < 2)
            return;

        // the playlist of the library with the same media as the queue
        vlc_ml_playlist_list_t *playlists = vlc_ml_list_playlists(ml, nullptr, VLC_ML_PLAYLIST_TYPE_ALL);
        if (!playlists)
            return;
        for (size_t i = 0; i < playlists->i_nb_items && ctx.playlist.isEmpty(); ++i)
        {
            const vlc_ml_playlist_t &playlist = playlists->p_items[i];
            if (playlist.i_nb_media != static_cast<unsigned>(queue.size()))
                continue;
            vlc_ml_media_list_t *media = vlc_ml_list_playlist_media(ml, nullptr, playlist.i_id);
            if (!media)
                continue;
            bool same = media->i_nb_items == static_cast<size_t>(queue.size());
            for (size_t j = 0; same && j < media->i_nb_items; ++j)
            {
                const vlc_ml_media_t &m = media->p_items[j];
                const char *file = (m.p_files && m.p_files->i_nb_items > 0) ? m.p_files->p_items[0].psz_mrl : nullptr;
                same = file && qfu(file) == queue[j];
            }
            vlc_ml_media_list_release(media);
            if (same)
                ctx.playlist = qfu(playlist.psz_name);
        }
        vlc_ml_playlist_list_release(playlists);
    },
    [this](quint64, Ctx& ctx) {
        m_currentMediaId = ctx.id;
        m_favorite = ctx.favorite;
        m_playlistName = ctx.playlist;
        emit currentMediaChanged();
    });
}

void PlayerTweaks::toggleFavorite()
{
    if (m_currentMediaId < 0 || !p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;
    const qint64 id = m_currentMediaId;
    const bool favorite = !m_favorite;
    m_favorite = favorite;
    emit currentMediaChanged();
    p_intf->p_mi->getMediaLibrary()->runOnMLThread(this,
    [id, favorite](vlc_medialibrary_t* ml) {
        vlc_ml_media_set_favorite(ml, id, favorite);
    });
}
