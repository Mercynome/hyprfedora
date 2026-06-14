import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    PanelWindow {
        id: topBar

        anchors {
            top: true
            left: true
            right: true
        }

        height: 48
        color: "transparent"

        WlrLayershell.namespace: "quickshell"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: 48

        // ════════════════════════════════════════
        //  MAIN CONTENT AREA
        // ════════════════════════════════════════
        Item {
            id: bar
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 5

            // ── Live Data Properties ──
            property string cpuVal: "--"
            property string memVal: "--"
            property string tempVal: ""
            property string volVal: "--"
            property string volMuted: "false"
            property string micVal: "--"
            property string micMuted: "false"
            property string netInfo: ""
            property string netType: ""
            property string netDown: ""
            property string netUp: ""
            property string batVal: ""
            property string batStatus: ""
            property string musicText: ""
            property string musicStatus: ""

            // ── Stats Parser ──
            Process {
                id: statsProc
                command: ["cat", "/tmp/qs_stats.txt"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        var lines = text.trim().split("\n");
                        for (var i = 0; i < lines.length; i++) {
                            var eq = lines[i].indexOf("=");
                            if (eq > 0) {
                                var key = lines[i].substring(0, eq);
                                var val = lines[i].substring(eq + 1);
                                if      (key === "cpu")          bar.cpuVal = val;
                                else if (key === "mem")          bar.memVal = val;
                                else if (key === "temp")         bar.tempVal = val;
                                else if (key === "vol")          bar.volVal = val;
                                else if (key === "vol_muted")    bar.volMuted = val;
                                else if (key === "mic")          bar.micVal = val;
                                else if (key === "mic_muted")    bar.micMuted = val;
                                else if (key === "net")          bar.netInfo = val;
                                else if (key === "net_type")     bar.netType = val;
                                else if (key === "net_down")     bar.netDown = val;
                                else if (key === "net_up")       bar.netUp = val;
                                else if (key === "bat")          bar.batVal = val;
                                else if (key === "bat_status")   bar.batStatus = val;
                                else if (key === "music")        bar.musicText = val;
                                else if (key === "music_status") bar.musicStatus = val;
                            }
                        }
                    }
                }
            }

            Process {
                id: volUpdateProc
                command: ["sh", "-c", "sleep 0.05 && echo $(pamixer --get-volume 2>/dev/null) $(pamixer --get-mute 2>/dev/null) $(pamixer --default-source --get-volume 2>/dev/null) $(pamixer --default-source --get-mute 2>/dev/null)"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        var lines = text.trim().split("\n");
                        var lastLine = lines[lines.length - 1];
                        var parts = lastLine.trim().split(/\s+/);
                        if (parts.length >= 4) {
                            bar.volVal = parts[0];
                            bar.volMuted = parts[1];
                            bar.micVal = parts[2];
                            bar.micMuted = parts[3];
                        }
                    }
                }
            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: statsProc.running = true
            }
            Component.onCompleted: statsProc.running = true


            // ╔══════════════════════════════════╗
            // ║          LEFT SECTION             ║
            // ╚══════════════════════════════════╝
            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // ── Workspaces ──
                GlassPill {
                    height: 40
                    width: Math.round(workspacesRow.implicitWidth + innerPadding * 2)

                    Item {
                        id: workspacesContainer
                        anchors.centerIn: parent
                        width: workspacesRow.implicitWidth
                        height: workspacesRow.implicitHeight

                        property real activeX: 0

                        // ── Bouncy Sliding Indicator ──
                        Rectangle {
                            x: workspacesContainer.activeX
                            y: 0
                            width: 30
                            height: 30
                            radius: 15
                            color: "#40FFFFFF"
                            antialiasing: true
                            
                            Behavior on x {
                                NumberAnimation { 
                                    duration: 500
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.5 
                                }
                            }
                        }

                        Row {
                            id: workspacesRow
                            anchors.fill: parent
                            spacing: 4

                            Repeater {
                                model: Hyprland.workspaces
                                delegate: WorkspaceButton {
                                    workspaceId: modelData.id
                                    isActive: modelData.active
                                    isUrgent: modelData.urgent

                                    onXChanged: if (isActive) workspacesContainer.activeX = x
                                    onIsActiveChanged: if (isActive) workspacesContainer.activeX = x
                                    Component.onCompleted: if (isActive) workspacesContainer.activeX = x
                                }
                            }
                        }
                    }
                }

                // ── Window Title ──
                GlassPill {
                    height: 40
                    width: Math.round(Math.min(windowTitle.implicitWidth + innerPadding * 2, 350))
                    visible: Hyprland.activeToplevel != null && Hyprland.activeToplevel.title !== ""

                    Text {
                        id: windowTitle
                        anchors.centerIn: parent
                        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                        color: "#E6FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 320)
                    }
                }

                // ── Music Player ──
                GlassPill {
                    height: 40
                    width: Math.round(musicRow.implicitWidth + innerPadding * 2)
                    visible: bar.musicStatus === "Playing" || bar.musicStatus === "Paused"

                    Row {
                        id: musicRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: bar.musicStatus === "Paused" ? "\uf04c" : "\uf001"
                            font.family: "Font Awesome 6 Free"; font.weight: 900
                            font.pixelSize: 12
                            color: bar.musicStatus === "Paused" ? "#80FFFFFF" : "#B3FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: bar.musicText || ""
                            color: "#E6FFFFFF"
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 200)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }


            // ╔══════════════════════════════════╗
            // ║         CENTER SECTION            ║
            // ╚══════════════════════════════════╝
            GlassPill {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                width: Math.round(clockRow.implicitWidth + innerPadding * 2)

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "\uf017"
                        font.family: "Font Awesome 6 Free"; font.weight: 900
                        font.pixelSize: 13
                        color: "#B3FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: clockText
                        text: Qt.formatDateTime(new Date(), "HH:mm  ·  dd MMM ddd")
                        color: "#FFFFFF"
                        font.pixelSize: 15
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm  ·  dd MMM ddd")
                        }
                    }
                }
            }


            // ╔══════════════════════════════════╗
            // ║         RIGHT SECTION             ║
            // ╚══════════════════════════════════╝
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // ── Hardware Stats (Temp | CPU | RAM) ──
                GlassPill {
                    height: 40
                    width: Math.round(hwRow.implicitWidth + innerPadding * 2)

                    Row {
                        id: hwRow
                        anchors.centerIn: parent
                        spacing: 12

                        // Temperature
                        Row {
                            visible: bar.tempVal !== ""
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "\uf2c9"
                                font.family: "Font Awesome 6 Free"; font.weight: 900
                                font.pixelSize: 11
                                color: "#B3FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: bar.tempVal + "°"
                                font.pixelSize: 13; font.bold: true
                                color: "#E6FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Separator
                        Rectangle {
                            width: 1; height: 16
                            color: "#33FFFFFF"
                            visible: bar.tempVal !== ""
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // CPU
                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "\uf2db"
                                font.family: "Font Awesome 6 Free"; font.weight: 900
                                font.pixelSize: 11
                                color: "#B3FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: bar.cpuVal + "%"
                                font.pixelSize: 13; font.bold: true
                                color: "#E6FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Separator
                        Rectangle {
                            width: 1; height: 16
                            color: "#33FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // RAM
                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "\uf1c0"
                                font.family: "Font Awesome 6 Free"; font.weight: 900
                                font.pixelSize: 11
                                color: "#B3FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: bar.memVal + "%"
                                font.pixelSize: 13; font.bold: true
                                color: "#E6FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Click to open btop
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("exec kitty -e btop")
                    }
                }

                // ── Network ──
                GlassPill {
                    height: 40
                    width: Math.round(netRow.implicitWidth + innerPadding * 2)
                    visible: bar.netInfo !== ""

                    Row {
                        id: netRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: bar.netType === "wifi" ? "\uf1eb" : "\uf0ac"
                            font.family: "Font Awesome 6 Free"; font.weight: 900
                            font.pixelSize: 11
                            color: "#B3FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: bar.netDown && bar.netUp ? "\u2193" + bar.netDown + " \u2191" + bar.netUp : bar.netInfo
                            font.pixelSize: 12; font.bold: true
                            color: "#E6FFFFFF"
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 140)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── Audio (Speaker & Mic) ──
                GlassPill {
                    height: 40
                    width: Math.round(audioRow.implicitWidth + innerPadding * 2)
                    visible: bar.volVal !== "" || bar.micVal !== ""

                    Row {
                        id: audioRow
                        anchors.centerIn: parent
                        spacing: 12

                        // Speaker
                        Item {
                            visible: bar.volVal !== ""
                            width: speakerRow.width
                            height: speakerRow.height
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: speakerRow
                                spacing: 6
                                Text {
                                    text: bar.volMuted === "true" ? "\uf026" : "\uf028"
                                    font.family: "Font Awesome 6 Free"; font.weight: 900
                                    font.pixelSize: 11
                                    color: bar.volMuted === "true" ? "#80FFFFFF" : "#B3FFFFFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: bar.volVal + "%"
                                    font.pixelSize: 13; font.bold: true
                                    color: "#E6FFFFFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.LeftButton) {
                                        Hyprland.dispatch("exec pavucontrol")
                                    } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                                        Hyprland.dispatch("exec pamixer -t")
                                        volUpdateProc.running = true
                                    }
                                }
                                onWheel: function(wheel) {
                                    if (wheel.angleDelta.y > 0)
                                        Hyprland.dispatch("exec pamixer -i 2")
                                    else
                                        Hyprland.dispatch("exec pamixer -d 2")
                                    volUpdateProc.running = true
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            width: 1; height: 16
                            color: "#33FFFFFF"
                            visible: bar.volVal !== "" && bar.micVal !== ""
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Microphone
                        Item {
                            visible: bar.micVal !== ""
                            width: micRow.width
                            height: micRow.height
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: micRow
                                spacing: 6
                                Text {
                                    text: bar.micMuted === "true" ? "\uf131" : "\uf130"
                                    font.family: "Font Awesome 6 Free"; font.weight: 900
                                    font.pixelSize: 11
                                    color: bar.micMuted === "true" ? "#80FFFFFF" : "#B3FFFFFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: bar.micVal + "%"
                                    font.pixelSize: 13; font.bold: true
                                    color: "#E6FFFFFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.LeftButton) {
                                        Hyprland.dispatch("exec pavucontrol")
                                    } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                                        Hyprland.dispatch("exec pamixer --default-source -t")
                                        volUpdateProc.running = true
                                    }
                                }
                                onWheel: function(wheel) {
                                    if (wheel.angleDelta.y > 0)
                                        Hyprland.dispatch("exec pamixer --default-source -i 2")
                                    else
                                        Hyprland.dispatch("exec pamixer --default-source -d 2")
                                    volUpdateProc.running = true
                                }
                            }
                        }
                    }
                }

                // ── Battery (if available) ──
                GlassPill {
                    height: 40
                    width: Math.round(batRow.implicitWidth + innerPadding * 2)
                    visible: bar.batVal !== ""

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: {
                                var v = parseInt(bar.batVal) || 0;
                                if (bar.batStatus === "Charging") return "\uf0e7";
                                if (v > 75) return "\uf240";
                                if (v > 50) return "\uf241";
                                if (v > 25) return "\uf242";
                                if (v > 10) return "\uf243";
                                return "\uf244";
                            }
                            font.family: "Font Awesome 6 Free"; font.weight: 900
                            font.pixelSize: 13
                            color: {
                                var v = parseInt(bar.batVal) || 0;
                                if (bar.batStatus === "Charging") return "#A6E3A1";
                                if (v <= 15) return "#F38BA8";
                                if (v <= 30) return "#F9E2AF";
                                return "#B3FFFFFF";
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: bar.batVal + "%"
                            font.pixelSize: 13; font.bold: true
                            color: "#E6FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── Power Button ──
                GlassPill {
                    height: 40
                    width: 42
                    innerPadding: 0

                    Text {
                        anchors.centerIn: parent
                        text: "\uf011"
                        font.family: "Font Awesome 6 Free"; font.weight: 900
                        font.pixelSize: 15
                        color: powerMouse.containsMouse ? "#FFFFFF" : "#CCFFFFFF"

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutExpo }
                        }
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("exec wlogout")
                    }
                }
            }
        }
    }
}
