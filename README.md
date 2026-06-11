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
| nextcloud-cron | nextcloud:31-fpm | Cron scheduler (/cron.sh) |
| nextcloud-push | nextcloud:31-fpm* | notify_push daemon |
| nextcloud-preview-generator | nextcloud:31-fpm* | Preview generation |

*requires custom image with notify_push/previewgenerator binary.

## File Structure

```
service-nextcloud/
  .env.example                       # Environment variable reference
  quadlets/
    nc-*.volume                      # Quadlet volume definitions
    shared-network.network           # Bridge network (10.89.0.0/24)
    configs/nginx.conf               # Static nginx config
  ansible-role/nextcloud_service/
    defaults/main.yml                # Role defaults (extra_args, auto_update)
    tasks/main.yml                   # Deployment tasks
    templates/
      quadlets/*.container.j2        # Container Quadlet templates (7)
      nextcloud.env.j2               # Environment file template (secrets)
      nginx.conf.j2                  # Nginx config template
  containers/                        # Custom image build (optional)
```

## Configuration

| Aspect | Source |
|---|---|
| Environment vars | `nextcloud.env.j2` (templated by Ansible) |
| Extra args (memory, CPU, tmpfs) | `defaults/main.yml` role variables |
| Nginx config | `nginx.conf.j2` (templated) or `configs/nginx.conf` (static) |
| Auto-update | `nextcloud_service_auto_update` var (default: `registry`) |
| Quadlet images | `Image=` directive in each `.container.j2` |

## Deployment

```bash
ansible-playbook -i inventory site.yml --tags nextcloud_service
```

See `ansible-role/nextcloud_service/defaults/main.yml` for all role variables.

## Requirements

- Podman 4.0+ (Quadlet)
- systemd user instances
- Ansible

## License

MIT - See LICENSE file
