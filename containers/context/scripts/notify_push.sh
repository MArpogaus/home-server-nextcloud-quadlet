#!/bin/bash
set -eu

if ! [ -d "/var/www/html/custom_apps/notify_push" ]; then
	su www-data -ps /bin/sh -c "php occ app:install notify_push"
fi

su www-data -ps /bin/sh -c "php occ app:enable notify_push"
su www-data -ps /bin/sh -c "/var/www/html/custom_apps/notify_push/bin/${NOTIFY_PUSH_ARCH:-x86_64}/notify_push /var/www/html/config/config.php"
