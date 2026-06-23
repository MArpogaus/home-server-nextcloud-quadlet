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

# PHP settings (upstream entrypoint handles memory_limit, upload_limit)
# Apply overrides that exist in base php.ini
sed -i "s/^max_execution_time =.*/max_execution_time = ${PHP_MAX_EXECUTION_TIME:-3600}/"  $PHP_PATH/php/php.ini
sed -i "s/^max_input_time =.*/max_input_time = ${PHP_MAX_INPUT_TIME:-3600}/"              $PHP_PATH/php/php.ini
sed -i "s/^max_file_uploads =.*/max_file_uploads = ${PHP_MAX_FILE_UPLOADS:-100}/"         $PHP_PATH/php/php.ini
sed -i "s/^allow_url_fopen =.*/allow_url_fopen = Off/"                                     $PHP_PATH/php/php.ini
sed -i "s/^display_errors =.*/display_errors = Off/"                                       $PHP_PATH/php/php.ini
sed -i "s/^expose_php =.*/expose_php = Off/"                                               $PHP_PATH/php/php.ini

# Security hardening via conf.d (settings that may not exist in base php.ini)
cat > "$PHP_PATH/php/conf.d/99-nextcloud-security.ini" <<'EOF'
session.use_strict_mode = On
session.cookie_httponly = On
session.cookie_secure = On
allow_url_include = Off
EOF

echo executing default entrypoint
exec "$@"
