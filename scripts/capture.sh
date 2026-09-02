#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
if [[ ! "$version" =~ ^ver-[0-9][0-9A-Za-z.-]*$ ]]; then
  printf 'Usage: %s ver-NN\n' "$0" >&2
  exit 2
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
out="$repo_root/versions/$version"
if [[ -e "$out" ]]; then
  printf 'Refusing to overwrite existing snapshot: %s\n' "$out" >&2
  exit 1
fi
mkdir -p "$out"/{packages,profile,config,home}

printf 'Capturing package manifests...\n'
pacman -Qqe | sort -u > "$out/packages/pacman-explicit.txt"
pacman -Qqm | sort -u > "$out/packages/aur-explicit.txt"
pacman -Qq | sort -u > "$out/packages/pacman-all.txt"
pacman -Q > "$out/packages/pacman-versions.txt"
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application,origin,version 2>/dev/null | sort > "$out/packages/flatpak-apps.txt" || :
fi

printf 'Capturing OS and desktop profile...\n'
date --iso-8601=seconds > "$out/profile/captured-at.txt"
cat /etc/os-release > "$out/profile/os-release"
uname -a > "$out/profile/uname.txt"
id > "$out/profile/user-id.txt"
groups > "$out/profile/groups.txt"
getent passwd "$USER" | cut -d: -f1,3,4,6,7 > "$out/profile/passwd-entry.txt"
command -v omarchy >/dev/null && omarchy version > "$out/profile/omarchy-version.txt" || :
command -v omarchy >/dev/null && omarchy theme current > "$out/profile/omarchy-settings.txt" || :
command -v omarchy >/dev/null && omarchy font current >> "$out/profile/omarchy-settings.txt" || :
locale > "$out/profile/locale.txt"
hostnamectl 2>/dev/null > "$out/profile/hostnamectl.txt" || hostname > "$out/profile/hostname.txt"
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null > "$out/profile/user-services-enabled.txt" || :
systemctl list-unit-files --state=enabled --no-legend 2>/dev/null > "$out/profile/system-services-enabled.txt" || :
findmnt > "$out/profile/mounts.txt"
if command -v lscpu >/dev/null; then lscpu > "$out/profile/lscpu.txt"; fi
if command -v lsblk >/dev/null; then lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS > "$out/profile/lsblk.txt"; fi
env | cut -d= -f1 | sort > "$out/profile/environment-names.txt"
env | grep -E '^(COLORTERM|EDITOR|GDK_BACKEND|GDK_SCALE|GIT_TERMINAL_PROMPT|LANG|LC_|MOZ_ENABLE_WAYLAND|OZONE_PLATFORM|QT_IM_MODULE|QT_QPA_PLATFORM|QT_QPA_PLATFORMTHEME|SDL_IM_MODULE|SHELL|TERM|TERMINAL|XCOMPOSEFILE|XCURSOR_SIZE|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|_JAVA_AWT_WM_NONREPARENTING)=' | sort > "$out/profile/environment-safe.env" || :
mkdir -p "$out/config/environment.d"
env | grep -E '^(EDITOR|GDK_BACKEND|GDK_SCALE|LANG|LC_[A-Za-z0-9_]*|MOZ_ENABLE_WAYLAND|OZONE_PLATFORM|QT_IM_MODULE|QT_QPA_PLATFORM|QT_QPA_PLATFORMTHEME|SDL_IM_MODULE|XCOMPOSEFILE|XCURSOR_SIZE)=' \
  | sort > "$out/config/environment.d/omarchy-nkv.conf" || :

copy_config() {
  local rel="$1"
  if [[ -e "$HOME/.config/$rel" ]]; then
    mkdir -p "$out/config/$(dirname "$rel")"
    cp -a "$HOME/.config/$rel" "$out/config/$(dirname "$rel")/"
  fi
}
printf 'Capturing safe user configuration...\n'
for rel in \
  alacritty foot ghostty kitty btop fish git lazygit mimeapps.list \
  starship.toml tmux nvim fcitx5 gtk-3.0 gtk-4.0 imv mise \
  hypr hyprland-preview-share-picker onlyoffice obsidian opencode \
  tensaku xournalpp yay omarchy; do
  copy_config "$rel"
done
for rel in .bashrc .bash_profile .profile .XCompose; do
  [[ -f "$HOME/$rel" ]] && cp -a "$HOME/$rel" "$out/home/"
done
if [[ -d "$HOME/.local/bin" ]]; then
  find "$HOME/.local/bin" -maxdepth 1 -type f -printf '%f\t%k KB\t%M\n' \
    | sort > "$out/profile/local-bin-inventory.txt"
fi

printf 'Removing nested Git metadata from custom themes...\n'
find "$out/config/omarchy/themes" -type d -name .git -prune -exec rm -rf {} + 2>/dev/null || :
printf '# Snapshot %s\n\nCaptured from %s on %s.\n\nSecrets and runtime state are excluded.\n' \
  "$version" "${USER}@$(hostname)" "$(date --iso-8601=seconds)" > "$out/SNAPSHOT.md"
find "$out" -type f ! -name MANIFEST.sha256 -print0 | sort -z | xargs -0 sha256sum > "$out/MANIFEST.sha256"
printf 'Snapshot written to %s\n' "$out"
