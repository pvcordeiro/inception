all:
	@printf "Launching configuration inception...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d

build:
	@printf "Building configuration inception...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down -v || true
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env up -d --build --force-recreate

down:
	@printf "Stopping configuration inception...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down

clean:
	@printf "Cleaning configuration inception...\n"
	@docker compose -f ./srcs/docker-compose.yml --env-file ./srcs/.env down -v
	@docker system prune -a

fclean: clean
	@printf "Total clean of all configurations docker\n"
	@docker stop $$(docker ps -qa) || true
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf $(HOME)/data

re: fclean build
	@printf "Rebuilding configuration inception...\n"

.PHONY: all build down re clean fclean