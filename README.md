# Arch Linux Dotfiles & System Configuration

## Repository Structure

```text
arch-config/
├── .gitignore              # Ignores temp files, logs, and sensitive data
├── README.md               # Documentation and usage guide
├── install.sh              # Setup & bootstrap script (Full, Terminal-only, Desktop-only)
├── backup.sh               # Local backup script (Refreshes package lists & configs)
├── push.sh                 # Git push script (Commits & pushes to GitHub)
├── packages/
│   ├── pacman-pkgs.txt     # Explicitly installed native packages (pacman -Qqen)
│   ├── aur-pkgs.txt        # Explicitly installed AUR packages (pacman -Qqem)
│   └── terminal-pkgs.txt   # Core terminal utilities (fish, kitty, tmux, gvim, etc.)
├── home/
│   └── .vimrc              # Symlinked to ~/.vimrc
└── config/
    ├── fish/               # Fish shell configuration, completions, and functions
    ├── hypr/               # Hyprland, hypridle, hyprlock, and helper scripts
    ├── kitty/              # Kitty terminal configuration
    ├── mako/               # Mako notification daemon config
    ├── rofi/               # Rofi menu themes and rasi configs
    ├── tmux/               # Tmux configuration
    ├── waybar/             # Waybar status bar config, styles, and scripts
    └── wofi/               # Wofi configuration
```

---

## Backup & Git Workflow


### 1. Refresh & Local Backup (`backup.sh`)
Refresh package lists and pull any non-symlinked config updates:

```bash
./backup.sh
```

- Exports active packages into `packages/pacman-pkgs.txt` and `packages/aur-pkgs.txt`.
- Cleans any temporary/backup files (`*.bak`, `nohup.out`, etc.).
- Displays `git status` summary.
- **Does not commit or push**

### 2. Push Changes to GitHub (`push.sh`)

```bash
# Push with default timestamp message:
./push.sh

# Custom commit message:
./push.sh "Added new tmux keybindings and updated fish prompt"
```

---

## Installation & Restoration (`install.sh`)

Clone and set up your system or terminal

```bash
git clone https://github.com/David-Pylko/arch-config.git ~/arch-config
cd ~/arch-config
./install.sh
```

### Installation Modes & Flags

| Mode | Command Flag | What it Does |
| :--- | :--- | :--- |
| **Full Setup** | `./install.sh --all` | Installs all pacman + AUR packages, links all desktop & terminal configs, sets default shell |
| **Terminal Setup Only** | `./install.sh --terminal` | Installs terminal packages (`fish`, `kitty`, `tmux`, `gvim`, `fzf`, `fastfetch`), links terminal configs, sets shell |
| **Terminal Configs Only** | `./install.sh --terminal-links` | Symlinks `kitty`, `tmux`, `fish`, and `.vimrc` without installing packages |
| **Desktop Configs Only** | `./install.sh --desktop-links` | Symlinks `hypr`, `waybar`, `mako`, `rofi`, `wofi` without installing packages |
| **All Configs Only** | `./install.sh --links-only` | Symlinks all configs (desktop + terminal) without installing packages |
| **Packages Only** | `./install.sh --packages-only` | Installs all official pacman & AUR packages without touching configs |

> **Safety** Any existing configuration file or directory is automatically backed up to `~/.config_backups/backup_<timestamp>/` before creating symlinks.

