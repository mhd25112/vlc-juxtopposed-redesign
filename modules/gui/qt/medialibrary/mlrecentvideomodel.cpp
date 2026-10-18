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

#include "mlrecentvideomodel.hpp"
#include "mlhelper.hpp"

// Ctor / dtor

MLRecentVideoModel::MLRecentVideoModel(QObject * parent) : MLVideoModel(parent)
{
    // the last watched first
    setSortOrder(Qt::DescendingOrder);
}

void MLRecentVideoModel::setInProgressOnly(bool value)
{
    if (m_inProgressOnly == value)
        return;
    m_inProgressOnly = value;
    emit inProgressOnlyChanged();
    emit resetRequested();
}

// Protected MLBaseModel implementation

std::unique_ptr<MLListCacheLoader>
MLRecentVideoModel::createMLLoader() const
/* override */
{
    return std::make_unique<MLListCacheLoader>(m_mediaLib, std::make_shared<MLRecentVideoModel::Loader>(*this));
}

// Private MLVideoModel reimplementation

void MLRecentVideoModel::onVlcMlEvent(const MLEvent & event) /* override */
{
    switch (event.i_type)
    {
        case VLC_ML_EVENT_HISTORY_CHANGED:
            emit resetRequested();
            return;
        default:
            break;
    }

    MLVideoModel::onVlcMlEvent(event);
}

// Loader

size_t MLRecentVideoModel::Loader::count(vlc_medialibrary_t* ml, const vlc_ml_query_params_t* queryParams) const /* override */
{
    if (!m_inProgressOnly)
        return vlc_ml_count_video_history(ml, queryParams);
    return list(ml, queryParams).size();
}

std::vector<std::unique_ptr<MLItem>>
MLRecentVideoModel::Loader::list(vlc_medialibrary_t* ml, const vlc_ml_query_params_t* queryParams) const
{
    // the whole history (it is short) when filtering, the page is cut after
    vlc_ml_query_params_t params = queryParams ? *queryParams : vlc_ml_query_params_t{};
    if (m_inProgressOnly)
    {
        params.i_nbResults = 0;
        params.i_offset = 0;
    }

    ml_unique_ptr<vlc_ml_media_list_t> media_list {
        vlc_ml_list_video_history(ml, &params)
    };

    if (media_list == nullptr)
        return {};

    std::vector<std::unique_ptr<MLItem>> res;

    for (const vlc_ml_media_t & media : ml_range_iterate<vlc_ml_media_t>(media_list))
    {
        // left part of the way: a position saved, not watched to the end
        if (m_inProgressOnly && !(media.f_progress > 0. && media.f_progress < 0.95))
            continue;
        res.emplace_back( std::make_unique<MLVideo>(&media));
    }

    return res;
}

std::vector<std::unique_ptr<MLItem>>
MLRecentVideoModel::Loader::load(vlc_medialibrary_t* ml, const vlc_ml_query_params_t* queryParams) const /* override */
{
    auto res = list(ml, queryParams);
    if (!m_inProgressOnly || queryParams == nullptr)
        return res;

    // the page asked for
    const size_t offset = std::min<size_t>(queryParams->i_offset, res.size());
    const size_t end = queryParams->i_nbResults == 0 ? res.size()
                                                     : std::min<size_t>(offset + queryParams->i_nbResults, res.size());
    std::vector<std::unique_ptr<MLItem>> page;
    for (size_t i = offset; i < end; ++i)
        page.push_back(std::move(res[i]));
    return page;
}

std::unique_ptr<MLItem>
MLRecentVideoModel::Loader::loadItemById(vlc_medialibrary_t* ml, MLItemId itemId) const
{
    assert(itemId.type == VLC_ML_PARENT_UNKNOWN);
    ml_unique_ptr<vlc_ml_media_t> media(vlc_ml_get_media(ml, itemId.id));
    if (!media)
        return nullptr;
    return std::make_unique<MLVideo>(media.get());
}
