#!/bin/bash
set -eu

# Nextcloud cron.php wrapper
exec /entrypoint.sh php /var/www/html/cron.php
