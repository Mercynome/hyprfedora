#!/usr/bin/env bash

# Renk seçimi yap
COLOR=$(hyprpicker --format=hex)

# Eğer ESC'ye basıp iptal etmediyse
if [ -n "$COLOR" ]; then
    # Panoya kopyala
    wl-copy "$COLOR"
    
    # Bildirim gönder
    notify-send -t 3000 "🌈 Renk Seçildi" "<b>$COLOR</b> panoya kopyalandı."
    
    # Geçmişe kaydet
    HISTORY_FILE="$HOME/.cache/color_history.txt"
    touch "$HISTORY_FILE"
    
    # Aynı rengi sil ve en üste ekle
    grep -v "$COLOR" "$HISTORY_FILE" > /tmp/color_history.tmp || true
    echo "$COLOR" > "$HISTORY_FILE"
    cat /tmp/color_history.tmp >> "$HISTORY_FILE"
    
    # Son 30 rengi tut
    head -n 30 "$HISTORY_FILE" > /tmp/color_history.tmp
    mv /tmp/color_history.tmp "$HISTORY_FILE"
fi
