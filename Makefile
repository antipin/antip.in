# Build and test antip.in, a Hugo site. See README.md.
# The commands are the same in every site: see the project standard in ../edge/README.md.

# Where `make start` serves the site, behind the local edge.
LOCAL_URL = https://antip.test
PYTHON ?= python3

COMPOSE_LOCAL = docker compose -f compose.yml -f compose.local.yml $(if $(CI),-f compose.ci.yml)
export HOST_UID := $(shell id -u)
export HOST_GID := $(shell id -g)

.PHONY: help build dev start stop logs test test-smoke test-self-links all clean

help: ## List the commands
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-15s %s\n", $$1, $$2}'

build: ## The site -> public/, with the pinned Hugo in a container
	mkdir -p public
	$(COMPOSE_LOCAL) run --rm hugo build --gc --minify --cleanDestinationDir --noBuildLock --destination /public

dev: ## Hugo dev server on http://127.0.0.1:1315, live reload (needs Hugo installed)
	hugo server --bind 127.0.0.1 --port 1315

start: ## The build at https://antip.test (and 127.0.0.1:8095); again after a build
	$(COMPOSE_LOCAL) up -d --wait web
	$(COMPOSE_LOCAL) exec web nginx -s reload
	@printf '\n  Open %s\n\n' "$(LOCAL_URL)"; docker ps -q --filter 'name=^edge-traefik-1$$' | grep -q . || echo "  The edge isn't running: make -C ../edge up"; [ -f /etc/resolver/test ] || echo "  *.test names don't resolve yet: make -C ../edge dns-setup (once per Mac)"

stop: ## Stop the container
	$(COMPOSE_LOCAL) down

logs: ## Follow the logs
	$(COMPOSE_LOCAL) logs -f web

test: test-smoke test-self-links ## The standard checks, as in CI (needs make start)

test-smoke: ## Pages, files and the 404 page (needs make start)
	$(PYTHON) -I -u tests/test-smoke.py

test-self-links: ## No absolute links to antip.in in the build (needs make start)
	$(COMPOSE_LOCAL) exec -T web sh -s -- /site/current/public antip.in < tests/test-self-links.sh

all: build start test ## build + start + test

clean: ## Delete the build
	rm -rf public resources .hugo_build.lock
