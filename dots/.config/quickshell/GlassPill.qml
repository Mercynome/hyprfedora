import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes
Item {
    id: pill

    // ── Public API ──
    property int innerPadding: 16
    property bool enableHover: true
    property int radius: 20

    // ── Hover Detection ──
    HoverHandler {
        id: hoverHandler
        enabled: pill.enableHover
    }
    property bool hovered: hoverHandler.hovered

    // ── Fluid Dynamics ──
    z: hovered ? 1 : 0
    scale: hovered ? 1.03 : 1.0

    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    // ── Fluid Colors ──
    property color baseColor: hovered ? "#4DFFFFFF" : "#26FFFFFF"
    property color topGlow: hovered ? "#99FFFFFF" : "#66FFFFFF"
    property color borderColor: hovered ? "#80FFFFFF" : "#33FFFFFF"
    Behavior on baseColor { ColorAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on topGlow { ColorAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on borderColor { ColorAnimation { duration: 400; easing.type: Easing.OutExpo } }

    // ── Liquid Glass Surface (Absolute Perfection) ──
    // 1. The Solid Base
    // Provides a uniform alpha > 0.1 across the ENTIRE pill (including the 2px gap),
    // ensuring Hyprland's blur covers the whole shape perfectly without gaps.
    Rectangle {
        anchors.fill: parent
        radius: pill.radius
        color: pill.baseColor
        antialiasing: true
    }

    // 2. The Gradient Glow (Inset by 2px)
    // Its anti-aliased edge blends perfectly over the flat interior of the base,
    // avoiding any curve-on-curve alpha multiplication artifacts.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: pill.radius - 2
        antialiasing: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: pill.topGlow }
            GradientStop { position: 0.3; color: "#00FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
    }

    // 3. The Border Overlay
    // Matches the Solid Base bounds exactly, synchronizing their anti-aliasing math.
    Rectangle {
        anchors.fill: parent
        radius: pill.radius
        color: "transparent"
        border.color: pill.borderColor
        border.width: 1
        antialiasing: true
    }

    // ── Content Container ──
    default property alias content: contentItem.data

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.leftMargin: pill.innerPadding
        anchors.rightMargin: pill.innerPadding
    }
}
