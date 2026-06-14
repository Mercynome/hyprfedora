#!/bin/bash
# ==============================================================================
# AKILLI OS SEÇİCİ & KURULUM BETİĞİ
# Bu betik Fedora veya Arch sistemini otomatik algılar ve gerekli dotfiles paketlerini kurar.
# ==============================================================================

echo "OS Tespiti yapılıyor..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "İşletim sistemi tespit edilemedi."
    exit 1
fi

if [ "$OS" == "fedora" ]; then
    echo "Fedora sistemi tespit edildi! Paketler kuruluyor..."
    sudo dnf copr enable -y solopasha/hyprland scottames/awww tofik/nwg-shell sdegler/hyprland
    sudo dnf install -y kitty fuzzel waybar SwayNotificationCenter wlogout kvantum qt5ct qt6ct cliphist satty waypaper pyprland hyprland hyprpolkitagent hypridle hyprlock hyprsunset hyprshot nwg-look awww cargo rust-packaging gtk4-layer-shell-devel wget tar xz
    
    echo "hyprKCS (Arayüzlü Tuş Yöneticisi) Cargo ile kuruluyor..."
    cargo install hyprKCS

elif [ "$OS" == "arch" ]; then
    echo "Arch Linux tespit edildi! Paketler pacman/paru ile kuruluyor..."
    sudo pacman -Syu --needed hyprland kitty fuzzel waybar wlogout kvantum qt5ct qt6ct cliphist pyprland hypridle hyprlock cargo wget tar xz
    # AUR paketleri için yay veya paru varsayıyoruz:
    if command -v paru &> /dev/null; then
        paru -S --needed swaync satty waypaper hyprpolkitagent hyprsunset hyprshot nwg-look awww-git hyprkcs-git
    elif command -v yay &> /dev/null; then
        yay -S --needed swaync satty waypaper hyprpolkitagent hyprsunset hyprshot nwg-look awww-git hyprkcs-git
    else
        echo "Lütfen AUR yardımcı programı (yay veya paru) kurun."
        exit 1
    fi
else
    echo "Desteklenmeyen OS: $OS. Lütfen paketleri elle kurun."
fi

echo "İkon ve İmleç temaları doğrudan kaynak koddan indiriliyor..."
mkdir -p ~/.local/share/icons
mkdir -p ~/.icons

# Pure Icon Theme (GitHub'dan clone edip kopyalama)
if [ ! -d "$HOME/.local/share/icons/Pure-Dark" ]; then
    echo "Pure Icon Theme indiriliyor..."
    temp_pure=$(mktemp -d)
    git clone https://github.com/mjkim0727/Pure-icon-theme.git "$temp_pure"
    cd "$temp_pure"
    ./install-user.sh || cp -r Pure* ~/.local/share/icons/
    rm -rf "$temp_pure"
fi

# Bibata Modern Classic Cursors (GitHub Releases'ten doğrudan indirme)
if [ ! -d "$HOME/.icons/Bibata-Modern-Classic" ]; then
    echo "Bibata Cursors indiriliyor..."
    wget -qO- https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz | tar xJ -C ~/.icons/
fi

echo "Paket kurulumu tamamlandı."
echo "Yapılandırma dosyaları (Dotfiles) sembolik bağ (symlink) olarak ~/.config altına bağlanıyor..."

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dots/.config"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

# Her bir config klasörünü / dosyasını tarayıp sembolik bağ oluşturuyoruz
for item in "$DOTS_DIR"/*; do
    if [ -e "$item" ]; then
        item_name=$(basename "$item")
        target="$CONFIG_DIR/$item_name"
        
        # Eğer hedefte zaten bir klasör/dosya varsa veya bozuk bir sembolik bağ ise yedekle/sil
        if [ -e "$target" ] || [ -L "$target" ]; then
            echo "Yedekleniyor: $target -> ${target}_backup"
            mv "$target" "${target}_backup" 2>/dev/null || rm -rf "$target"
        fi
        
        echo "Bağlanıyor: $target -> $item"
        ln -s "$item" "$target"
    fi
done

# GTK ve Hyprland Tema Ayarlarının Uygulanması
echo "İkon ve İmleç temaları (Pure-Dark & Bibata) GTK geneli için varsayılan yapılıyor..."
gsettings set org.gnome.desktop.interface icon-theme 'Pure-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true

echo "========================================================================="
echo "KURULUM VE DOTFILES AKTARIMI BAŞARIYLA TAMAMLANDI! 🚀"
echo "Sisteminizi yeniden başlatmanız veya Hyprland'i yeniden yüklemeniz önerilir."
echo "========================================================================="
