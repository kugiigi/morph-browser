/*
 * Copyright 2014-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3
import QtQml.Models 2.2

Item {
    id: tabslist

    property real delegateHeight
    property real chromeHeight
    property alias model: filteredModel.model
    property alias searchText: searchField.text
    property alias view: list.item
    readonly property int count: model.count
    property bool incognito
    property bool search: false

    signal scheduleTabSwitch(int index)
    signal tabSelected(int index)
    signal tabClosed(int index)

    function reset() {
        list.item.contentY = 0
        searchText = ""
    }

    readonly property bool animating: selectedAnimation.running

    TabChrome {
        id: invisibleTabChrome
        visible: false
    }

    Rectangle {
        id: backrect
        width: parent.width
        height: delayBackground.running ? invisibleTabChrome.height : parent.height
        color: theme.palette.normal.base
        visible: !browser.wide
    }
    onVisibleChanged: {
        if (visible) {
            delayBackground.start()
            
            if (browser.wide) {
                search = true
            } else {
                search = false
            }
        } else {
            if (browser.wide) {
                list.item.focus = false
            }
        }
            
    }

    Timer {
        id: delayBackground
        interval: 300
    }
    
    function focusInput() {
        search = true
        searchField.selectAll();
        searchField.forceActiveFocus()
    }
    
    function selectFirstItem() {
        var firstItem = visibleGroup.get(0)
        if (browser.wide) {
            tabslist.selectAndAnimateTab(firstItem.itemsIndex, firstItem.index)
        } else {
            tabslist.tabSelected(firstItem.itemsIndex)
        }
    }
    
    
    Loader {
        id: flickableLoader
        
        readonly property real expansionThreshold: units.gu(15)
        
        active: list.item && !browser.wide
        asynchronous: true
        sourceComponent: Connections{
            target: list.item
            
            onVerticalOvershootChanged: {
                if(target.verticalOvershoot < 0){
                    if(-target.verticalOvershoot >= expansionThreshold){
                        tabslist.search = true
                        tabslist.focusInput()
                    }
                }
            }
        }
    }  
    
    Rectangle {
        id: searchRec
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(6)
        color: browser.wide ? "transparent" : theme.palette.normal.background
        opacity: tabslist.search ? 1 : list.item.verticalOvershoot < 0 ? -list.item.verticalOvershoot / height : 0


        Behavior on opacity {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.FastDuration
            }
        }
        
        TextField {
            id: searchField
            
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }

            placeholderText: i18n.tr("Search Tabs")
            primaryItem: Icon {
                height: parent.height * 0.5
                width: height
                name: "search"
            }
            
            onTextChanged: searchDelay.restart()
            KeyNavigation.down: list.item
            onAccepted: tabslist.selectFirstItem()
            
            Timer {
                id: searchDelay
                interval: 300
                onTriggered: filteredModel.update(searchField.text)
            }
        }
    }
    
    Loader {
        id: list
        asynchronous: true
        anchors.fill: parent
        anchors.topMargin: tabslist.search ? searchRec.height : 0
        
        Behavior on anchors.topMargin {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.FastDuration
            }
        }
        sourceComponent: browser.wide ? listWideComponent : listNarrowComponent
    }
    
    Label {
        id: resultsLabel
        
        text: searchDelay.running ? i18n.tr("Loading...") : i18n.tr("No results")
        textSize: Label.Large
        font.weight: Font.DemiBold
        color: browser.wide ? UbuntuColors.porcelain : theme.palette.normal.baseText
        anchors {
            top: searchRec.bottom
            horizontalCenter: parent.horizontalCenter
            margins: units.gu(3)
        }
        visible: filteredModel.count == 0
    }
    
    DelegateModel {
        id: filteredModel
        
        function update(searchText) {
            if (items.count > 0) {
                items.setGroups(0, items.count, ["items"]);
            }
            
            if (searchText) {
                filterOnGroup = "visible"
                var visible = [];
                var searchTextUpper = searchText.toUpperCase()
                var titleUpper
                var urlUpper
                
                for (var i = 0; i < items.count; ++i) {
                    var item = items.get(i);
                    titleUpper = item.model.title.toUpperCase()
                    urlUpper = item.model.url.toString().toUpperCase()
                    if (titleUpper.indexOf(searchTextUpper) > -1 || urlUpper.indexOf(searchTextUpper) > -1 ) {
                        visible.push(item);
                    }
                }

                for (i = 0; i < visible.length; ++i) {
                    item = visible[i];
                    item.inVisible = true;
                }
            } else {
                filterOnGroup = "items"
            }
        }

        groups: [
            DelegateModelGroup {
                id: visibleGroup
                name: "visible"
                includeByDefault: false
            }
        ]

        delegate: Package {
            id: packageDelegate
            
            Item {
                id: gridDelegate
                
                Package.name: "grid"
                
                property int tabIndex: index
                
                width: tabslist.view.cellWidth
                height: tabslist.view.cellHeight
                clip: true

                TabPreview {
                    
                    title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                    icon: model.icon
                    incognito: tabslist.incognito
                    tab: model.tab
                    
                    anchors.fill: parent
                    anchors.margins: units.gu(1)

                    onSelected: tabslist.tabSelected(index)
                    onClosed: tabslist.tabClosed(index)
                }
            }
            
            Loader {
                id: listDelegate

                property int groupIndex: filteredModel.filterOnGroup === "visible" ? packageDelegate.DelegateModel.visibleIndex : index
                
                Package.name: "list"
                asynchronous: true

                width: list.item.contentWidth

                height: list.item.height

                y: Math.max(list.item.contentY, groupIndex * delegateHeight)
                Behavior on y {
                    enabled: !list.item.moving && !selectedAnimation.running
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.BriskDuration
                    }
                }

                opacity: selectedAnimation.running && (groupIndex > selectedAnimation.listIndex) ? 0 : 1
                Behavior on opacity {
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.FastDuration
                    }
                }

                readonly property string title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                readonly property string icon: model.icon

                active: (groupIndex >= 0) && ((list.item.contentY + list.item.height + delegateHeight / 2) >= (groupIndex * delegateHeight))

                visible: list.item.contentY < ((groupIndex + 1) * delegateHeight)

                sourceComponent: TabPreview {
                    title: listDelegate.title
                    icon: listDelegate.icon
                    incognito: tabslist.incognito
                    tab: model.tab

                  /*  Binding {
                        // Change the height of the location bar controller
                        // for the first webview only, and only while the tabs
                        // list view is visible.
                        when: tabslist.visible && (index == 0)
                        target: tab && tab.webview ? tab.webview.locationBarController : null
                        property: "height"
                        value: invisibleTabChrome.height
                    } */

                    onSelected: tabslist.selectAndAnimateTab(index, groupIndex)
                    onClosed: tabslist.tabClosed(index)
                }
            }
        }
    }
    
    Component {
        id: listWideComponent
        
        GridView {
            id: gridView
            
            property int columnCount: switch (true) {
                case tabslist.width >= units.gu(100):
                    3
                    break;
                case tabslist.width >= units.gu(60):
                    2
                    break;
                default:
                    1
                    break;
            }
            
            clip: true
            model: filteredModel.parts.grid
            cellWidth: (tabslist.width) / columnCount
            cellHeight: cellWidth * (tabslist.height / tabslist.width)
            highlight: Component {
                Item {
                    z: 10
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                    opacity: 0.4
                    visible: gridView.activeFocus
                    
                    Rectangle {
                        anchors.fill: parent
                        color: theme.palette.normal.focus
                    }
                }
            }
            
            Keys.onEnterPressed: tabslist.tabSelected(currentItem.tabIndex)
            Keys.onReturnPressed: tabslist.tabSelected(currentItem.tabIndex)
        }
    }

    Component {
        id: listNarrowComponent

        Flickable {
            id: flickable

            anchors.fill: parent

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.DragOverBounds //StopAtBounds

            contentWidth: width
            contentHeight: filteredModel ? (filteredModel.count - 1) * delegateHeight + height : 0
            
            onVisibleChanged: {
                // WORKAROUND: Repeater items stay hidden when switching from wide to narrow layout
                // only if the model is direcly assigned. This solves that issue.
                if (visible) {
                    repeater.model = filteredModel.parts.list
                }
            }
            
            Repeater {
                id: repeater
            }
        }
    }
    
    Timer {
        id: delayedTabSelection
        interval: 1
        property int index: 0
        onTriggered: tabslist.tabSelected(index)
    }
    
    PropertyAnimation {
        id: selectedAnimation
        property int tabIndex: 0
        property int listIndex: 0
        target: list.item
        property: "contentY"
        to: listIndex * delegateHeight
        duration: UbuntuAnimation.FastDuration
        onStopped: {
            // Delay switching the tab until after the animation has completed.
            delayedTabSelection.index = tabIndex
            delayedTabSelection.start()
        }
    }

    function selectAndAnimateTab(tabIndex, listIndex) {
        // Animate tab into full view
        if (tabIndex == 0) {
            tabSelected(0)
        } else {
            selectedAnimation.tabIndex = tabIndex
            selectedAnimation.listIndex = listIndex ? listIndex : tabIndex
            scheduleTabSwitch(tabIndex)
            selectedAnimation.start()
        }
    }
}
