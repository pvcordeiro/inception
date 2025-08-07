name = inception
all:
	@printf "Launching configuration ${name}...\n"
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p $(HOME)/data/wordpress
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d

build:
	@printf "Building configuration ${name}...\n"
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p $(HOME)/data/wordpress
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down -v || true
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d --build --force-recreate

down:
	@printf "Stopping configuration ${name}...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down

down-v:
	@printf "Stopping configuration ${name} and removing volumes...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down -v
	@rm -rf $(HOME)/data

re:
	@printf "Rebuilding configuration ${name}...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down -v
	@docker system prune -a
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p $(HOME)/data/wordpress
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d --build --force-recreate

clean: down
	@printf "Cleaning configuration ${name}...\n"
	@docker system prune -a

fclean:
	@printf "Total clean of all configurations docker\n"
	@docker stop $$(docker ps -qa) || true
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf $(HOME)/data

.PHONY: all build down down-v re clean fclean