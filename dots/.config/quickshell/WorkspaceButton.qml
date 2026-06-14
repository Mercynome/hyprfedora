import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root

    property int workspaceId: 1
    property bool isActive: false
    property bool isUrgent: false

    width: 30
    height: 30
    radius: 15
    antialiasing: true

    // ── Fluid Color State ──
    color: {
        if (isUrgent)  return "#CCF7768E"
        if (mouseArea.containsMouse) return "#1AFFFFFF"
        return "transparent"
    }

    Behavior on color {
        ColorAnimation { duration: 400; easing.type: Easing.OutExpo }
    }

    // ── Hover Bounce ──
    scale: mouseArea.containsMouse ? 1.10 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
    }

    // ── Number Label ──
    Text {
        anchors.centerIn: parent
        text: root.workspaceId
        color: root.isActive ? "#FFFFFF" : (mouseArea.containsMouse ? "#CCFFFFFF" : "#80FFFFFF")
        font.pixelSize: 13
        font.bold: true
        // font.family: "Noto Sans"

        Behavior on color {
            ColorAnimation { duration: 400; easing.type: Easing.OutExpo }
        }
    }

    // ── Interaction ──
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + root.workspaceId)
    }
}
