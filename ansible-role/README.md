# Nextcloud Service Ansible Role

Deploy Nextcloud Quadlet services via Ansible.

## Variables

| Variable | Default | Description |
|---|---|---|
| `nextcloud_service_user` | `nextcloud` | Service account username |
| `nextcloud_service_home` | `/var/services/nextcloud` | Home directory |
| `nextcloud_deploy_nginx_config` | `true` | Deploy nginx.conf |

## Usage

```yaml
# In your playbook
- hosts: all
  roles:
    - role: nextcloud_service
      nextcloud_service_user: nextcloud
      nextcloud_service_home: /var/services/nextcloud
```

## Files Deployed

- Quadlet container definitions (`.container`)
- Volume definitions (`.volume`)
- Network definitions (`.network`)
- nginx.conf (optional)

## Requirements

- Ansible 2.21+
- Target system with systemd user instances
- Quadlet support (Podman 4.0+)
