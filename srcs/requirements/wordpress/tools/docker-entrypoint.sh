#!/bin/bash
set -eo pipefail

# Function to read secrets
get_secret() {
    local secret_file="/run/secrets/$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        echo ""
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
    
    # Download WordPress using the method that worked
    curl -o latest.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz
    
    # Create wp-config.php using the method that worked
    cp wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" wp-config.php
    sed -i "s/username_here/$WORDPRESS_DB_USER/" wp-config.php
    sed -i "s/password_here/$(get_secret db_password)/" wp-config.php
    sed -i "s/localhost/$WORDPRESS_DB_HOST/" wp-config.php
    
    echo "WordPress setup completed"
fi

# Change ownership
chown -R www-data:www-data /var/www/html

exec "$@"
