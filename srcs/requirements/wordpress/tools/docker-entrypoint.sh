#!/bin/bash
set -eo pipefail

echo "Waiting for database..."
until mysqladmin ping -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent; do
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
    sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" wp-config.php
    sed -i "s/username_here/$WORDPRESS_DB_USER/" wp-config.php
    sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" wp-config.php
    sed -i "s/localhost/$WORDPRESS_DB_HOST/" wp-config.php
    
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
