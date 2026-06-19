import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// ════════════════════════════════════════════════════════════
//  OSD OVERLAY — Liquid Glass On-Screen Display
//  Ses ve parlaklık değişimlerini ekranın alt ortasında gösterir
// ════════════════════════════════════════════════════════════
PanelWindow {
    id: osdWindow

    anchors {
        bottom: true
        left: true
        right: true
    }

    height: 100
    color: "transparent"

    WlrLayershell.namespace: "osd_overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0

    // ── OSD State ──
    property string osdType: ""    // "volume", "brightness", "mute"
    property int osdValue: 0
    property bool osdMuted: false
    property bool osdVisible: false

    // ── File Watcher: /tmp/qs_osd trigger dosyasını izler ──
    Process {
        id: osdReader
        command: ["cat", "/tmp/qs_osd"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var eq = lines[i].indexOf("=");
                    if (eq > 0) {
                        var key = lines[i].substring(0, eq);
                        var val = lines[i].substring(eq + 1);
                        if      (key === "type")  osdWindow.osdType = val;
                        else if (key === "value") osdWindow.osdValue = parseInt(val) || 0;
                        else if (key === "muted") osdWindow.osdMuted = (val === "true");
                    }
                }
                osdWindow.osdVisible = true;
                hideTimer.restart();
            }
        }
    }

    // ── Trigger Watcher: Her 150ms'de dosya değişikliği kontrol ──
    Process {
        id: triggerWatcher
        command: ["sh", "-c", "cat /tmp/qs_osd_trigger 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var newVal = text.trim();
                if (newVal !== "" && newVal !== lastTrigger) {
                    lastTrigger = newVal;
                    osdReader.running = true;
                }
            }
        }
        property string lastTrigger: ""
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: triggerWatcher.running = true
    }

    // ── Auto-Hide Timer ──
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: osdWindow.osdVisible = false
    }

    // ════════════════════════════════════════
    //  OSD PILL — Alt Ortada Görünen Gösterge
    // ════════════════════════════════════════
    Item {
        id: osdContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: osdWindow.osdVisible ? 24 : 0
        width: 280
        height: 56
        opacity: osdWindow.osdVisible ? 1.0 : 0.0
        scale: osdWindow.osdVisible ? 1.0 : 0.85

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        // ── Glass Background ──
        Rectangle {
            anchors.fill: parent
            radius: 28
            color: "#33FFFFFF"
            antialiasing: true
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 26
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#80FFFFFF" }
                GradientStop { position: 0.3; color: "#00FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: 28
            color: "transparent"
            border.color: "#40FFFFFF"
            border.width: 1
            antialiasing: true
        }

        // ── Content Row ──
        Row {
            anchors.centerIn: parent
            spacing: 14

            // İkon
            Text {
                id: osdIcon
                text: {
                    if (osdWindow.osdType === "brightness") return "\uf185";  // sun
                    if (osdWindow.osdMuted) return "\uf6a9";                 // volume-mute
                    var v = osdWindow.osdValue;
                    if (v === 0) return "\uf026";                            // volume-off
                    if (v < 50) return "\uf027";                             // volume-low
                    return "\uf028";                                         // volume-high
                }
                font.family: "Font Awesome 6 Free"
                font.weight: 900
                font.pixelSize: 18
                color: {
                    if (osdWindow.osdMuted) return "#80FFFFFF";
                    if (osdWindow.osdType === "brightness") return "#F9E2AF";
                    return "#FFFFFF";
                }
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                horizontalAlignment: Text.AlignHCenter

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Progress Bar
            Item {
                width: 160
                height: 6
                anchors.verticalCenter: parent.verticalCenter

                // Track (arka plan)
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: "#20FFFFFF"
                    antialiasing: true
                }

                // Fill (doluluk)
                Rectangle {
                    width: parent.width * (osdWindow.osdValue / 100)
                    height: parent.height
                    radius: 3
                    antialiasing: true
                    color: {
                        if (osdWindow.osdMuted) return "#60FFFFFF";
                        if (osdWindow.osdType === "brightness") return "#F9E2AF";
                        return "#FFFFFF";
                    }

                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // Yüzde Yazısı
            Text {
                text: osdWindow.osdMuted ? "Mute" : osdWindow.osdValue + "%"
                font.pixelSize: 14
                font.bold: true
                color: "#E6FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
