import QtQuick

// Caelestia-style SDDM greeter: Material palette + wallpaper + font all come
// from theme.conf, which sddm-theme-sync regenerates from the desktop's live
// caelestia scheme (~/.local/state/caelestia/scheme.json). Pure QtQuick — no
// QtQuick.Controls styles, no SddmComponents — so there is nothing to break.
Item {
    id: root

    property int sessionIndex: sessionModel.lastIndex
    property var sessionNames: ({})
    property string sessionName: ""

    // Gaming Mode is entered from the DESKTOP only (Super+Shift+S → DeckShift
    // switch); logging into the gamescope session from the greeter would
    // bypass that flow entirely. Hide gamescope sessions from the cycler, and
    // never preselect one (SDDM remembers the last session, which is a
    // gamescope session after a reboot from Gaming Mode).
    // Hidden: all gamescope sessions ("Gaming Mode (ChimeraOS)", "Steam Big
    // Picture" x2) — Gaming Mode is desktop-only (Super+Shift+S) — and the
    // plain "Hyprland" session, which loses the uwsm-managed environment the
    // caelestia shell needs (a shell-less desktop is all you'd get).
    function isAllowed(i) {
        var n = sessionNames[i]
        return n !== undefined && n !== "Hyprland" && !/gam(ing|escope)|steam|big picture/i.test(n)
    }

    function allowedCount() {
        var total = 0
        for (var i in sessionNames)
            if (isAllowed(parseInt(i)))
                total++
        return total
    }

    function nextAllowed(from) {
        var count = sessionModel.rowCount()
        for (var step = 1; step <= count; step++) {
            var i = (from + step) % count
            if (isAllowed(i))
                return i
        }
        return from
    }

    function refreshSessionName() {
        if (sessionNames[sessionIndex] !== undefined && !isAllowed(sessionIndex))
            sessionIndex = nextAllowed(sessionIndex)
        sessionName = sessionNames[sessionIndex] !== undefined ? sessionNames[sessionIndex] : "Default"
    }

    function tryLogin() {
        errorText.text = ""
        sddm.login(userInput.text, passInput.text, sessionIndex)
    }

    // The exact font the desktop shell uses (Google Sans Flex, bundled inside
    // the caelestia shell tree); falls back to the configured family (Rubik).
    FontLoader {
        id: uiFont
        source: config.fontFile ? "file://" + config.fontFile : ""
    }
    property string fontFamily: uiFont.status === FontLoader.Ready ? uiFont.name : config.fontFallback

    // Invisible probe to collect session display names from sessionModel.
    Repeater {
        model: sessionModel
        delegate: Item {
            visible: false
            Component.onCompleted: {
                root.sessionNames[index] = name
                root.refreshSessionName()
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "Incorrect password — try again"
            passInput.text = ""
            passInput.forceActiveFocus()
        }
    }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.32
        }
    }

    // Clock
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
        spacing: 4

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 96
            font.weight: Font.Light
            color: config.text
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.fontFamily
            font.pixelSize: 20
            color: config.subtext
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            clock.text = Qt.formatTime(new Date(), "HH:mm")
            dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }

    // Login card
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.42
        width: 380
        height: cardColumn.height + 48
        radius: 24
        color: config.surfaceContainer
        opacity: 0.96

        Column {
            id: cardColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48
            spacing: 14

            // Username
            Rectangle {
                width: parent.width
                height: 48
                radius: 16
                color: config.surfaceContainerHigh
                border.color: userInput.activeFocus ? config.primary : config.outline
                border.width: 1

                TextInput {
                    id: userInput
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    color: config.text
                    selectionColor: config.primary
                    selectedTextColor: config.onPrimary
                    text: userModel.lastUser
                    clip: true
                    KeyNavigation.tab: passInput
                }
            }

            // Password
            Rectangle {
                width: parent.width
                height: 48
                radius: 16
                color: config.surfaceContainerHigh
                border.color: passInput.activeFocus ? config.primary : config.outline
                border.width: 1

                TextInput {
                    id: passInput
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: config.text
                    selectionColor: config.primary
                    selectedTextColor: config.onPrimary
                    clip: true
                    focus: true
                    KeyNavigation.tab: userInput
                    onAccepted: root.tryLogin()
                }
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    verticalAlignment: Text.AlignVCenter
                    visible: passInput.text.length === 0 && !passInput.activeFocus
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    color: config.subtext
                    text: "Password"
                }
            }

            Text {
                id: errorText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: text.length > 0
                font.family: root.fontFamily
                font.pixelSize: 14
                color: config.error
                text: ""
                wrapMode: Text.Wrap
            }

            // Login button
            Rectangle {
                width: parent.width
                height: 48
                radius: 16
                color: loginArea.pressed ? Qt.darker(config.primary, 1.15) : config.primary

                Text {
                    anchors.centerIn: parent
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: config.onPrimary
                    text: "Log in"
                }
                MouseArea {
                    id: loginArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tryLogin()
                }
            }

            // Session cycler (hidden when only one session is selectable)
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                // referencing sessionName makes the binding re-evaluate as
                // the session list is populated
                visible: root.sessionName !== "" && root.allowedCount() > 1
                font.family: root.fontFamily
                font.pixelSize: 13
                color: sessionArea.containsMouse ? config.text : config.subtext
                text: "Session: " + root.sessionName + "  ⟳"

                MouseArea {
                    id: sessionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionIndex = root.nextAllowed(root.sessionIndex)
                        root.refreshSessionName()
                    }
                }
            }
        }
    }

    // Power controls
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 24

        Repeater {
            model: [
                { label: "Sleep",    enabled: sddm.canSuspend,  act: function() { sddm.suspend() } },
                { label: "Restart",  enabled: sddm.canReboot,   act: function() { sddm.reboot() } },
                { label: "Shut down", enabled: sddm.canPowerOff, act: function() { sddm.powerOff() } }
            ]
            delegate: Text {
                visible: modelData.enabled
                font.family: root.fontFamily
                font.pixelSize: 14
                color: powerArea.containsMouse ? config.text : config.subtext
                text: modelData.label

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.act()
                }
            }
        }
    }

    Component.onCompleted: passInput.forceActiveFocus()
}
