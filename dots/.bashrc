# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Abacus AI CLI
export PATH="/home/general/.abacusai/bin:$PATH"
. "$HOME/.cargo/env"

# opencode
export PATH=/home/general/.opencode/bin:$PATH


# Added by Antigravity CLI installer
export PATH="/home/general/.local/bin:$PATH"
eval "$(starship init bash)"
export QML_XHR_ALLOW_FILE_READ=1

# Pfetch Customization
export PF_INFO="ascii title os host kernel uptime memory"
export PF_ALIGN="8"
export PF_COLOR=1
pfetch
