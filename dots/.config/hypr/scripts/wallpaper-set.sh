#!/bin/bash
# ════════════════════════════════════════════════════════════
# WALLPAPER SET — Duvar kağıdı değiştir ve tüm sistemi
# Material You renk paletine göre güncelle
# ════════════════════════════════════════════════════════════
# Kullanım:
#   wallpaper-set.sh /path/to/wallpaper.jpg
#   wallpaper-set.sh   (argümansız: waypaper ile seçtir)
# ════════════════════════════════════════════════════════════

WALLPAPER="$1"

# Eğer argüman verilmezse waypaper'ı aç
if [ -z "$WALLPAPER" ]; then
    waypaper
    # waypaper kendi seçtiği dosyayı otomatik uygular
    # Son kullanılan dosyayı waypaper config'den bul
    WALLPAPER=$(grep "wallpaper" ~/.config/waypaper/config.ini 2>/dev/null | tail -1 | cut -d'=' -f2 | xargs)
    if [ -z "$WALLPAPER" ]; then
        echo "Duvar kağıdı bulunamadı."
        exit 1
    fi
fi

echo "🎨 Duvar kağıdı değiştiriliyor: $WALLPAPER"

# 1. swww ile duvar kağıdını uygula (yumuşak geçiş)
if command -v swww &> /dev/null; then
    swww img "$WALLPAPER" \
        --transition-type grow \
        --transition-pos "0.5,0.5" \
        --transition-duration 1.5 \
        --transition-fps 60
fi

# 2. matugen ile Material You renk paleti üret
if command -v matugen &> /dev/null; then
    echo "🎨 Material You renkleri üretiliyor..."
    matugen image "$WALLPAPER"
    echo "✅ Renk paleti güncellendi!"
else
    echo "⚠️  matugen bulunamadı, renk güncellemesi atlanıyor."
    exit 0
fi

# 3. Uygulamaları yeniden yükle
echo "🔄 Uygulamalar yeniden yükleniyor..."

# Hyprland config yeniden yükle (border renkleri)
hyprctl reload 2>/dev/null

# Kitty terminal renklerini yeniden yükle (çalışan pencerelere)
for pid in $(pgrep -x kitty); do
    kill -SIGUSR1 "$pid" 2>/dev/null
done

# Spicetify (Spotify renkleri)
if command -v spicetify &> /dev/null; then
    spicetify apply 2>/dev/null &
fi

# Bildirim gönder
notify-send "🎨 Renk Paleti Güncellendi" "Duvar kağıdına göre tüm renkler değiştirildi!" -u normal -t 3000

echo "✅ Tüm renkler başarıyla güncellendi!"
