# Beets-Lidarr Unmapped Tagging Helper

This utility scans your Lidarr-managed music library for folders that contain music files but are not yet recognized by Lidarr (unmapped). It then attempts to tag them using [Beets](https://beets.io/) and triggers a Lidarr rescan so they are picked up properly.

> 📝 **Attribution:** This tool builds upon the excellent work in [RandomNinjaAtk/arr-scripts](https://github.com/RandomNinjaAtk/arr-scripts), specifically the `BeetsTagger` for Lidarr and its `beets-config.yaml`. All credit for the Beets integration and tagging logic goes to the original author.

---

## 🔧 Features
- Detects music folders not associated with albums in Lidarr
- Runs Beets to automatically tag music metadata
- Supports `.mp3` and `.flac` files
- Triggers Lidarr to rescan the library afterward
- Caches known Lidarr paths for performance
- Dry run mode for safe testing
- Generates logs for matched, failed, and total operations

---

## 📦 Usage

### Docker Compose

Place the following files in the same directory:
- `docker-compose.yml`
- `Dockerfile`
- `scripts/`
  - `beets_lidarr_cleanup.sh`
  - `beets-config.yaml`

Then build and run:

```bash
docker compose up --build
```

### Optional Flags

```bash
docker compose run beets-cleaner --refresh-cache
```
- `--refresh-cache`: Forces reloading Lidarr album paths via API instead of using the cached list.

To enable dry run mode:
- Edit `beets_lidarr_cleanup.sh` and set `DRY_RUN=true`

---

## 📁 Folder Structure

```bash
.
├── docker-compose.yml
├── Dockerfile
└── scripts
    ├── beets-config.yaml
    └── beets_lidarr_cleanup.sh
```

---

## 📝 Requirements
- Lidarr API key and URL
- Music library volume mapped as `/music`
- Beets configuration (`beets-config.yaml`)
- LinuxServer.io or Beetbox Beets container (multi-arch)

---

## 🛡 Permissions
Ensure your container user has read access to your music directory. On Unraid:

```bash
chown -R nobody:users /mnt/user/YOUR_MUSIC_PATH
chmod -R u+rwX,go+rX,go-w /mnt/user/YOUR_MUSIC_PATH
```

---

## 📃 Logs
- `beets_lidarr_cleanup.log`: Full run log
- `beets_matched.log`: Successfully tagged folders
- `beets_failed.log`: Folders that failed tagging

---

## ✅ Future Improvements
- `.wma` → `.mp3` conversion pre-pass
- Permission-denied folder tracking
- Scheduled automation or webhook trigger

---

This project is licensed under the GNU General Public License v3.0 — see the LICENSE file for details.

© Chris Almida / Sovereign Living
