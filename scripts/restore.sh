#!/usr/bin/env bash
set -euo pipefail

version="${1:-ver-01}"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
snapshot="$repo_root/versions/$version"
[[ -d "$snapshot" ]] || { printf 'Unknown snapshot: %s\n' "$version" >&2; exit 1; }

read -r -p "Install packages and replace safe configs from $version? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { printf 'Cancelled.\n'; exit 0; }

if [[ -s "$snapshot/packages/pacman-explicit.txt" ]]; then
  sudo pacman -Syu --needed --noconfirm - < "$snapshot/packages/pacman-explicit.txt"
fi
if [[ -s "$snapshot/packages/aur-explicit.txt" ]] && command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm - < "$snapshot/packages/aur-explicit.txt"
elif [[ -s "$snapshot/packages/aur-explicit.txt" ]]; then
  printf 'AUR packages recorded but yay is unavailable; install them from packages/aur-explicit.txt.\n' >&2
fi

mkdir -p "$HOME/.config" "$HOME/.local"
cp -a "$snapshot/config/." "$HOME/.config/"
cp -a "$snapshot/home/." "$HOME/"
printf 'Restored %s. Re-authenticate excluded services and log out/in to reload the desktop.\n' "$version"
