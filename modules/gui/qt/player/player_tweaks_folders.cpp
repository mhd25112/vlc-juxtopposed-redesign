/*****************************************************************************
 * player_tweaks_folders.cpp: the library as folders on the disk
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

#include <QCollator>
#include <QHash>
#include <QMap>

#include <vlc_media_library.h>

#include "maininterface/mainctx.hpp"
#include "medialibrary/medialib.hpp"
#include "medialibrary/mlqmltypes.hpp"

#include <algorithm>

namespace {

// "file:///C:/Videos/Shows/", with its trailing slash, the same way for the
// library's MRLs and the URLs of the interface
QString folderKey(const QUrl &url)
{
    QString key = url.adjusted(QUrl::NormalizePathSegments).toString(QUrl::FullyEncoded);
    if (!key.endsWith(QLatin1Char('/')))
        key += QLatin1Char('/');
#ifdef _WIN32
    key = key.toLower();
#endif
    return key;
}

QString folderName(const QString &url)
{
    QString path = QUrl(url).adjusted(QUrl::StripTrailingSlash).path();
    return path.section(QLatin1Char('/'), -1);
}

struct Folder
{
    QString url;      // as the library has it
    qint64 id = -1;   // the library's folder, -1 if it holds none of the media
    unsigned count = 0;
};

}

void PlayerTweaks::requestLibraryFolder(const QString &kind, const QUrl &folder)
{
    if (!p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    const bool audio = (kind == QLatin1String("audio"));
    const QString wanted = folder.isEmpty() ? QString() : folderKey(folder);
    QString wantedUrl = folder.toString(QUrl::FullyEncoded);
    if (!wantedUrl.isEmpty() && !wantedUrl.endsWith(QLatin1Char('/')))
        wantedUrl += QLatin1Char('/');

    struct Ctx {
        QVariantMap result;
    };
    p_intf->p_mi->getMediaLibrary()->runOnMLThread<Ctx>(this,
    [audio, wanted, wantedUrl](vlc_medialibrary_t* ml, Ctx& ctx) {
        // the folders holding such media, by key
        QMap<QString, Folder> withMedia;
        vlc_ml_folder_list_t *list = vlc_ml_list_folders_by_type(ml, nullptr,
                                         audio ? VLC_ML_MEDIA_TYPE_AUDIO : VLC_ML_MEDIA_TYPE_VIDEO);
        if (list)
        {
            for (size_t i = 0; i < list->i_nb_items; ++i)
            {
                const vlc_ml_folder_t &f = list->p_items[i];
                if (!f.psz_mrl || f.b_banned)
                    continue;
                const QUrl url = QUrl::fromEncoded(f.psz_mrl);
                Folder entry;
                entry.url = url.toString(QUrl::FullyEncoded);
                if (!entry.url.endsWith(QLatin1Char('/')))
                    entry.url += QLatin1Char('/');
                entry.id = f.i_id;
                entry.count = audio ? f.i_nb_audio : f.i_nb_video;
                withMedia.insert(folderKey(url), entry);
            }
            vlc_ml_folder_list_release(list);
        }

        // the folders of the library
        QStringList roots;
        if (vlc_ml_folder_list_t *points = vlc_ml_list_entry_points(ml, nullptr))
        {
            for (size_t i = 0; i < points->i_nb_items; ++i)
            {
                if (points->p_items[i].psz_mrl && !points->p_items[i].b_banned)
                {
                    QString url = QUrl::fromEncoded(points->p_items[i].psz_mrl).toString(QUrl::FullyEncoded);
                    if (!url.endsWith(QLatin1Char('/')))
                        url += QLatin1Char('/');
                    roots.append(url);
                }
            }
            vlc_ml_folder_list_release(points);
        }

        // the subfolders of a folder holding such media (anywhere below)
        // with their counts, by key
        const auto children = [&](const QString &parentUrl) {
            QMap<QString, Folder> result;
            const QString parentKey = folderKey(QUrl(parentUrl));
            for (auto it = withMedia.cbegin(); it != withMedia.cend(); ++it)
            {
                if (!it.key().startsWith(parentKey) || it.key() == parentKey)
                    continue;
                // the first part after the parent
                const QString rest = it.value().url.mid(parentUrl.size());
                const QString part = rest.section(QLatin1Char('/'), 0, 0);
                if (part.isEmpty())
                    continue;
                const QString childUrl = parentUrl + part + QLatin1Char('/');
                Folder &child = result[folderKey(QUrl(childUrl))];
                child.url = childUrl;
                child.count += it.value().count;
            }
            return result;
        };

        const auto directCount = [&](const QString &url) -> unsigned {
            const auto it = withMedia.constFind(folderKey(QUrl(url)));
            return it != withMedia.cend() ? it->count : 0;
        };

        // the top: the folder of the library, or the folders when there are
        // several; a folder holding only one folder is skipped
        QString top;
        QStringList usedRoots;
        for (const QString &root : std::as_const(roots))
        {
            if (directCount(root) > 0 || !children(root).isEmpty())
                usedRoots.append(root);
        }
        if (usedRoots.size() == 1)
        {
            top = usedRoots.first();
            for (;;)
            {
                const auto sub = children(top);
                if (sub.size() != 1 || directCount(top) > 0)
                    break;
                top = sub.first().url;
            }
        }

        // the folder shown
        QString current = top;
        if (!wanted.isEmpty())
        {
            for (const QString &root : std::as_const(usedRoots))
            {
                if (wanted.startsWith(folderKey(QUrl(root))))
                {
                    // the library's spelling of the wanted folder
                    current = root + wantedUrl.mid(root.size());
                    break;
                }
            }
        }

        // its path from the top, for the header
        QVariantList crumbs;
        if (!current.isEmpty() && !top.isEmpty() && folderKey(QUrl(current)) != folderKey(QUrl(top))
            && folderKey(QUrl(current)).startsWith(folderKey(QUrl(top))))
        {
            QString url = top;
            const QStringList parts = current.mid(top.size()).split(QLatin1Char('/'), Qt::SkipEmptyParts);
            for (const QString &part : parts)
            {
                url += part + QLatin1Char('/');
                crumbs.append(QVariantMap {
                    { QStringLiteral("name"), QUrl::fromPercentEncoding(part.toUtf8()) },
                    { QStringLiteral("url"), QUrl::fromEncoded(url.toUtf8()) },
                });
            }
        }

        // its folders, by name
        QVariantList folders;
        QList<Folder> sub;
        if (current.isEmpty())
        {
            for (const QString &root : std::as_const(usedRoots))
            {
                Folder f;
                f.url = root;
                f.count = directCount(root);
                for (const Folder &c : children(root))
                    f.count += c.count;
                sub.append(f);
            }
        }
        else
        {
            sub = children(current).values();
        }
        QCollator collator;
        collator.setNumericMode(true);
        collator.setCaseSensitivity(Qt::CaseInsensitive);
        std::sort(sub.begin(), sub.end(), [&](const Folder &a, const Folder &b) {
            return collator.compare(folderName(a.url), folderName(b.url)) < 0;
        });
        for (const Folder &f : std::as_const(sub))
        {
            folders.append(QVariantMap {
                { QStringLiteral("name"), QUrl::fromPercentEncoding(folderName(f.url).toUtf8()) },
                { QStringLiteral("url"), QUrl::fromEncoded(f.url.toUtf8()) },
                { QStringLiteral("count"), f.count },
            });
        }

        // its media
        QVariantList media;
        qint64 folderId = -1;
        if (!current.isEmpty())
        {
            const auto it = withMedia.constFind(folderKey(QUrl(current)));
            if (it != withMedia.cend())
                folderId = it->id;
        }
        QHash<int64_t, QString> artists;
        const auto artistName = [&](int64_t id) -> QString {
            if (id <= 0)
                return QString();
            const auto it = artists.constFind(id);
            if (it != artists.cend())
                return *it;
            QString name;
            if (vlc_ml_artist_t *artist = vlc_ml_get_artist(ml, id))
            {
                name = qfu(artist->psz_name);
                vlc_ml_artist_release(artist);
            }
            artists.insert(id, name);
            return name;
        };

        if (folderId > 0)
        {
            vlc_ml_query_params_t params = vlc_ml_query_params_create();
            params.i_sort = VLC_ML_SORTING_FILENAME;
            if (vlc_ml_media_list_t *items = vlc_ml_list_folder_media(ml, &params, folderId))
            {
                for (size_t i = 0; i < items->i_nb_items; ++i)
                {
                    const vlc_ml_media_t &m = items->p_items[i];
                    if (m.i_type != (audio ? VLC_ML_MEDIA_TYPE_AUDIO : VLC_ML_MEDIA_TYPE_VIDEO))
                        continue;
                    const char *file = (m.p_files && m.p_files->i_nb_items > 0) ? m.p_files->p_items[0].psz_mrl : nullptr;
                    const QUrl mrl = QUrl::fromEncoded(file ? file : "");
                    const vlc_ml_thumbnail_t &thumbnail = m.thumbnails[VLC_ML_THUMBNAIL_SMALL];
                    media.append(QVariantMap {
                        { QStringLiteral("id"), QVariant::fromValue(MLItemId(m.i_id, VLC_ML_PARENT_UNKNOWN)) },
                        { QStringLiteral("url"), mrl },
                        { QStringLiteral("name"), QUrl::fromPercentEncoding(mrl.toString(QUrl::FullyEncoded).section(QLatin1Char('/'), -1).toUtf8()) },
                        { QStringLiteral("title"), qfu(m.psz_title) },
                        { QStringLiteral("thumbnail"), (thumbnail.i_status == VLC_ML_THUMBNAIL_STATUS_AVAILABLE && thumbnail.psz_mrl)
                                                       ? qfu(thumbnail.psz_mrl) : QString() },
                        { QStringLiteral("progress"), m.f_progress },
                        { QStringLiteral("playCount"), m.i_playcount },
                        { QStringLiteral("duration"), static_cast<qint64>(m.i_duration) },
                        { QStringLiteral("artist"), audio ? artistName(m.album_track.i_artist_id) : QString() },
                    });
                }
                vlc_ml_media_list_release(items);
            }
        }

        ctx.result = QVariantMap {
            { QStringLiteral("url"), current.isEmpty() ? QUrl() : QUrl::fromEncoded(current.toUtf8()) },
            { QStringLiteral("top"), top.isEmpty() ? QUrl() : QUrl::fromEncoded(top.toUtf8()) },
            { QStringLiteral("crumbs"), crumbs },
            { QStringLiteral("folders"), folders },
            { QStringLiteral("media"), media },
            // for the views of the library: the media of this folder (none
            // when it holds only folders)
            { QStringLiteral("parentId"), QVariant::fromValue(MLItemId(folderId > 0 ? folderId : INT64_MAX, VLC_ML_PARENT_FOLDER)) },
        };
    },
    [this, kind, folder](quint64, Ctx& ctx) {
        emit libraryFolderReady(kind, folder, ctx.result);
    });
}

void PlayerTweaks::requestFolderPreview(const QUrl &folder)
{
    if (folder.isEmpty() || !p_intf->p_mi || !p_intf->p_mi->getMediaLibrary())
        return;

    const QString key = folderKey(folder);

    struct Ctx {
        QStringList thumbnails;
        int count = 0;
    };
    p_intf->p_mi->getMediaLibrary()->runOnMLThread<Ctx>(this,
    [key](vlc_medialibrary_t* ml, Ctx& ctx) {
        // the folders with videos in it, by name
        QList<QPair<QString, int64_t>> folders;
        if (vlc_ml_folder_list_t *list = vlc_ml_list_folders_by_type(ml, nullptr, VLC_ML_MEDIA_TYPE_VIDEO))
        {
            for (size_t i = 0; i < list->i_nb_items; ++i)
            {
                const vlc_ml_folder_t &f = list->p_items[i];
                if (!f.psz_mrl || f.b_banned)
                    continue;
                const QString k = folderKey(QUrl::fromEncoded(f.psz_mrl));
                if (!k.startsWith(key))
                    continue;
                folders.append({ k, f.i_id });
                ctx.count += f.i_nb_video;
            }
            vlc_ml_folder_list_release(list);
        }
        std::sort(folders.begin(), folders.end());

        // four pictures at most, made when missing (shown the next time)
        for (const auto &folder : std::as_const(folders))
        {
            vlc_ml_query_params_t params = vlc_ml_query_params_create();
            params.i_sort = VLC_ML_SORTING_FILENAME;
            vlc_ml_media_list_t *items = vlc_ml_list_folder_media(ml, &params, folder.second);
            if (!items)
                continue;
            for (size_t i = 0; i < items->i_nb_items && ctx.thumbnails.size() < 4; ++i)
            {
                const vlc_ml_media_t &m = items->p_items[i];
                if (m.i_type != VLC_ML_MEDIA_TYPE_VIDEO)
                    continue;
                const vlc_ml_thumbnail_t &thumbnail = m.thumbnails[VLC_ML_THUMBNAIL_SMALL];
                if (thumbnail.i_status == VLC_ML_THUMBNAIL_STATUS_AVAILABLE && thumbnail.psz_mrl)
                    ctx.thumbnails.append(qfu(thumbnail.psz_mrl));
                else if (thumbnail.i_status == VLC_ML_THUMBNAIL_STATUS_MISSING)
                    vlc_ml_media_generate_thumbnail(ml, m.i_id, VLC_ML_THUMBNAIL_SMALL, 512, 320, 0.3);
            }
            vlc_ml_media_list_release(items);
            if (ctx.thumbnails.size() >= 4)
                break;
        }
    },
    [this, folder](quint64, Ctx& ctx) {
        emit folderPreviewReady(folder, ctx.thumbnails, ctx.count);
    });
}

QVariant PlayerTweaks::emptyFolder() const
{
    return QVariant::fromValue(MLItemId(INT64_MAX, VLC_ML_PARENT_FOLDER));
}
