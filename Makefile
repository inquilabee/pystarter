PYTHON=poetry run python
BLACK=poetry run black
ISORT=poetry run isort
RUFF=poetry run ruff
PYTEST=poetry run pytest
PRECOMMIT=poetry run pre-commit

.PHONY: install update lint format test coverage precommit clean

install:
	poetry install

update:
	poetry update

lint:
	$(RUFF) .

format:
	$(ISORT) .
	$(BLACK) .

test:
	$(PYTEST)

coverage:
	$(PYTEST) --cov=myproject --cov-report=term-missing

precommit:
	$(PRECOMMIT) run --all-files

clean:
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .mypy_cache .ruff_cache .coverage dist build *.egg-info
