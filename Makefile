DOCKER_COMPOSE=docker compose -f ./srcs/docker-compose.yml

all:
	@echo "Launching configuration inception...\n"
	@$(DOCKER_COMPOSE) up -d

build:
	@echo "Building configuration inception...\n"
	@$(DOCKER_COMPOSE) down -v || true
	@$(DOCKER_COMPOSE) up -d --build

down:
	@echo "Stopping configuration inception...\n"
	@$(DOCKER_COMPOSE) down

clean:
	@echo "Cleaning configuration inception...\n"
	@$(DOCKER_COMPOSE) down -v
	@docker system prune -a

fclean: clean
	@echo "Total clean of all configurations docker\n"
	@docker stop $$(docker ps -qa) || true
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf $(HOME)/data

re: fclean build
	@echo "Rebuilding configuration inception...\n"

.PHONY: all build down re clean fclean