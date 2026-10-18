/*****************************************************************************
 * player_tweaks_online.cpp: subtitles from OpenSubtitles
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

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPointer>
#include <QSet>
#include <QtEndian>
#include <QStandardPaths>

#include <vlc_common.h>
#include <vlc_stream.h>

// "Add Subtitles", "From OpenSubtitles": the search of OpenSubtitles (its
// REST interface, which needs no account to search and download), by the
// hash of the file for the subtitles made for it, and by name. Everything
// happens in the background with VLC's own access modules.

namespace {

const char *apiBase = "https://rest.opensubtitles.org/search/";

QByteArray readAll(stream_t *s, const std::atomic_bool &abort, size_t limit)
{
    QByteArray data;
    char buffer[16384];
    while (!abort && static_cast<size_t>(data.size()) < limit)
    {
        const ssize_t n = vlc_stream_Read(s, buffer, sizeof(buffer));
        if (n <= 0)
            break;
        data.append(buffer, static_cast<qsizetype>(n));
    }
    return data;
}

QByteArray fetch(vlc_object_t *obj, const QByteArray &url, const std::atomic_bool &abort,
                 bool inflate = false, size_t limit = 8 * 1024 * 1024, bool *failed = nullptr)
{
    stream_t *s = vlc_stream_NewURL(obj, url.constData());
    if (!s)
    {
        if (failed)
            *failed = true;
        return {};
    }
    if (inflate)
    {
        if (stream_t *filtered = vlc_stream_FilterNew(s, "inflate"))
            s = filtered;
    }
    const QByteArray data = readAll(s, abort, limit);
    vlc_stream_Delete(s);
    return data;
}

// the hash OpenSubtitles knows files by: their size plus the sums of their
// first and last 64 KiB as 64 bit numbers
QString movieHash(const QString &path, qint64 *size)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    const qint64 length = file.size();
    if (length < 131072)
        return {};
    quint64 hash = static_cast<quint64>(length);
    const auto sum = [&](qint64 offset) {
        if (!file.seek(offset))
            return false;
        const QByteArray chunk = file.read(65536);
        if (chunk.size() != 65536)
            return false;
        for (int i = 0; i < 65536; i += 8)
        {
            quint64 v;
            memcpy(&v, chunk.constData() + i, 8);
            hash += qFromLittleEndian(v);
        }
        return true;
    };
    if (!sum(0) || !sum(length - 65536))
        return {};
    *size = length;
    return QStringLiteral("%1").arg(hash, 16, 16, QLatin1Char('0'));
}

QVariantList parseResults(const QByteArray &json, bool byHash)
{
    QVariantList results;
    const QJsonArray items = QJsonDocument::fromJson(json).array();
    for (const QJsonValue &value : items)
    {
        const QJsonObject o = value.toObject();
        const QString link = o.value(QStringLiteral("SubDownloadLink")).toString();
        if (link.isEmpty())
            continue;
        results.append(QVariantMap {
            { QStringLiteral("name"), o.value(QStringLiteral("SubFileName")).toString() },
            { QStringLiteral("movie"), o.value(QStringLiteral("MovieName")).toString() },
            { QStringLiteral("language"), o.value(QStringLiteral("LanguageName")).toString() },
            { QStringLiteral("languageId"), o.value(QStringLiteral("SubLanguageID")).toString() },
            { QStringLiteral("format"), o.value(QStringLiteral("SubFormat")).toString() },
            { QStringLiteral("downloads"), o.value(QStringLiteral("SubDownloadsCnt")).toString().toInt() },
            { QStringLiteral("link"), link },
            // made for this very file
            { QStringLiteral("exact"), byHash && o.value(QStringLiteral("MatchedBy")).toString() == QLatin1String("moviehash") },
        });
    }
    return results;
}

}

void PlayerTweaks::searchOnlineSubtitles(const QUrl &media, const QString &query, const QString &language)
{
    const QString lang = language.isEmpty() ? QStringLiteral("all") : language;
    QString path;
    if (media.isLocalFile())
        path = media.toLocalFile();
    const QByteArray text = QUrl::toPercentEncoding(query.trimmed().toLower());
    vlc_object_t *obj = VLC_OBJECT(p_intf);
    QPointer<PlayerTweaks> self(this);
    auto abort = onlineAbort();

    auto done = startOnlineJob();
    m_onlineThreads.back().thread = std::thread([obj, media, query, lang, path, text, self, abort, done]() {
        struct Done { std::shared_ptr<std::atomic_bool> flag; ~Done() { *flag = true; } } finished { done };
        QVariantList results;
        QSet<QString> seen;
        bool failed = false;
        const auto add = [&](const QVariantList &list) {
            for (const QVariant &r : list)
            {
                const QString link = r.toMap().value(QStringLiteral("link")).toString();
                if (!seen.contains(link))
                {
                    seen.insert(link);
                    results.append(r);
                }
            }
        };

        // made for this file
        qint64 size = 0;
        const QString hash = path.isEmpty() ? QString() : movieHash(path, &size);
        if (!hash.isEmpty() && !*abort)
        {
            const QByteArray url = QByteArray(apiBase) + "moviebytesize-" + QByteArray::number(size)
                                   + "/moviehash-" + hash.toLatin1() + "/sublanguageid-" + lang.toLatin1();
            add(parseResults(fetch(obj, url, *abort, false, 8 * 1024 * 1024, &failed), true));
        }
        // by name
        if (!text.isEmpty() && !*abort)
        {
            const QByteArray url = QByteArray(apiBase) + "query-" + text + "/sublanguageid-" + lang.toLatin1();
            add(parseResults(fetch(obj, url, *abort, false, 8 * 1024 * 1024, &failed), false));
        }
        if (*abort)
            return;
        const QString error = (failed && results.isEmpty()) ? qtr("OpenSubtitles could not be reached.") : QString();
        QMetaObject::invokeMethod(qApp, [self, media, query, results, error]() {
            if (self)
                emit self->onlineSubtitlesReady(media, query, results, error);
        }, Qt::QueuedConnection);
    });
}

void PlayerTweaks::downloadOnlineSubtitle(const QUrl &media, const QString &link, const QString &languageId,
                                          const QString &format)
{
    vlc_object_t *obj = VLC_OBJECT(p_intf);
    QPointer<PlayerTweaks> self(this);
    auto abort = onlineAbort();

    // next to the media, else in the folder of VLC's own data
    QString folder;
    QString base = QStringLiteral("subtitles");
    if (media.isLocalFile())
    {
        const QFileInfo info(media.toLocalFile());
        folder = info.absolutePath();
        base = info.completeBaseName();
    }
    const QString suffix = QStringLiteral(".%1.%2").arg(languageId.isEmpty() ? QStringLiteral("sub") : languageId,
                                                        format.isEmpty() ? QStringLiteral("srt") : format);
    const QString fallback = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/subtitles");

    auto done = startOnlineJob();
    m_onlineThreads.back().thread = std::thread([obj, media, link, folder, base, suffix, fallback, self, abort, done]() {
        struct Done { std::shared_ptr<std::atomic_bool> flag; ~Done() { *flag = true; } } finished { done };
        const QByteArray data = fetch(obj, link.toUtf8(), *abort, true);
        QString file;
        QString error;
        if (data.isEmpty())
        {
            error = qtr("The subtitles could not be downloaded.");
        }
        else
        {
            for (const QString &dir : { folder, fallback })
            {
                if (dir.isEmpty() || !QDir().mkpath(dir))
                    continue;
                QFile out(dir + QLatin1Char('/') + base + suffix);
                if (out.open(QIODevice::WriteOnly) && out.write(data) == data.size())
                {
                    file = out.fileName();
                    break;
                }
            }
            if (file.isEmpty())
                error = qtr("The subtitles could not be saved.");
        }
        if (*abort)
            return;
        QMetaObject::invokeMethod(qApp, [self, media, file, error]() {
            if (!self)
                return;
            if (!file.isEmpty())
                self->setSubtitleFor(media, QUrl::fromLocalFile(file));
            emit self->onlineSubtitleDownloaded(media, file.isEmpty() ? QUrl() : QUrl::fromLocalFile(file), error);
        }, Qt::QueuedConnection);
    });
}

std::shared_ptr<std::atomic_bool> PlayerTweaks::onlineAbort()
{
    if (!m_onlineAbort)
        m_onlineAbort = std::make_shared<std::atomic_bool>(false);
    return m_onlineAbort;
}

std::shared_ptr<std::atomic_bool> PlayerTweaks::startOnlineJob()
{
    // the finished ones
    for (auto it = m_onlineThreads.begin(); it != m_onlineThreads.end();)
    {
        if (*it->done)
        {
            if (it->thread.joinable())
                it->thread.join();
            it = m_onlineThreads.erase(it);
        }
        else
        {
            ++it;
        }
    }
    auto done = std::make_shared<std::atomic_bool>(false);
    m_onlineThreads.push_back(OnlineJob { std::thread(), done });
    return done;
}

void PlayerTweaks::stopOnline()
{
    if (m_onlineAbort)
        *m_onlineAbort = true;
    for (OnlineJob &job : m_onlineThreads)
    {
        if (job.thread.joinable())
            job.thread.join();
    }
    m_onlineThreads.clear();
}
