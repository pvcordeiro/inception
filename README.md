# Inception

Containerized WordPress stack (NGINX + PHP-FPM + MariaDB) built **from scratch Dockerfiles**

## 🚀 Features
- Custom Debian-based images for each service
- WordPress + PHP-FPM 7.4 provisioned automatically via WP-CLI
- MariaDB initialized with database, users, and privileges
- NGINX reverse proxy with **self-signed TLS certificate** (HTTPS only)
- Host-bound persistent volumes:
  - `/home/$USER/data/mariadb` → MariaDB datadir
  - `/home/$USER/data/wordpress` → WordPress files (core + uploads)
- Clean, reproducible orchestration via `docker compose` and a `Makefile`

## 🔧 Services Overview
| Service   | Purpose | Exposed Internal Port | Container Starts After |
|-----------|---------|-----------------------|------------------------|
| mariadb   | Relational DB | 3306 | — |
| wordpress | PHP-FPM runtime + WordPress install | 9000 | mariadb |
| nginx     | TLS termination + static + reverse proxy (FastCGI to wordpress) | 443 | wordpress |

NGINX proxies PHP requests to `wordpress:9000` (FastCGI). Static assets are cached aggressively (1 year immutable) by config.

## 🔐 TLS
A self-signed certificate is generated at build time inside the NGINX image and served on port 443. Browsers will warn about trust (expected). For local development you may:
- Proceed through the browser warning, or
- Trust the certificate manually (optional).

## ⚙️ Environment Variables
Edit `.env` (create from `env_template.txt`).

| Variable | Description |
|----------|-------------|
| DOMAIN_NAME | Public hostname used in WP + NGINX (also used in `wp core install`). |
| MYSQL_DATABASE | WordPress database name. |
| MYSQL_USER / MYSQL_PASSWORD | Normal DB user + password for WordPress. |
| MYSQL_ROOT_PASSWORD | Root password set during MariaDB bootstrap. |
| WP_DB_HOST | Hostname of DB service (keep `mariadb`). |
| WP_ADMIN_USER / WP_ADMIN_PASSWORD / WP_ADMIN_EMAIL | Initial WordPress admin credentials. |
| WP_USER / WP_USER_PASSWORD / WP_USER_EMAIL | Additional non-admin author user created. |

Keep real secrets out of version control—commit only `env_template.txt`.

## 🛠 Prerequisites
- Docker Engine + Docker Compose Plugin
- GNU Make (optional but used for shortcuts)
- (Optional) Add `DOMAIN_NAME` to `/etc/hosts` for local resolution, e.g.:
  ```
  127.0.0.1   paude-so.42.fr
  ```
  (Mac users: The compose file uses `/home/$USER/...` paths—change to `/Users/$USER/...` if needed. See "Adapting Host Paths" below.)

## ▶️ Quick Start
```bash
# 1. Clone repository
# 2. Create working env file
cp srcs/env_template.txt srcs/.env
# 3. (Optional) Adjust DOMAIN_NAME and credentials
# 4. Ensure host data dirs exist (first run will auto-create via bind mount)
mkdir -p /home/$USER/data/mariadb /home/$USER/data/wordpress
# 5. Launch stack
make all   # or: docker compose -f ./srcs/docker-compose.yml up -d
```
Access: https://$DOMAIN_NAME (accept self-signed cert warning).

## 🔄 Lifecycle Commands (Makefile)
| Command | Action |
|---------|--------|
| `make all` | Start (build if missing) in detached mode. |
| `make build` | Force rebuild images + recreate containers. |
| `make down` | Stop and remove containers. |
| `make clean` | Down + remove named volumes in this project + prune images (interactive). |
| `make fclean` | Aggressive prune of ALL Docker artifacts + remove `~/data`. |
| `make re` | Full rebuild (fclean + build). |

## 🧹 Persistent Data
Data lives on the host outside containers (`/home/$USER/data/...`). Deleting containers doesn’t remove data. Use `make fclean` to wipe everything (including volumes + bind-mount directories).

## 🏗 Architecture Diagram
```
               HTTPS 443
 Browser ─────────────────▶ [ NGINX ]
                               │ FastCGI :9000
                               ▼
                         [ WordPress (PHP-FPM) ]
                               │ 3306 (internal)
                               ▼
                           [ MariaDB ]

 Host Bind Mounts:
   /home/$USER/data/wordpress  ↔  /var/www/html
   /home/$USER/data/mariadb    ↔  /var/lib/mysql
```

## 🔍 Troubleshooting
| Symptom | Check |
|---------|-------|
| Browser shows insecure cert | Expected (self-signed). Add exception or trust cert. |
| WordPress install repeats | WordPress dir not persisting → verify host bind path exists & permissions. |
| DB connection errors | Confirm `WP_DB_HOST=mariadb`, and matching MYSQL_* creds, then inspect MariaDB logs. |
| 403/404 on PHP pages | Ensure NGINX passes PHP: container `wordpress` healthy, FastCGI config intact. |

Common commands:
```bash
docker compose -f srcs/docker-compose.yml ps
docker logs wordpress -f
docker logs mariadb -f
docker exec -it mariadb mysql -u root -p
docker exec -it wordpress wp --info --allow-root
```

## 🧪 Verifications
On first successful run you should see:
- `WordPress setup completed` in `docker logs wordpress`
- MariaDB log line `Starting MariaDB...`
- HTTPS site loads with chosen site title.

## 🔄 Adapting Host Paths (macOS vs Linux)
The compose file uses `/home/${USER}`. On macOS typical home is `/Users/<name>`. Either:
1. Change the volume lines in `docker-compose.yml` to `/Users/${USER}/data/...`, or
2. Create a symlink: `sudo mkdir -p /home && sudo ln -s /Users/$USER /home/$USER`.

## 🛡 Security Notes
- Replace placeholder passwords before exposing beyond localhost.
- Self-signed cert unsuitable for production.
- Consider upgrading to a managed CA (e.g. Let's Encrypt) if deploying externally.

## ➕ Possible Enhancements
- Add healthchecks to services
- Add automatic certificate management (acme.sh / certbot)
- Introduce backup job for DB & uploads
- Add Docker image multi-stage slimming
- Support Redis object cache

## 📜 License
Educational project (42 Inception). Add a license file if planning public reuse.
