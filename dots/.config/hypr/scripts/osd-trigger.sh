#!/bin/bash
# ════════════════════════════════════════════════════════════
# OSD Trigger Script — Ses ve parlaklık değişimlerini
# Quickshell OSD overlay'ine bildirir
# ════════════════════════════════════════════════════════════
# Kullanım:
#   osd-trigger.sh vol-up
#   osd-trigger.sh vol-down
#   osd-trigger.sh vol-mute
#   osd-trigger.sh bright-up
#   osd-trigger.sh bright-down
# ════════════════════════════════════════════════════════════

ACTION="$1"

case "$ACTION" in
    vol-up)
        pamixer -i 5
        TYPE="volume"
        VALUE=$(pamixer --get-volume 2>/dev/null)
        MUTED=$(pamixer --get-mute 2>/dev/null)
        ;;
    vol-down)
        pamixer -d 5
        TYPE="volume"
        VALUE=$(pamixer --get-volume 2>/dev/null)
        MUTED=$(pamixer --get-mute 2>/dev/null)
        ;;
    vol-mute)
        pamixer -t
        TYPE="volume"
        VALUE=$(pamixer --get-volume 2>/dev/null)
        MUTED=$(pamixer --get-mute 2>/dev/null)
        ;;
    bright-up)
        brightnessctl set +5%
        TYPE="brightness"
        VALUE=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')
        MUTED="false"
        ;;
    bright-down)
        brightnessctl set 5%-
        TYPE="brightness"
        VALUE=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')
        MUTED="false"
        ;;
    *)
        echo "Bilinmeyen eylem: $ACTION"
        exit 1
        ;;
esac

# OSD verilerini yaz
cat > /tmp/qs_osd << EOF
type=$TYPE
value=$VALUE
muted=$MUTED
EOF

# Trigger dosyasını güncelle (Quickshell'in değişikliği algılaması için)
echo "$(date +%s%N)" > /tmp/qs_osd_trigger
