#!/bin/bash

get_secret() {
    local secret_file="/run/secrets/$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        echo ""
    fi
}

ROOT_PASSWORD=$(get_secret "db_root_password")
if [ -z "$ROOT_PASSWORD" ]; then
    ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
fi

DB_PASSWORD=$(get_secret "db_password")
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD="$MYSQL_PASSWORD"
fi

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql
chmod 755 /run/mysqld

if [ ! -f "/var/lib/mysql/mysql/user.MYD" ]; then
    echo "Initializing MariaDB database..."
    
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql.sock &
    MYSQL_PID=$!
    
    until mysqladmin --socket=/tmp/mysql.sock ping >/dev/null 2>&1; do
        sleep 1
    done
    
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
    
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "MariaDB initialization completed"
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql
