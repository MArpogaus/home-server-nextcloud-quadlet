# service-nextcloud

Nextcloud deployment with rootless Podman Quadlet, managed via Ansible.

## Architecture

7 containers on a `shared-network` bridge (10.89.0.0/24):

| Service | Image | Role |
|---|---|---|
| nextcloud-db | postgres:15 | PostgreSQL database |
| nextcloud-redis | redis:7 | Cache |
| nextcloud-app | nextcloud:31-fpm | PHP-FPM application |
| nextcloud-web | nginx:1.25 | Reverse proxy to app |
| nextcloud-cron | nextcloud:31-fpm | Cron scheduler (`/cron.sh`) |
| nextcloud-push | nextcloud:31-fpm | `notify_push` daemon |
| nextcloud-preview-generator | nextcloud:31-fpm | Preview generation |
| promtail-nc | grafana/promtail:3 | Log shipping sidecar |

## Task Reference (13 tasks)

| # | Module | Purpose | Rationale |
|---|--------|---------|-----------|
| 1 | `file` (loop 4) | Create data dirs (`db_data`, `data`, `config`, `bin`) | Pre-create volumes so Podman can mount them with correct selinux context |
| 2 | `copy` | Deploy `pre-snapshot-pg-dump.sh` | System-level DB dump before Btrfs snapshot for crash-consistent backup |
| 3-4 | `template` | Deploy `pg-dumpall.service` + `.timer` | Systemd oneshot on `OnCalendar=23:55` — DB dump before nightly snapshot |
| 5 | `systemd` | Enable+start pg_dumpall timer | Activate the DB dump schedule |
| 6 | `copy` (loop 4) | Deploy static Quadlet files (network, pod, promtail) | Shared network and pod definitions aren't templated |
| 7 | `template` (loop 7) | Render `.container.j2` → `.container` | Per-container images, volumes, env files, extra args injected via Jinja2 |
| 8 | `file` | Ensure `configs/` directory exists | Host path for bind-mounted config files |
| 9 | `copy` (loop 2) | Deploy static configs (`promtail-nc.yaml`, `docker.conf`) | Sidecar log config, PHP-FPM pool settings |
| 10 | `template` | Render `nginx.conf.j2` | Reverse proxy config with `client_max_body_size` |
| 11 | `template` | Render `nextcloud.env.j2` (mode 0600) | Runtime env vars: DB creds, admin user, PHP tuning, trusted domains |
| 12 | `command` | `machinectl shell ... systemctl --user daemon-reload` | Tell systemd user instance to re-read Quadlet files |
| 13 | `systemd` | Restart `user@<uid>.service` | Triggers Quadlet generator → creates/starts/restarts containers |

## Role Contract

Inherited from `site.yml`:

| Var | Description |
|---|---|
| `service_name` | `nextcloud` |
| `service_user` | `nextcloud` |
| `service_uid` | 82 (default) |
| `service_home` | `/var/services/nextcloud` |
| `service_repo` | `../service-nextcloud` |

## Configuration

| Aspect | Source |
|---|---|
| DB creds, admin, PHP, domains | `nextcloud.env.j2` (templated from `secrets/vars.yml`) |
| Per-container resource limits | `defaults/main.yml` via `nextcloud_service_*_extra_args` |
| Image tags (app/cron/push/preview) | `nextcloud_image` var (default `nextcloud:31-fpm`) |
| Auto-update policy | `nextcloud_service_auto_update` (default `registry`) |
| Nginx upload limit | `nextcloud_max_body_size` (default `15G`) |

## Generalization Gaps

Still hardcoded (configurable only by editing files):

| What | Where | Hardcoded |
|---|---|---|
| Postgres image tag | `nextcloud-db.container.j2` | `postgres:15` |
| Redis image tag | `nextcloud-redis.container.j2` | `redis:7` |
| Nginx image tag | `nextcloud-web.container.j2` | `nginx:1.25` |
| Promtail image tag | `promtail-nc.container` | `grafana/promtail:3` |
| Host port | `nc.pod` | `127.0.0.1:8080:80` |
| DB dump schedule | `pg-dumpall.timer.j2` | `OnCalendar=23:55:00` |
| DB dump retention | `pre-snapshot-pg-dump.sh` | `-mtime +30` |
| Loki endpoint | `promtail-nc.yaml` | `http://10.0.2.2:3100` |
| Network subnet | `shared-network.network` | `10.89.0.0/24` |
| Phone region | `phone.config.php` (in custom image) | `DE` |
| Preview config | `prev.config.php` (in custom image) | 1024px, scale 1 |

## Files

```
service-nextcloud/
  ansible-role/nextcloud_service/
    defaults/main.yml         # Role variables
    tasks/main.yml            # 13 tasks
    templates/                # nextcloud.env.j2, nginx.conf.j2, pg-dumpall.*.j2
    files/                    # Config PHP files, promtail, pre-snapshot script
  quadlets/
    nc.pod                    # Pod: publishes 127.0.0.1:8080:80
    shared-network.network    # Bridge 10.89.0.0/24
    nextcloud-*.container.j2  # 7 templated container files
    promtail-nc.container     # Static log shipper
    configs/                  # Static configs + templates
  containers/                 # Custom Nextcloud image (Containerfile, build scripts)
  .github/workflows/          # CI/CD image build + push
```

## Deployment

```bash
ansible-playbook -i inventory site.yml --tags nextcloud_service
```

## License

MIT
