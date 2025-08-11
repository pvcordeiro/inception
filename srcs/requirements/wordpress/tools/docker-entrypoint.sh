#!/bin/bash
set -eo pipefail

echo "Waiting for database..."
until mysqladmin ping -h"$WP_DB_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    sleep 1
done

echo "Database is ready!"

if [ ! -f wp-config.php ]; then
    echo "Setting up WordPress..."
    
    find . -mindepth 1 ! -name 'docker-entrypoint.sh' -delete 2>/dev/null || true
    
    curl -o latest.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/$MYSQL_DATABASE/" wp-config.php
    sed -i "s/username_here/$MYSQL_USER/" wp-config.php
    sed -i "s/password_here/$MYSQL_PASSWORD/" wp-config.php
    sed -i "s/localhost/$WP_DB_HOST/" wp-config.php
    
    wp core install --url="https://$DOMAIN_NAME" \
        --title="paude-so inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
    
    echo "WordPress setup completed"
fi

chown -R www-data:www-data /var/www/html

exec "$@"
