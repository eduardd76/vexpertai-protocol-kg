.DEFAULT_GOAL := help
COMPOSE := docker compose
PY := ./.venv/bin/python

.PHONY: help up seed browser demo reset down verify-lab

help:  ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-9s\033[0m %s\n",$$1,$$2}'

up:  ## Start Neo4j and wait until it is healthy
	$(COMPOSE) up -d
	@echo "Waiting for Neo4j to be healthy..."
	@i=0; until [ "$$(docker inspect -f '{{.State.Health.Status}}' vexpertai-neo4j 2>/dev/null)" = "healthy" ]; do \
		i=$$((i+1)); \
		if [ $$i -ge 30 ]; then \
			echo ""; \
			echo "Neo4j did not become healthy in time. Check: docker compose logs vexpertai-neo4j"; \
			exit 1; \
		fi; \
		sleep 2; printf "."; done; \
		echo " ready -> http://localhost:7474  (neo4j / password123)"

seed:  ## Create venv, install deps, load the design graph
	@test -d .venv || python3 -m venv .venv
	./.venv/bin/pip install -q -r requirements.txt
	$(PY) src/seed_loader.py

browser:  ## Open the Neo4j Browser
	@open http://localhost:7474 2>/dev/null || \
		xdg-open http://localhost:7474 2>/dev/null || \
		echo "Open http://localhost:7474 in your browser"

demo:  ## Print the 8 bounded graph views
	@test -x ./.venv/bin/python || { echo "Run 'make seed' first."; exit 1; }
	$(PY) src/demo.py

reset:  ## Reload the design dataset (your vexpertai-builder work is untouched)
	@test -x ./.venv/bin/python || { echo "Run 'make seed' first."; exit 1; }
	$(PY) src/seed_loader.py

down:  ## Stop Neo4j (data volume preserved)
	$(COMPOSE) down

verify-lab:  ## Check the lab Cypher blocks (lint always; live blast-radius if a seeded DB is up)
	@test -x ./.venv/bin/python || { echo "Run 'make seed' first."; exit 1; }
	$(PY) -m pytest tests/test_lab_cypher.py -rs -q
