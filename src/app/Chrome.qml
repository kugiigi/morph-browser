/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import "actions" as Actions

Item {
    id: chrome

    property alias url: addressBar.actualUrl
    signal urlValidated(url url)
    property alias addressBar: addressBar
    property string title
    property alias loading: addressBar.loading
    property alias loadProgress: progressBar.value
    property alias canGoBack: backButton.enabled
    signal goBackClicked()
    property alias canGoForward: forwardButton.enabled

    property bool backForwardButtonsVisible: true
    property bool activityButtonVisible: true
    property bool addressBarVisible: true

    signal goForwardClicked()
    signal requestReload()
    signal requestStop()
    signal toggleTabsClicked()

    QtObject {
        id: internal
        // Arbitrary threshold for narrow screens.
        readonly property bool isNarrow: width < units.gu(55)
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: 0.95
    }

    ToolbarButton {
        id: backButton
        objectName: "backButton"
        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        // On narrow screens, hide the button to maximize the
        // address bar’s real estate when it has active focus.
        width: (internal.isNarrow && addressBar.activeFocus) ? 0 : units.gu(5)
        Behavior on width {
            UbuntuNumberAnimation {}
        }
        height: units.gu(5)
        clip: true
        iconSource: "assets/go-previous.png"
        text: i18n.tr("Back")
        onTriggered: chrome.goBackClicked()
        visible: backForwardButtonsVisible
    }

    ToolbarButton {
        id: forwardButton
        objectName: "forwardButton"
        anchors {
            left: backButton.right
            leftMargin: visible ? units.gu(1) : 0
            verticalCenter: parent.verticalCenter
        }
        // On narrow screen, hide the button to maximize
        // the address bar’s real estate.
        visible: !internal.isNarrow && backForwardButtonsVisible
        width: visible ? units.gu(5) : 0
        height: units.gu(5)
        iconSource: "assets/go-next.png"
        text: i18n.tr("Forward")
        onTriggered: chrome.goForwardClicked()
    }

    Component {
        id: addressBarPopover
        ActionSelectionPopover {
            actions: ActionList {
                Actions.ShareLink {
                    onTriggered: shareLoader.item.shareLink(chrome.url, chrome.title)
                }    
            }
        }
    }

    Item {
        id: addressBarPopOverPositioner
        anchors.bottom: addressBar.top
        anchors.horizontalCenter: addressBar.horizontalCenter
        visible: false
    }

    Loader {
        id: shareLoader
        source: formFactor == "desktop" ? "" : "Share.qml"
    }

    AddressBar {
        id: addressBar
        objectName: "addressBar"

        anchors {
            left: forwardButton.right
            leftMargin: units.gu(1)
            right: activityButton.left
            rightMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }

        onValidated: chrome.urlValidated(requestedUrl)
        onRequestReload: chrome.requestReload()
        onRequestStop: chrome.requestStop()
        onPressAndHold: {
            if (chrome.url && shareLoader.status == Loader.Ready) {
                PopupUtils.open(addressBarPopover, addressBarPopOverPositioner)
            }
        }
        visible: addressBarVisible
    }

    ToolbarButton {
        id: activityButton
        objectName: "activityButton"

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: units.gu(2)
        }
        width: units.gu(5)
        height: width

        iconSource: "assets/browser-tabs.png"
        text: i18n.tr("Activity")

        onTriggered: chrome.toggleTabsClicked()
        visible: activityButtonVisible
    }

    EmbeddedProgressBar {
        id: progressBar
        visible: chrome.loading && addressBarVisible
        source: visible ? addressBar : null
        minimumValue: 0
        maximumValue: 100
        bgColor: UbuntuColors.orange
        fgColor: "white"
    }

    Image {
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        fillMode: Image.TileHorizontally
        source: "assets/toolbar_dropshadow.png"
    }

    onUrlValidated: chrome.forceActiveFocus()
}
