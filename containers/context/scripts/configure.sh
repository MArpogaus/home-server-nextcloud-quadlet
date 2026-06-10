#!/bin/bash
set -ex

NC_PATH=/var/www/html
PHP_PATH=/usr/local/etc

# PHP-FPM optimization
FPMS=${PHP_MAX_CHILDREN:-20}
PMaxSS=$((FPMS*2/3))
PMinSS=$((PMaxSS/2))
PStartS=$(((PMaxSS+PMinSS)/2))

sed -i "s/pm.max_children =.*/pm.max_children = $FPMS/"             $PHP_PATH/php-fpm.d/www.conf
sed -i "s/pm.start_servers =.*/pm.start_servers = $PStartS/"        $PHP_PATH/php-fpm.d/www.conf
sed -i "s/pm.min_spare_servers =.*/pm.min_spare_servers = $PMinSS/" $PHP_PATH/php-fpm.d/www.conf
sed -i "s/pm.max_spare_servers =.*/pm.max_spare_servers = $PMaxSS/" $PHP_PATH/php-fpm.d/www.conf

[ $PHP_MAX_REQUESTS ]  && sed -i "s/;pm.max_requests = 500/pm.max_requests = $PHP_MAX_REQUESTS/" $PHP_PATH/php-fpm.d/www.conf

sed -i "s/;emergency_restart_threshold =.*/emergency_restart_threshold = 10/" $PHP_PATH/php-fpm.conf
sed -i "s/;emergency_restart_interval =.*/emergency_restart_interval = 1m/"   $PHP_PATH/php-fpm.conf
sed -i "s/;process_control_timeout =.*/process_control_timeout = 10s/"        $PHP_PATH/php-fpm.conf

echo executing default entrypoint
exec "$@"
