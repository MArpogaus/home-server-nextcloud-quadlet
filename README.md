# service-nextcloud

Nextcloud 31 deployment via Podman Quadlet with PostgreSQL, Redis, and custom PHP-FPM optimization.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Nextcloud Service (Quadlet)                        │
│                                                     │
│  nextcloud-db     ─ PostgreSQL 15 (:Z volume)       │
│  nextcloud-redis  ─ Redis 7                         │
│  nextcloud-app    ─ Nextcloud 31 (custom image)     │
│  nextcloud-push   ─ notify_push                     │
│  nextcloud-cron   ─ cron.php scheduler              │
│  nextcloud-preview-generator ─ preview generation   │
│  nextcloud-web    ─ Nginx reverse proxy             │
│                                                     │
│  Network: shared-network (bridge 10.89.0.0/24)      │
│  (shared with Bunkerweb via container-to-container)  │
└─────────────────────────────────────────────────────┘
```

## Quick Start

1. Copy `.env.example` to `.env` and fill in secrets:
   ```bash
   cp .env.example .env
   ```

2. Deploy Quadlet files to systemd user directory:
   ```bash
   cp containers/* ~/.config/systemd/user/
   cp volumes/* ~/.config/systemd/user/
   cp networks/*.network ~/.config/systemd/user/
   ```

3. Reload and enable:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now nextcloud-db nextcloud-redis nextcloud-app nextcloud-cron nextcloud-push nextcloud-preview-generator nextcloud-web
   ```

4. Verify:
   ```bash
   podman ps
   systemctl --user list-units --type=service | grep nextcloud
   ```

## Image Building

Build and push the custom Nextcloud image via GitHub Actions:

```bash
# Push to trigger the build workflow
git push origin main
```

The image will be published to:
```
ghcr.io/MArpogaus/service-nextcloud/my-nextcloud:latest
```

### Local Build (for testing)

```bash
podman build -t my-nextcloud:latest -f Containerfile .
```

## Volume Labels

| Volume | Purpose | SELinux |
|---|---|---|
| `nc-db` | PostgreSQL data | `:Z` (private) |
| `nc-app-html` | Nextcloud files (shared) | `:z` (shared) |
| `nc-app-apps` | Custom apps | `:z` (shared) |
| `nc-app-config` | Nextcloud config | `:z` (shared) |
| `nc-app-logs` | Log files | `:z` (shared) |
| `nc-web-cache` | Nginx cache | `:ro,z` |
| `nextcloud-data` | User data | `:z` (shared) |

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DB_ROOT_PASSWORD` | PostgreSQL superuser password | — |
| `DB_NAME` | Database name | `nextcloud` |
| `DB_USER` | Database user | `nextcloud` |
| `DB_PASSWORD` | Database user password | — |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Trusted domain(s) | — |
| `NEXTCLOUD_URL` | Public URL | — |
| `NEXTCLOUD_ADMIN_USER` | Admin username (first run) | — |
| `NEXTCLOUD_ADMIN_PASSWORD` | Admin password (first run) | — |
| `PHP_MAX_REQUESTS` | PHP-FPM max requests per child | `50` |

## Reverse Proxy

Bunkerweb proxies to `http://nextcloud-web:80` via shared bridge network `shared-network`.

## SELinux

All volumes use proper SELinux labels:
- Database volumes: `:Z` (private relabel)
- Shared app volumes: `:z` (shared relabel)
- Read-only mounts: `:ro,z`
