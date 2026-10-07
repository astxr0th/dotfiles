<div align="center">

# ✦ dotfiles ✦

**wxw @ nuclearcore** · mango + quickshell rice for Arch

[![Arch](https://img.shields.io/badge/Arch-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)](https://archlinux.org)
[![Artix](https://img.shields.io/badge/Artix-10A0CC?style=for-the-badge&logo=artixlinux&logoColor=white)](https://artixlinux.org)
[![Wayland](https://img.shields.io/badge/Wayland-FFBC00?style=for-the-badge&logo=wayland&logoColor=black)](https://wayland.freedesktop.org)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io)
[![Stars](https://img.shields.io/github/stars/astxr0th/dotfiles?style=for-the-badge&color=a96256&labelColor=0c090a)](https://github.com/astxr0th/dotfiles/stargazers)

![screenshot](assets/screenshot.png)

*colors follow the wallpaper: pick a new one and everything re-themes*

</div>

---

## ⟡ setup

| | |
|---|---|
| **distro** | Artix Linux (any Arch-based distro works) |
| **wm** | [mango](https://github.com/mangowm/mango) |
| **shell / bar** | [quickshell](https://quickshell.org) |
| **terminal** | [kitty](https://sw.kovidgoyal.net/kitty) · [foot](https://codeberg.org/dnkl/foot) |
| **shell** | zsh + [spaceship](https://spaceship-prompt.sh) |
| **editor** | neovim (lazy.nvim, snacks, blink.cmp, lspsaga) |
| **files** | [yazi](https://yazi-rs.github.io) |
| **colors** | [pywal16](https://github.com/eylles/pywal16) · [wallust](https://codeberg.org/explosion-mental/wallust) |
| **wallpaper** | awww |
| **font** | Iosevka · Iosevka Nerd Font |
| **icons** | Papirus |
| **fetch** | fastfetch (with neco-arc) |

## ⟡ the quickshell desktop

Everything on screen is one quickshell config. No waybar, rofi, or swaync needed (their configs are still here if you want them).

- **sidebar**: workspaces, clock, network, volume, battery
- **control center**: device toggles, cpu/ram/temp/disk bars, music player (any MPRIS app), notifications
- **launcher**: apps sorted by how often you open them
- **wallpaper picker**: thumbnails from `~/wal`, sets the wallpaper and regenerates the colors
- **live theming**: pywal colors are pushed to mango borders, kitty, and GTK light/dark as soon as they change
- **screen recorder**: gpu-screen-recorder front end with replay buffer, region record, and "save last N seconds"
- **screenshot tool**: region, window, or full screen; saved to `~/Pictures/Screenshots` and copied
- **mixer**: per-app volume, input/output switching, live peak meters
- **wifi + bluetooth panel**
- **lock screen** using ext-session-lock, so the session stays locked even if the shell crashes

## ⟡ install

> [!WARNING]
> The script backs up anything it replaces to `~/.dotfiles-backup/<date>`, but read it before you run it.

```bash
git clone https://github.com/astxr0th/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The script will:

1. check you're on an Arch-based distro (uses `sudo` or `doas`, whichever you have)
2. install `paru` if you don't have an AUR helper yet
3. install every package listed below
4. back up your current configs and symlink these in their place
5. on Artix/dinit, link the pipewire user services
6. offer to switch your shell to zsh

| flag | what it does |
|---|---|
| `-y`, `--yes` | don't ask anything |
| `-c`, `--copy` | copy files instead of symlinking |
| `-n`, `--no-packages` | only link configs |
| `-e`, `--extras` | also install zen browser, equibop, steam |
| `-h`, `--help` | show help |

Symlinks mean a `git pull` in `~/.dotfiles` updates everything. Use `--copy` if you'd rather keep your own changes separate.

After installing, log into **mango**, put some wallpapers in `~/wal`, and press <kbd>SUPER</kbd> + <kbd>W</kbd>.

<details>
<summary><b>package list</b></summary>

```
core     mangowm-git quickshell qt6-5compat xdg-desktop-portal-wlr polkit-gnome
         pipewire pipewire-pulse wireplumber networkmanager bluez-utils
         brightnessctl lm_sensors libnotify xdg-utils
cli      kitty foot zsh spaceship-prompt starship neovim yazi fastfetch btop mpv git
theme    python-pywal16-git wallust awww imagemagick ttf-iosevka
         ttf-iosevka-nerd ttf-jetbrains-mono-nerd papirus-icon-theme
media    grim slurp wl-clipboard cliphist gpu-screen-recorder
legacy   rofi waybar swaync
extras   zen-browser-bin equibop-bin steam
```

</details>

## ⟡ keybindings

<details open>
<summary><b>apps & desktop</b></summary>

| keys | action |
|---|---|
| <kbd>SUPER</kbd> <kbd>Space</kbd> | app launcher |
| <kbd>SUPER</kbd> <kbd>Return</kbd> | kitty |
| <kbd>SUPER</kbd> <kbd>E</kbd> | yazi |
| <kbd>SUPER</kbd> <kbd>B</kbd> | zen browser |
| <kbd>SUPER</kbd> <kbd>W</kbd> | wallpaper picker |
| <kbd>SUPER</kbd> <kbd>H</kbd> | control center |
| <kbd>SUPER</kbd> <kbd>SHIFT</kbd> <kbd>S</kbd> | screenshot tool |
| <kbd>SUPER</kbd> <kbd>SHIFT</kbd> <kbd>C</kbd> | edit mango config |
| <kbd>SUPER</kbd> <kbd>R</kbd> | reload mango |
| <kbd>SUPER</kbd> <kbd>Q</kbd> | close window |
| <kbd>SUPER</kbd> <kbd>SHIFT</kbd> <kbd>Q</kbd> | quit mango |

</details>

<details>
<summary><b>screen recorder</b></summary>

| keys | action |
|---|---|
| <kbd>ALT</kbd> <kbd>Z</kbd> | recorder panel |
| <kbd>ALT</kbd> <kbd>F9</kbd> | start / stop recording |
| <kbd>ALT</kbd> <kbd>CTRL</kbd> <kbd>F9</kbd> | record a region |
| <kbd>ALT</kbd> <kbd>F7</kbd> | pause |
| <kbd>ALT</kbd> <kbd>SHIFT</kbd> <kbd>F10</kbd> | toggle replay buffer |
| <kbd>ALT</kbd> <kbd>F10</kbd> | save replay |
| <kbd>ALT</kbd> <kbd>F11</kbd> | save last 60 seconds |
| <kbd>ALT</kbd> <kbd>F12</kbd> | save last 10 minutes |

</details>

<details>
<summary><b>windows</b></summary>

| keys | action |
|---|---|
| <kbd>ALT</kbd> <kbd>←↑↓→</kbd> | focus direction |
| <kbd>SUPER</kbd> <kbd>SHIFT</kbd> <kbd>←↑↓→</kbd> | swap windows |
| <kbd>SUPER</kbd> <kbd>F</kbd> | fullscreen |
| <kbd>SUPER</kbd> <kbd>SHIFT</kbd> <kbd>F</kbd> | fake fullscreen |
| <kbd>SUPER</kbd> <kbd>S</kbd> | toggle floating |
| <kbd>SUPER</kbd> <kbd>G</kbd> | toggle global |
| <kbd>SUPER</kbd> <kbd>O</kbd> | toggle overlay |
| <kbd>SUPER</kbd> <kbd>I</kbd> / <kbd>SHIFT</kbd> <kbd>I</kbd> | minimize / restore |
| <kbd>ALT</kbd> <kbd>A</kbd> | maximize |
| <kbd>ALT</kbd> <kbd>Tab</kbd> | overview |
| <kbd>ALT</kbd> <kbd>SHIFT</kbd> <kbd>Z</kbd> | scratchpad |
| <kbd>SUPER</kbd> <kbd>N</kbd> | next layout |
| <kbd>ALT</kbd> <kbd>E</kbd> / <kbd>ALT</kbd> <kbd>X</kbd> | full width / cycle width presets |
| <kbd>CTRL</kbd> <kbd>SHIFT</kbd> <kbd>←↑↓→</kbd> | move floating window |
| <kbd>CTRL</kbd> <kbd>ALT</kbd> <kbd>←↑↓→</kbd> | resize floating window |
| <kbd>SUPER</kbd> + left drag / right drag | move / resize |

</details>

<details>
<summary><b>tags & monitors</b></summary>

| keys | action |
|---|---|
| <kbd>SUPER</kbd> <kbd>1-9</kbd> | go to tag |
| <kbd>SUPER</kbd> <kbd>SHIFT</kbd> <kbd>1-9</kbd> | send window to tag |
| <kbd>SUPER</kbd> <kbd>←</kbd> / <kbd>→</kbd> | previous / next tag |
| <kbd>CTRL</kbd> <kbd>←</kbd> / <kbd>→</kbd> | previous / next tag that has windows |
| <kbd>CTRL</kbd> <kbd>SUPER</kbd> <kbd>←</kbd> / <kbd>→</kbd> | move window to previous / next tag |
| <kbd>SUPER</kbd> + scroll | cycle tags |
| <kbd>ALT</kbd> <kbd>SHIFT</kbd> <kbd>←</kbd> / <kbd>→</kbd> | focus monitor |
| <kbd>SUPER</kbd> <kbd>ALT</kbd> <kbd>←</kbd> / <kbd>→</kbd> | send window to monitor |
| <kbd>ALT</kbd> <kbd>SHIFT</kbd> <kbd>X</kbd> / <kbd>Z</kbd> / <kbd>R</kbd> | gaps bigger / smaller / toggle |

</details>

<details>
<summary><b>neovim</b> (leader is space)</summary>

| keys | action |
|---|---|
| <kbd>leader</kbd> <kbd>ff</kbd> | find files |
| <kbd>leader</kbd> <kbd>lg</kbd> | live grep |
| <kbd>K</kbd> | hover docs |
| <kbd>go</kbd> / <kbd>gr</kbd> | definition / references |
| <kbd>leader</kbd> <kbd>qf</kbd> | code action |
| <kbd>CTRL</kbd> <kbd>F</kbd> | format |
| <kbd>ALT</kbd> <kbd>1-9</kbd> | go to buffer |
| <kbd>leader</kbd> <kbd>w</kbd> | close buffer |
| <kbd>ALT</kbd> <kbd>T</kbd> | floating terminal |

</details>

## ⟡ layout

```
dotfiles/
├── install.sh
├── home/
│   └── .zshrc
└── config/               → ~/.config
    ├── mango/            window manager, rules, keybinds
    ├── quickshell/       sidebar, panels, launcher, lock, recorder
    ├── kitty/  foot/     terminals
    ├── nvim/             lua config, lazy.nvim
    ├── yazi/             file manager
    ├── wal/  wallust/    color templates
    ├── fastfetch/        fetch + neco-arc
    ├── btop/  mpv/
    ├── rofi/  waybar/  swaync/   older setup, still works
    ├── dinit.d/          pipewire user services (Artix only)
    ├── environment.d/
    ├── bin/              set_wal.sh
    └── starship.toml
```

## ⟡ notes

- `config/mango/config.conf` has a monitor rule for a 240Hz Samsung Odyssey and NVIDIA env vars at the top. Change or remove them for your hardware.
- `.zshrc` sets NVIDIA shader cache variables. They don't do anything on AMD or Intel.
- To lock the screen, run `qs ipc call lock lock`, or bind it in the mango config.
- `mango/colors.conf` and `kitty/zenities-colors.conf` are generated by quickshell on first run, so they aren't in the repo.

## ⟡ credits

- [zenities](https://github.com/hayyaoe/zenities) by hayyaoe, which the quickshell desktop is based on
- [mango](https://github.com/mangowm/mango), [quickshell](https://quickshell.org), [pywal16](https://github.com/eylles/pywal16)
- wallpapers from [wallhaven](https://wallhaven.cc)

<div align="center">
<br>
<sub>take whatever you want ✦</sub>
</div>
