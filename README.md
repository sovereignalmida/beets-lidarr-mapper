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

## 🚀 **Usage**

This tool runs a containerized `beets` instance to process and clean up unmapped music files, helping Lidarr correctly identify and tag your library.

---

## 🔧 **Setup**

1. Copy the provided `.env.example` file and fill in your Lidarr API key and path details:

```bash
cp .env.example config.env
```

2. Run the container:

```bash
docker compose up --build
```

---

## 🏁 **Runtime Flags**

The script supports the following runtime flags:

| Flag             | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| `--dry-run`      | Runs without making changes (no tagging, no Lidarr rescan)                  |
| `--refresh-cache`| Forces a fresh Lidarr album path list (ignores cached results)              |
| `--resume-only`  | Skips folder scanning and only resumes from previously generated todo list  |

You can combine flags like so:

```bash
docker compose run beets-cleaner --dry-run --resume-only
```

---

## 📂  **Folder Tracking**

To ensure resumability, the script tracks folder state:

- `beets_todo.log` — All discovered unmapped folders
- `beets_done.log` — Successfully processed folders
- `beets_failed.log` — Folders Beets could not tag
- `beets_remaining.log` — What’s left to process

You can safely stop and restart the container, and it will continue where it left off.


---

## 📁 Folder Structure

```bash
.
├── docker-compose.yml
├── Dockerfile
└── scripts
    ├── beets-config.yaml
    ├── beets_lidarr_cleanup.sh
    └── config.env
```

---

## 📝 Requirements
- Lidarr API key and URL
- Music library volume mapped as `/music`
- Beets configuration (`beets-config.yaml`)
- LinuxServer.io or Beetbox Beets container (multi-arch)

---

## 🛡 Permissions
Ensure your container user has read access to your music directory. 

On Unraid:

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
