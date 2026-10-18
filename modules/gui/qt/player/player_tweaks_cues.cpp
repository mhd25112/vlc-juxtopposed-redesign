/*****************************************************************************
 * player_tweaks_cues.cpp: the subtitle lines inside a media, for the seek bar
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
#include "player_controller.hpp"

#include <QCoreApplication>
#include <QPointer>

#include <vlc_common.h>
#include <vlc_block.h>
#include <vlc_demux.h>
#include <vlc_es_out.h>
#include <vlc_player.h>
#include <vlc_stream.h>

#include <algorithm>
#include <map>
#include <vector>

// "Show Subtitle Timeline on Seekbar" for the subtitles inside a media: the
// file is read by its demuxer in the background, which hands over the
// packets of the subtitle tracks only (the others are reported as not
// selected, so most demuxers skip them), and their times are kept.

namespace {

struct CueTrack
{
    int id;
    std::vector<std::pair<vlc_tick_t, vlc_tick_t>> cues; // start, length (0 if unknown)
};

struct CueEs
{
    bool spu;
    int track; // in CueOut::tracks, -1 if not a subtitle track
};

struct CueOut
{
    es_out_t out;
    std::vector<CueTrack> tracks;
};

es_out_id_t *cueAdd(es_out_t *out, input_source_t *, const es_format_t *fmt)
{
    CueOut *c = container_of(out, CueOut, out);
    auto *es = new CueEs { fmt->i_cat == SPU_ES, -1 };
    if (es->spu)
    {
        es->track = static_cast<int>(c->tracks.size());
        c->tracks.push_back(CueTrack { fmt->i_id, {} });
    }
    return reinterpret_cast<es_out_id_t *>(es);
}

int cueSend(es_out_t *out, es_out_id_t *id, block_t *block)
{
    CueOut *c = container_of(out, CueOut, out);
    auto *es = reinterpret_cast<CueEs *>(id);
    if (es->spu && es->track >= 0)
    {
        const vlc_tick_t start = block->i_pts != VLC_TICK_INVALID ? block->i_pts : block->i_dts;
        if (start != VLC_TICK_INVALID)
            c->tracks[es->track].cues.emplace_back(start - VLC_TICK_0, block->i_length > 0 ? block->i_length : 0);
    }
    block_Release(block);
    return VLC_SUCCESS;
}

void cueDel(es_out_t *, es_out_id_t *id)
{
    delete reinterpret_cast<CueEs *>(id);
}

int cueControl(es_out_t *, input_source_t *, int query, va_list args)
{
    switch (query)
    {
        case ES_OUT_GET_ES_STATE:
        {
            auto *es = reinterpret_cast<CueEs *>(va_arg(args, es_out_id_t *));
            bool *selected = va_arg(args, bool *);
            *selected = es->spu;
            return VLC_SUCCESS;
        }
        case ES_OUT_SET_PCR:
        case ES_OUT_SET_GROUP_PCR:
        case ES_OUT_RESET_PCR:
        case ES_OUT_SET_ES_STATE:
        case ES_OUT_SET_ES_FMT:
        case ES_OUT_SET_GROUP_META:
        case ES_OUT_SET_GROUP:
        case ES_OUT_DEL_GROUP:
            return VLC_SUCCESS;
        default:
            return VLC_EGENERIC;
    }
}

void cueDestroy(es_out_t *)
{
}

const struct es_out_callbacks cueCallbacks = {
    cueAdd, cueSend, cueDel, cueControl, cueDestroy,
};

// track id -> [start, end, start, end...] in seconds
QVariantMap readCues(vlc_object_t *obj, const QByteArray &mrl, const std::atomic_bool &abort)
{
    QVariantMap result;
    CueOut c;
    c.out.cbs = &cueCallbacks;

    stream_t *s = vlc_stream_NewURL(obj, mrl.constData());
    if (!s)
        return result;
    demux_t *demux = demux_New(obj, "any", mrl.constData(), s, &c.out);
    if (!demux)
    {
        vlc_stream_Delete(s);
        return result;
    }
    while (!abort && demux_Demux(demux) == VLC_DEMUXER_SUCCESS)
        ;
    demux_Delete(demux);

    for (CueTrack &track : c.tracks)
    {
        std::sort(track.cues.begin(), track.cues.end());
        QVariantList times;
        for (size_t i = 0; i < track.cues.size(); ++i)
        {
            const vlc_tick_t start = track.cues[i].first;
            vlc_tick_t length = track.cues[i].second;
            // bitmap subtitles: shown until the next one, a few seconds at most
            if (length <= 0)
            {
                const vlc_tick_t next = i + 1 < track.cues.size() ? track.cues[i + 1].first : start + VLC_TICK_FROM_SEC(3);
                length = std::min(next - start, VLC_TICK_FROM_SEC(5));
            }
            if (length <= 0)
                continue;
            times.append(secf_from_vlc_tick(start));
            times.append(secf_from_vlc_tick(start + length));
        }
        result.insert(QString::number(track.id), times);
    }
    return result;
}

}

QVariantList PlayerTweaks::embeddedSubtitleCues(const QUrl &media)
{
    const QString key = media.toString();
    const auto cached = m_embeddedCues.constFind(key);
    if (cached == m_embeddedCues.cend())
    {
        startEmbeddedCues(media);
        return {};
    }

    // the subtitle track shown, else the first one
    int wanted = -1;
    {
        vlc_player_t *player = p_intf->p_player;
        vlc_player_locker lock{ player };
        if (const struct vlc_player_track *track = vlc_player_GetSelectedTrack(player, SPU_ES))
            wanted = vlc_es_id_GetInputId(track->es_id);
    }
    if (wanted >= 0 && cached->contains(QString::number(wanted)))
        return cached->value(QString::number(wanted)).toList();
    for (auto it = cached->cbegin(); it != cached->cend(); ++it)
    {
        if (!it.value().toList().isEmpty())
            return it.value().toList();
    }
    return {};
}

void PlayerTweaks::startEmbeddedCues(const QUrl &media)
{
    const QString key = media.toString();
    if (key == m_cueUrl || !media.isLocalFile())
        return;

    stopEmbeddedCues();
    m_cueUrl = key;
    m_cueAbort = std::make_shared<std::atomic_bool>(false);

    const QByteArray mrl = media.toString(QUrl::FullyEncoded).toUtf8();
    vlc_object_t *obj = VLC_OBJECT(p_intf);
    QPointer<PlayerTweaks> self(this);
    auto abort = m_cueAbort;
    m_cueThread = std::thread([obj, mrl, key, abort, self]() {
        QVariantMap cues = readCues(obj, mrl, *abort);
        if (*abort)
            return;
        QMetaObject::invokeMethod(qApp, [self, key, cues]() {
            if (!self)
                return;
            self->m_embeddedCues.insert(key, cues);
            emit self->subtitleCuesChanged();
        }, Qt::QueuedConnection);
    });
}

void PlayerTweaks::stopEmbeddedCues()
{
    if (m_cueAbort)
        *m_cueAbort = true;
    if (m_cueThread.joinable())
        m_cueThread.join();
    m_cueUrl.clear();
}
