#!/bin/bash
set -eo pipefail

# Function to read secrets or fallback to environment
get_secret() {
    local secret_file="/run/secrets/$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        case "$1" in
            "db_password") echo "$MYSQL_PASSWORD" ;;
            *) echo "" ;;
        esac
    fi
}

# Wait for database to be ready
echo "Waiting for database..."
until mysqladmin ping -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$(get_secret db_password)" --silent; do
    sleep 1
done

echo "Database is ready!"

# Download WordPress if not already present
if [ ! -f wp-config.php ]; then
    echo "Setting up WordPress..."
    
    # Remove any existing files except our script
    find . -mindepth 1 ! -name 'docker-entrypoint.sh' -delete 2>/dev/null || true
    
    curl -o latest.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" wp-config.php
    sed -i "s/username_here/$WORDPRESS_DB_USER/" wp-config.php
    sed -i "s/password_here/$(get_secret db_password)/" wp-config.php
    sed -i "s/localhost/$WORDPRESS_DB_HOST/" wp-config.php
    
    # Install WordPress and create users
    wp core install --url="https://$DOMAIN_NAME" \
        --title="paude-so inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    
    # Create additional user
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
    
    echo "WordPress setup completed"
fi

# Change ownership
chown -R www-data:www-data /var/www/html

exec "$@"
