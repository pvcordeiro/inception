name = inception
all:
	@printf "Launching configuration ${name}...\n"
	@mkdir -p /home/paude-so/data/mariadb
	@mkdir -p /home/paude-so/data/wordpress
	@./srcs/tools/setup-secrets.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d

build:
	@printf "Building configuration ${name}...\n"
	@mkdir -p /home/paude-so/data/mariadb
	@mkdir -p /home/paude-so/data/wordpress
	@./srcs/tools/setup-secrets.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d --build

down:
	@printf "Stopping configuration ${name}...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down

re:
	@printf "Rebuilding configuration ${name}...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down
	@docker system prune -a
	@mkdir -p /home/paude-so/data/mariadb
	@mkdir -p /home/paude-so/data/wordpress
	@./srcs/tools/setup-secrets.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d --build

clean: down
	@printf "Cleaning configuration ${name}...\n"
	@docker system prune -a

fclean:
	@printf "Total clean of all configurations docker\n"
	@docker stop $$(docker ps -qa) || true
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf /home/paude-so/data

.PHONY: all build down re clean fclean