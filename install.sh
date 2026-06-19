#!/bin/bash
# ==============================================================================
# AKILLI OS SEÇİCİ & KURULUM BETİĞİ
# Bu betik Fedora veya Arch sistemini otomatik algılar ve gerekli dotfiles paketlerini kurar.
# ==============================================================================

if [ "$EUID" -eq 0 ]; then
    echo "HATA: Lütfen bu betiği 'sudo' ile çalıştırmayın!"
    echo "Bunu yaparsanız tüm dosyalarınız /root dizinine kopyalanır."
    echo "Betik içindeki paket yöneticisi (dnf/pacman) sizden otomatik şifre isteyecektir."
    echo "Doğru kullanım: ./install.sh"
    exit 1
fi

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
    sudo dnf copr enable -y solopasha/hyprland
    sudo dnf copr enable -y scottames/awww
    sudo dnf copr enable -y sdegler/hyprland
    sudo dnf install -y --skip-unavailable kitty fuzzel waybar SwayNotificationCenter wlogout kvantum qt5ct qt6ct cliphist wl-clipboard satty waypaper pyprland hyprland hyprpolkitagent hypridle hyprlock hyprsunset hyprshot nwg-look awww cargo rust-packaging gtk4-layer-shell-devel wget tar xz zsh util-linux-user unzip cava btop rofi nwg-drawer swww quickshell qt5-qtwayland qt6-qtwayland qt6-qtsvg qt6-qtdeclarative qt6-qt5compat grim slurp jq xdg-desktop-portal-hyprland xdg-desktop-portal-gtk thunar libnotify pavucontrol pamixer brightnessctl playerctl wtype
    
    echo "hyprKCS (Arayüzlü Tuş Yöneticisi) Cargo ile kuruluyor..."
    cargo install hyprKCS

elif [ "$OS" == "arch" ]; then
    echo "Arch Linux tespit edildi! Paketler pacman/paru ile kuruluyor..."
    sudo pacman -Syu --needed hyprland kitty fuzzel waybar wlogout kvantum qt5ct qt6ct cliphist wl-clipboard pyprland hypridle hyprlock cargo wget tar xz zsh unzip cava btop rofi swww qt5-wayland qt6-wayland qt6-declarative qt6-svg qt6-5compat grim slurp jq xdg-desktop-portal-hyprland xdg-desktop-portal-gtk thunar libnotify pavucontrol pamixer brightnessctl playerctl wtype
    # AUR paketleri için yay veya paru varsayıyoruz:
    if command -v paru &> /dev/null; then
        paru -S --needed swaync satty waypaper hyprpolkitagent hyprsunset hyprshot nwg-look awww-git hyprkcs-git nwg-drawer quickshell
    elif command -v yay &> /dev/null; then
        yay -S --needed swaync satty waypaper hyprpolkitagent hyprsunset hyprshot nwg-look awww-git hyprkcs-git nwg-drawer quickshell
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
    (
        cd "$temp_pure" || exit
        ./install-user.sh || cp -r Pure* ~/.local/share/icons/
    )
    rm -rf "$temp_pure"
fi

# Bibata Modern Classic Cursors (GitHub Releases'ten doğrudan indirme)
if [ ! -d "$HOME/.icons/Bibata-Modern-Classic" ]; then
    echo "Bibata Cursors indiriliyor..."
    wget -q https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz -O /tmp/bibata.tar.xz
    tar xJf /tmp/bibata.tar.xz -C ~/.icons/
    rm -f /tmp/bibata.tar.xz
fi

# Nerd Fonts Kurulumu (FiraCode)
if ! fc-list | grep -i "FiraCode Nerd Font" &> /dev/null; then
    echo "FiraCode Nerd Font indiriliyor..."
    mkdir -p ~/.local/share/fonts/FiraCode
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz -O /tmp/FiraCode.tar.xz
    tar xJf /tmp/FiraCode.tar.xz -C ~/.local/share/fonts/FiraCode/
    rm -f /tmp/FiraCode.tar.xz
    fc-cache -f -v
fi

# pfetch Kurulumu (Sistem Bilgi Gösterici)
if ! command -v pfetch &> /dev/null; then
    echo "pfetch kuruluyor..."
    sudo wget -qO /usr/local/bin/pfetch https://github.com/dylanaraps/pfetch/raw/master/pfetch
    sudo chmod +x /usr/local/bin/pfetch
fi

# Starship Kurulumu (Terminal Teması)
if ! command -v starship &> /dev/null; then
    echo "Starship terminal teması kuruluyor..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "Paket kurulumu tamamlandı."
echo "Yapılandırma dosyaları (Dotfiles) sembolik bağ (symlink) olarak ~/.config altına bağlanıyor..."

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dots"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

# 1. ~/.config Klasörü İçin Sembolik Bağlar
for item in "$DOTS_DIR/.config"/*; do
    if [ -e "$item" ]; then
        item_name=$(basename "$item")
        target="$CONFIG_DIR/$item_name"
        
        if [ -e "$target" ] || [ -L "$target" ]; then
            echo "Yedekleniyor: $target -> ${target}_backup"
            mv "$target" "${target}_backup" 2>/dev/null || rm -rf "$target"
        fi
        
        echo "Bağlanıyor: $target -> $item"
        ln -s "$item" "$target"
    fi
done

# 2. Ana Dizin (~) İçin Sembolik Bağlar (Örn: .bashrc)
for item in "$DOTS_DIR"/.*; do
    if [ -f "$item" ]; then
        item_name=$(basename "$item")
        # . ve .. dizinlerini atla
        if [ "$item_name" == "." ] || [ "$item_name" == ".." ] || [ "$item_name" == ".config" ]; then
            continue
        fi
        
        target="$HOME/$item_name"
        if [ -e "$target" ] || [ -L "$target" ]; then
            echo "Yedekleniyor: $target -> ${target}_backup"
            mv "$target" "${target}_backup" 2>/dev/null || rm -rf "$target"
        fi
        
        echo "Bağlanıyor: $target -> $item"
        ln -s "$item" "$target"
    fi
done

# GRUB Tema Kurulumu
echo "GRUB (Önyükleyici) teması kuruluyor (Hyperfluent Fedora)..."
sudo mkdir -p /boot/grub2/themes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/hyperfluent-fedora.tar.gz" ]; then
    # GRUB teması aslen zip arşivi olduğu için (adında tar.gz yazsa da) unzip ile hyperfluent-fedora klasörüne çıkartıyoruz.
    sudo unzip -q -o "$SCRIPT_DIR/hyperfluent-fedora.tar.gz" -d /boot/grub2/themes/hyperfluent-fedora/ 2>/dev/null || true
    
    if grep -q "^GRUB_THEME=" /etc/default/grub; then
        sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub2/themes/hyperfluent-fedora/theme.txt"|' /etc/default/grub
    else
        echo 'GRUB_THEME="/boot/grub2/themes/hyperfluent-fedora/theme.txt"' | sudo tee -a /etc/default/grub
    fi
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg || sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB teması başarıyla uygulandı!"
else
    echo "GRUB teması dosyası bulunamadı, atlanıyor."
fi

# GTK ve Hyprland Tema Ayarlarının Uygulanması
echo "İkon ve İmleç temaları (Pure-Dark & Bibata) GTK geneli için varsayılan yapılıyor..."
gsettings set org.gnome.desktop.interface icon-theme 'Pure-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true

echo "Terminal kabuğu ZSH olarak değiştiriliyor..."
if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s $(which zsh) || echo "ZSH varsayılan kabuk yapılamadı. Manuel olarak 'chsh -s \$(which zsh)' komutunu çalıştırabilirsiniz."
fi

echo "========================================================================="
echo "KURULUM VE DOTFILES AKTARIMI BAŞARIYLA TAMAMLANDI! 🚀"
echo "Sisteminizi yeniden başlatmanız veya Hyprland'i yeniden yüklemeniz önerilir."
echo "========================================================================="
