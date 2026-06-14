# ~/.zshrc

# ZSH temel ayarları
autoload -Uz compinit
compinit

# Renkli terminal çıkışı
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Hyprland için çevresel değişkenler (Wayland & Qt)
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export QT_AUTO_SCREEN_SCALE_FACTOR="1"
export XCURSOR_THEME="Bibata-Modern-Classic"
export XCURSOR_SIZE="24"

# Eğer pfetch yüklüyse terminal her açıldığında göster
if command -v pfetch &> /dev/null; then
    pfetch
fi

# Starship terminal temasını ZSH için başlat
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
