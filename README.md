# DebianAula

Automated build scripts for **DebianAula**, a customized Debian Live KDE Plasma
ISO tailored for classroom/lab use (originally built for courses at UFSC).

The scripts take the official [Debian Live KDE](https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/)
image and, fully unattended (aside from two short interactive checkpoints),
produce a ready-to-boot ISO with a curated set of applications, sane defaults,
and a pre-configured desktop environment — so students get a consistent,
distraction-free environment out of the box.

## What you get

- **Live-only or live + installer**: choose at build time whether Calamares
  (with `calamares-settings-debian`, partitioning tools, GRUB, etc.) ships in
  the ISO, or whether it's stripped out for a smaller, install-free USB image.
- **Curated app set**: Firefox (Mozilla repo), VS Code, Neovim configured with
  [LazyVim](https://github.com/wyllianbs/LazyVim-Setup), Kate with
  [kate-quickrun](https://github.com/wyllianbs/kate-quickrun), Thonny, LibreOffice
  (pt-BR only, to keep the image lean), Konsole with Catppuccin color schemes,
  VLC, Audacity/Audacious, and more.
- **Sane KDE Plasma defaults, applied without user interaction**:
  - Taskbar with Konsole pinned, Discover not cluttering it
  - Kickoff menu favorites curated (browser, file manager, terminal, editors)
  - Digital clock with seconds and long date format
  - Notification area with the relevant items always visible
  - Desktop folder correctly pointed at `~/Desktop` (not `$HOME`)
  - Slideshow wallpaper (60 min, random)
  - ABNT2 (pt-BR) keyboard layout, system-wide
  - Screen lock disabled, Bluetooth disabled
  - Custom splash screen
- **Firefox configured via `policies.json`** (not by shipping a live browser
  profile, which would leak history/cookies/passwords into the image):
  extensions (uBlock Origin, Cookie Manager), homepage, "always ask where to
  save downloads", private browsing by default, password manager disabled,
  and a curated search engine list.
- **Bilingual build tooling**: `build-iso.sh` prints its prompts and progress
  messages in Portuguese or English, auto-detected from the host's `$LANG` —
  the generated ISO's language (pt-BR) is unaffected by this.
- **A disk-space reservation trick**: a 1GB placeholder file is created during
  the build and removed by an init script on first real boot, guaranteeing
  that much free space on the live overlay regardless of the target media.

## Files

| File | Purpose |
|---|---|
| `build-iso.sh` | Main entry point. Downloads/reuses the base Debian Live ISO, extracts it, chroots in to install packages and apply system-wide configuration, runs the interactive customization step, then repacks the final ISO. |
| `customize-skel.sh` | Copies `skel/` into the chroot's `/etc/skel`, so the live user's home directory is pre-populated the moment it's created by `adduser` — no manual setup needed. |
| `customize-home.sh` | Runs automatically (as the live user, before the interactive step) to install things that need real commands rather than static config files: npm globals, LazyVim, kate-quickrun (always fetching the *latest* GitHub release), conky. |
| `skel/` | The actual dotfiles/config template applied to every new build: Dolphin, Konsole (+ Catppuccin color schemes), Kate, KDE global settings (theme, panel, keyboard, screen lock, splash, wallpaper), VS Code, Thonny. Edit files here directly to change what ships by default — no need to touch `build-iso.sh`. |

## Usage

Requirements: a Debian/KDE Plasma host (or VM) with a real TTY, `sudo`, and an
X server running (`DISPLAY` set). `Xephyr` (`xserver-xephyr`) is required for
the interactive customization step.

```bash
bash build-iso.sh
```

You'll be asked for:
1. The live user's **username** and **password**.
2. Whether the ISO should be **live-only** or **live + installer**.

The build then runs mostly unattended. It pauses twice for interaction:

- **Full-rebuild confirmation** (only if a previous build's `iso/`/`squashfs-root/`
  already exist) — decide whether to start fresh or reuse what's there.
- **Interactive desktop session**: a nested X server (Xephyr) opens a nearly-
  complete desktop, isolated from your real session, where you can make any
  additional manual tweaks (Dolphin view mode, Konsole toolbar, etc.) before
  the ISO is finalized. Close the apps you opened normally, then close the
  Xephyr window (or type `exit`) to resume the automated build.

The finished ISO is written to `DebianAula.iso` in the working directory.

## Customizing further

- **App defaults captured by hand**: some KDE settings (Qt window/toolbar
  state, "use these view properties for all folders", etc.) are only written
  to disk when the relevant app is closed cleanly. Make the change in the
  interactive Xephyr session, close that app's window normally, then copy the
  relevant file(s) from the live user's home directory into `skel/` at the
  same relative path.
- **New packages**: edit the `apt-get install`/`apt-get purge` lists inside
  the `CHROOT_ROOT_SETUP` heredoc in `build-iso.sh`.
- **Firefox policy changes**: edit the `policies.json` heredoc in
  `build-iso.sh` — see [Mozilla's policy reference](https://mozilla.github.io/policy-templates/)
  for available keys.

## License

No license file yet — treat as "all rights reserved" until one is added.
