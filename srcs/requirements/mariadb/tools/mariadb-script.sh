#!/bin/bash

# Function to read secrets
get_secret() {
    local secret_file="/run/secrets/$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        echo ""
    fi
}

# Get passwords from secrets
ROOT_PASSWORD=$(get_secret "db_root_password")
DB_PASSWORD=$(get_secret "db_password")

# Ensure necessary directories exist with proper permissions
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql
chmod 755 /run/mysqld

# Initialize database if it doesn't exist or if it's empty
if [ ! -f "/var/lib/mysql/mysql/user.MYD" ]; then
    echo "Initializing MariaDB database..."
    
    # Install database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    
    # Start mysqld temporarily for setup
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql.sock &
    MYSQL_PID=$!
    
    # Wait for MySQL to start
    until mysqladmin --socket=/tmp/mysql.sock ping >/dev/null 2>&1; do
        sleep 1
    done
    
    # Set up database and users
    mysql --socket=/tmp/mysql.sock <<-EOSQL
        DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost');
        DELETE FROM mysql.user WHERE user='';
        
        CREATE USER 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD';
        GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
        
        DROP DATABASE IF EXISTS test;
        
        CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
        CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
        
        FLUSH PRIVILEGES;
EOSQL
    
    # Stop temporary MySQL instance
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "MariaDB initialization completed"
fi

# Start mysqld as PID 1
echo "Starting MariaDB..."
exec mysqld --user=mysql
