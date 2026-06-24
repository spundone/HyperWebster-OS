pragma ComponentBehavior: Bound

// HyperWebster Notifications popout (off the bell). Header (count + DND + Clear),
// scrollable cards (tinted icon, title, body, time), empty state. Uses Notifs.

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.utils
import qs.components

NsPanel {
    id: root

    implicitWidth: 380
    anchorMode: "right"

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: "Notifications"
            color: Theme.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.panelTitle
            font.weight: Font.DemiBold
        }

        StyledText {
            text: "· " + Notifs.notClosed.length + " new"
            color: Theme.textFaint
            font.family: Theme.font.family
            font.pixelSize: Theme.font.bodySmall
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            radius: 0
            color: Notifs.dnd ? Theme.accentSoft : dndMa.containsMouse ? Theme.hover : "transparent"

            NsIcon {
                anchors.centerIn: parent
                icon: Notifs.dnd ? "do_not_disturb_on" : "dark_mode"
                color: Notifs.dnd ? Theme.accent : Theme.textMuted
            }

            MouseArea {
                id: dndMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.dnd = !Notifs.dnd
            }
        }

        StyledText {
            text: "Clear"
            color: clearMa.containsMouse ? Theme.accent : Theme.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.bodySmall

            MouseArea {
                id: clearMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Mirror the service's own clear() / clearNotifs shortcut:
                    // NotifData.close() sets `closed` (drops it from notClosed so the
                    // card disappears), removes it from Notifs.list, dismisses the
                    // server notification and destroys it. Calling
                    // `notification?.dismiss()` directly cleared nothing — it never
                    // touched the list, and is a no-op for notifications restored from
                    // disk (their `notification` is null). Iterate a slice() copy so
                    // mutating the list mid-loop is safe.
                    for (const n of Notifs.list.slice())
                        n.close();
                }
            }
        }
    }

    // cards
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: Notifs.notClosed

            delegate: Rectangle {
                id: card

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: cardRow.implicitHeight + 20
                radius: Theme.radius.button
                color: Theme.fillSubtle

                RowLayout {
                    id: cardRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 0
                        color: Theme.accentSoft

                        NsIcon {
                            anchors.centerIn: parent
                            icon: Icons.getNotifIcon(card.modelData?.summary ?? "", card.modelData?.urgency ?? 1)
                            color: Theme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData?.summary ?? ""
                                color: Theme.text
                                elide: Text.ElideRight
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.bodySmall
                                font.weight: Font.Medium
                            }
                            StyledText {
                                text: card.modelData?.timeStr ?? ""
                                color: Theme.textFaint
                                font.family: Theme.font.family
                                font.pixelSize: Theme.font.meta
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.modelData?.body ?? ""
                            color: Theme.textMuted
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.family: Theme.font.family
                            font.pixelSize: Theme.font.meta
                        }
                    }
                }
            }
        }

        StyledText {
            visible: Notifs.notClosed.length === 0
            Layout.topMargin: 6
            text: "No notifications"
            color: Theme.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.bodySmall
        }
    }
}
