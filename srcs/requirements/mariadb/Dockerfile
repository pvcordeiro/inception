FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb-script.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb-script.sh

EXPOSE 3306

CMD ["/usr/local/bin/mariadb-script.sh"]