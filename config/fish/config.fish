if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -U fish_greeting ""

set -gx EDITOR vim

bind \cy forward-char

bind -M insert \cy forward-char

# Created by `pipx` on 2026-07-28 14:46:54
set PATH $PATH /home/david/.local/bin

# Added by Antigravity CLI installer
set -gx PATH "/home/david/.local/bin" $PATH

abbr fish-reload "source ~/.config/fish/config.fish"

abbr config "cd /home/david/arch-config/config"

# Bind to (Alt-R)
bind \er add_-r_to_command


bind \ev sudovim




