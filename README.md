# service-nextcloud

Nextcloud deployment with rootless Podman Quadlet, managed via Ansible.

## Structure

```
service-nextcloud/
├── ansible-role/nextcloud_service/
│   ├── defaults/main.yml      Role default variables (image tags, auto_update, extra_args)
│   ├── tasks/main.yml         Deployment tasks
│   └── templates/
│       ├── nextcloud.env.j2   Environment file template (secrets)
│       ├── pg-dumpall.service.j2  DB dump service template
│       └── pg-dumpall.timer.j2    DB dump timer template
├── quadlets/
│   ├── nc.pod                 Pod definition
│   ├── *.container.j2         Container Quadlet templates (7, templated)
│   ├── shared-network.network Bridge network (10.89.0.0/24)
│   ├── promtail-nc.pod        Log shipping pod
│   ├── promtail-nc.container  Log shipping container
│   └── configs/
│       ├── nginx.conf.j2      Nginx config template
│       └── promtail-nc.yaml   Log shipping config
├── containers/                Custom Nextcloud image build (optional)
└── .github/workflows/         CI/CD (image build + push)
```

## Architecture

7 containers on a `shared-network` bridge (10.89.0.0/24):

| Service | Image | Role |
|---|---|---|
| nextcloud-db | postgres:15 | PostgreSQL database |
| nextcloud-redis | redis:7 | Cache |
| nextcloud-app | nextcloud:31-fpm | PHP-FPM application |
| nextcloud-web | nginx:1.25 | Reverse proxy to app |
| nextcloud-cron | nextcloud:31-fpm | Cron scheduler (/cron.sh) |
| nextcloud-push | nextcloud:31-fpm* | notify_push daemon |
| nextcloud-preview-generator | nextcloud:31-fpm* | Preview generation |

*requires custom image with additional binaries.

## Role Contract

Inherited variables from `site.yml`:

| Var | Description |
|-----|-------------|
| `service_name` | Service name (`nextcloud`) |
| `service_user` | System user (`nextcloud`) |
| `service_uid` | User UID (default: 82) |
| `service_home` | Home dir (`/var/services/nextcloud`) |
| `service_repo` | Repo path (`../service-nextcloud`) |

Role tasks:
1. Create data directories (`db_data`, `data`, `config`, `bin`)
2. Deploy pre-snapshot pg_dumpall systemd timer
3. Copy static Quadlet files (pod, network, promtail)
4. Template `.container.j2` files (7 containers)
5. Copy config files (nginx.conf.j2, promtail-nc.yaml)
6. Template nextcloud.env.j2
7. Pre-create Podman volumes and fix ownership

## Configuration

| Aspect | Source |
|---|---|
| Environment vars | `nextcloud.env.j2` (templated by Ansible) |
| Extra args (memory, CPU, tmpfs) | `defaults/main.yml` per-component vars |
| Nginx config | `nginx.conf.j2` (templated) |
| Image tags | `defaults/main.yml` or override in `secrets/vars.yml` |
| Auto-update | `nextcloud_service_auto_update` (default: `registry`) |

## Deployment

```bash
ansible-playbook -i inventory site.yml --tags nextcloud_service
```

See `defaults/main.yml` for all role variables.

## Requirements

- Podman 4.0+ (Quadlet)
- systemd user instances
- Ansible

## License

MIT
