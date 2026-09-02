# omarchy-nkv

Versioned, reproducible user configuration for an Omarchy installation.

The repository records package manifests, safe user configuration, custom
themes, shell profiles, environment values that are safe to replicate, and a
diagnostic profile. Credentials and machine-specific runtime state are
intentionally excluded. This is a restoration aid, not a disk image: the
target PC must already be bootable with Omarchy/Arch Linux.

## Versions

Each snapshot is a directory under `versions/`. `ver-01` is the initial
baseline. Create a new version after a meaningful change:

```bash
cd ~/Projects/omarchy-nkv
./scripts/capture.sh ver-02
git diff --stat
git diff --check
git add versions/ver-02
git commit -m "Capture ver-02"
git tag ver-02
git push origin main --tags
```

The capture script is additive and does not modify the live installation.
Review `versions/<version>/SNAPSHOT.md` and run a secret scan before pushing.
Keep versions immutable; make a corrected version rather than rewriting a tag.

## Restore on a new PC

1. Install Omarchy and create the target user with the desired home directory.
   Connect to the network and install `git`, `sudo`, and (for AUR packages)
   `yay`.
2. Clone this repository and select a version:

   ```bash
   git clone https://github.com/i-nkv/omarchy-nkv.git
   cd omarchy-nkv
   git checkout ver-01
   ```

3. Review the manifests, then run `./scripts/restore.sh ver-01`. It asks before
   replacing files, installs package manifests, and restores safe configs and
   themes. User-local executables are inventoried but not copied because
   GitHub rejects files over 100 MB; reinstall those tools from their
   distribution source.
4. Log out and back in (or reboot) so services, shell startup, fonts, and
   desktop settings reload. Re-authenticate GitHub, browsers, Mullvad, Steam,
   and other services manually; credentials are not stored here.
5. Apply the recorded theme/font from `profile/omarchy-settings.txt` if it was
   not applied automatically.

## Capture and update

Run `./scripts/capture.sh ver-NN` on the current PC after a meaningful change,
review the generated snapshot, then commit and push it. Package manifests are
captured separately for official, AUR, and all installed packages, while
`MANIFEST.sha256` makes each snapshot auditable.
