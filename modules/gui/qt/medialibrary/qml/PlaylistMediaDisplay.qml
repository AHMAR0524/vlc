/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * Authors: Benjamin Arnaud <bunjee@omega.gg>
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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12

import org.videolan.medialib 0.1
import org.videolan.vlc 0.1

import "qrc:///widgets/" as Widgets
import "qrc:///main/" as MainInterface
import "qrc:///util/" as Util
import "qrc:///style/"

FocusScope {
    id: root

    // Properties

    readonly property bool hasGridListMode: false

    property int leftPadding: 0
    property int rightPadding: 0

    readonly property int currentIndex: view.currentIndex
    property string name: ""

    property int initialIndex: 0

    property alias header: view.header
    property Item headerItem: view.headerItem

    property bool isMusic: true
    property string _placeHolder: isMusic ? VLCStyle.noArtAlbumCover : VLCStyle.noArtVideoCover


    // Aliases

    // NOTE: This is used to determine which media(s) shall be displayed.
    property alias parentId: model.parentId

    property alias model: model

    property alias dragItem: dragItem

    // Events

    onModelChanged: resetFocus()

    onInitialIndexChanged: resetFocus()

    // Functions

    function setCurrentItemFocus(reason) { view.setCurrentItemFocus(reason); }

    function resetFocus() {
        const count = model.count

        if (count === 0 || initialIndex === -1) return

        var index

        if (initialIndex < count)
            index = initialIndex
        else
            index = 0

        modelSelect.select(model.index(index, 0), ItemSelectionModel.ClearAndSelect)

        view.positionViewAtIndex(index, ItemView.Contain)

        view.setCurrentItem(index)
    }

    // Events

    function onDelete()
    {
        const indexes = modelSelect.selectedIndexes;

        if (indexes.length === 0)
            return;

        model.remove(indexes);
    }

    // Childs

    MLPlaylistModel {
        id: model

        ml: MediaLib

        onCountChanged: {
            // NOTE: We need to cancel the Drag item manually when resetting. Should this be called
            //       from 'onModelReset' only ?
            dragItem.Drag.cancel();

            if (count === 0 || modelSelect.hasSelection)
                return;

            resetFocus();
        }
    }

    Widgets.MLDragItem {
        id: dragItem

        mlModel: model

        indexes: modelSelect.selectedIndexes

        coverRole: "thumbnail"

        defaultCover: root._placeHolder
    }

    Util.SelectableDelegateModel {
        id: modelSelect

        model: root.model
    }

    PlaylistMediaContextMenu {
        id: contextMenu

        model: root.model
    }

    PlaylistMedia
    {
        id: view

        // Settings

        anchors.fill: parent

        clip: true

        focus: (model.count !== 0)

        model: root.model

        selectionDelegateModel: modelSelect

        dragItem: root.dragItem

        isMusic: root.isMusic

        header: Widgets.SubtitleLabel {
            id: label

            leftPadding: view.contentLeftMargin
            rightPadding: view.contentRightMargin
            topPadding: VLCStyle.margin_normal
            bottomPadding: VLCStyle.margin_xsmall

            text: root.name
            color: view.colorContext.fg.primary
        }


        headerTopPadding: VLCStyle.margin_normal

        Navigation.parentItem: root

        Navigation.cancelAction: function () {
            if (view.currentIndex <= 0) {
                root.Navigation.defaultNavigationCancel()
            } else {
                positionViewAtIndex(0, ItemView.Contain)

                setCurrentItem(0)
            }
        }

        // Events

        onContextMenuButtonClicked: contextMenu.popup(modelSelect.selectedIndexes,
                                                      globalMousePos)

        onRightClick: contextMenu.popup(modelSelect.selectedIndexes, globalMousePos)

        // Keys

        Keys.onDeletePressed: onDelete()
    }

    Widgets.EmptyLabelButton {
        anchors.fill: parent

        visible: !model.loading && (model.count <= 0)

        focus: visible

        text: I18n.qtr("No media found")

        cover: root._placeHolder

        Navigation.parentItem: root
    }
}
