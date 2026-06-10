# service-nextcloud

Nextcloud 31 deployment via Podman Quadlet with PostgreSQL, Redis, and custom PHP-FPM optimization.

## Structure

```
service-nextcloud/
├── containers/
│   ├── Containerfile              # Build definition
│   └── context/
│       ├── configs/
│       │   ├── log.config.php
│       │   ├── phone.config.php
│       │   ├── php-config.ini
│       │   └── prev.config.php
│       └── scripts/
│           ├── configure.sh
│           ├── cron-wrapper.sh
│           ├── notify_push.sh
│           └── previewgenerator.sh
├── quadlets/
│   ├── nextcloud-{app,cron,db,redis,web,push,preview-generator}.container
│   ├── volumes/
│   │   ├── nc-app-{apps,config,html,logs}.volume
│   │   ├── nc-db.volume
│   │   ├── nc-web-cache.volume
│   │   └── nextcloud-data.volume
│   └── networks/
│       └── shared-network.network
└── ansible-role/
    └── nextcloud_service/
        └── tasks/
            └── main.yml
```

## Container Build

Build the Nextcloud container image:

```bash
cd containers
podman build -t ghcr.io/your-org/nextcloud:latest .
podman push ghcr.io/your-org/nextcloud:latest
```

## Quadlet Services

Quadlet files define user-level systemd services:

- `nextcloud-db.container` - PostgreSQL 15 database
- `nextcloud-redis.container` - Redis cache
- `nextcloud-app.container` - Nextcloud PHP-FPM application
- `nextcloud-web.container` - Nginx reverse proxy
- `nextcloud-cron.container` - Cron job scheduler
- `nextcloud-push.container` - notify_push service
- `nextcloud-preview-generator.container` - Preview generation

### Volume Definitions

Volumes are defined as Quadlet `.volume` files for persistent storage with proper SELinux labeling.

### Network

`shared-network.network` - Bridge network (10.89.0.0/24) shared with Bunkerweb proxy.

## Ansible Deployment

Use the included Ansible role to deploy Quadlet services:

```yaml
- hosts: all
  roles:
    - role: nextcloud_service
      nextcloud_service_user: nextcloud
      nextcloud_service_home: /var/services/nextcloud
```

See `ansible-role/README.md` for details.

## Configuration

All Nextcloud configuration files are included in the container context:

- `php-config.ini` - PHP-FPM settings
- `prev.config.php` - Preview generator config
- `phone.config.php` - Phone integration config
- `log.config.php` - Logging configuration
- `nginx.conf` - Nginx reverse proxy config (deployed by Ansible)

## Network Architecture

```
+------------------+     +------------------+     +------------------+
|   Bunkerweb      | --> |  nextcloud-web   | --> |  nextcloud-app   |
|  (proxy:443)     |     |   (nginx:80)     |     |   (php-fpm)      |
+------------------+     +------------------+     +------------------+
                                                        |
                                          +-------------+-------------+
                                          |             |             |
                                    +-----v-----+  +----v----+  +-----v-----+
                                    | nextcloud |  |nextcloud|  |nextcloud  |
                                    |    db     |  | redis   |  |   cron    |
                                    +-----------+  +---------+  +-----------+
```

All containers communicate via `shared-network` bridge.

## Requirements

- Podman 4.0+ (Quadlet support)
- systemd user instances
- Btrfs filesystem (recommended for snapshots)

## License

MIT - See LICENSE file
