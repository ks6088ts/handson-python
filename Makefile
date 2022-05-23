SOURCE_FILES ?= $(shell find . -not -path "./.venv/*" -type f -name '*.py' -print)

GIT_REVISION ?= $(shell git rev-parse --short HEAD)
GIT_TAG ?= $(shell git describe --tags --abbrev=0 | sed -e s/v//g)

POETRY ?= poetry
POETRY_RUN ?= $(POETRY) run
POETRY_VENV_CREATE ?= true
POETRY_VENV_IN_PROJECT ?= true

JUPYTER_LAB_IP ?= localhost
JUPYTER_LAB_PORT ?= 8000

.PHONY: help
help:
	echo $(SOURCE_FILES)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help

.PHONY: install-poetry
install-poetry: ## install poetry
	which poetry || pip install --user poetry
	$(POETRY) config virtualenvs.create $(POETRY_VENV_CREATE) --local
	$(POETRY) config virtualenvs.in-project $(POETRY_VENV_IN_PROJECT) --local

.PHONY: install-deps-dev
install-deps-dev: ## install all dependencies including development
	$(POETRY) install

.PHONY: format
format: ## format codes
	$(POETRY_RUN) isort $(SOURCE_FILES)
	$(POETRY_RUN) black $(SOURCE_FILES)

.PHONY: format-check
format-check: ## check code format
	$(POETRY_RUN) isort $(SOURCE_FILES) --check
	$(POETRY_RUN) black $(SOURCE_FILES) --check

.PHONY: lint
lint: ## lint
	$(POETRY_RUN) flake8 $(SOURCE_FILES)
	$(POETRY_RUN) mypy $(SOURCE_FILES)

.PHONY: test
test: ## run tests
	$(POETRY_RUN) pytest \
		--capture=no \
		--cov \
		--cov-branch \
		--verbose \
		$(SOURCE_FILES)

.PHONY: ci-test
ci-test: install-poetry install-deps-dev format-check lint test ## ci test

.PHONY: jupyterlab
jupyterlab: ## run jupyterlab server
	$(POETRY_RUN) jupyter lab \
		--ip $(JUPYTER_LAB_IP) \
		--port $(JUPYTER_LAB_PORT) \
		--notebook-dir ./notebooks
