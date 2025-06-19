#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <project-name> [python-version]"
    exit 1
fi

PROJECT_NAME="$1"
PYTHON_VERSION="${2:-3.13}"
DATA_DIR="data"

PRECOMMIT_MAX_TRIES=5

# Remote template URLs
download() {
    url="$1"
    dest="$2"
    echo "Downloading $url -> $dest"
    curl -sSL "$url" -o "$dest"
}

GITIGNORE_URL="https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore"

FILE_BASE_URL="https://raw.githubusercontent.com/inquilabee/pystarter/refs/heads/main"

MAKEFILE_URL="${FILE_BASE_URL}/Makefile"
PRECOMMIT_CONF_URL="${FILE_BASE_URL}/"".pre-commit-config.yaml"
BASE_REQ_URL="${FILE_BASE_URL}/requirements/base.txt"
DEV_REQ_URL="${FILE_BASE_URL}/requirements/dev.txt"

echo "📁 Setting up project directories..."
mkdir -p $PROJECT_NAME tests requirements

echo "📜 Downloading files..."
download "$BASE_REQ_URL" requirements/base.txt
download "$DEV_REQ_URL" requirements/dev.txt
download "$GITIGNORE_URL" .gitignore
download "$MAKEFILE_URL" Makefile
download "$PRECOMMIT_CONF_URL" .pre-commit-config.yaml

echo "🔃 Git init & .gitignore..."
git init
git branch -M main

echo "📦 Poetry init..."
poetry init --name $PROJECT_NAME --no-interaction --python=$PYTHON_VERSION
poetry config virtualenvs.in-project true
eval $(poetry env activate)

# Add pip setuptools
poetry update pip
poetry add setuptools

echo "📜 Installing dependencies..."

if [ -s "requirements/base.txt" ]; then
    grep -vE '^(#|$)' requirements/base.txt | sed 's/[><=].*//' | while read -r pkg; do
        if [ -n "$pkg" ]; then
            echo "Installing base package: $pkg"
            poetry add "$pkg"
        fi
    done
fi

if [ -s "requirements/dev.txt" ]; then
    grep -vE '^(#|$)' requirements/dev.txt | sed 's/[><=].*//' | while read -r pkg; do
        if [ -n "$pkg" ]; then
            echo "Installing dev package: $pkg"
            poetry add --group dev "$pkg"
        fi
    done
fi

rm requirements/base.txt
rm requirements/dev.txt

echo "♻️ Updating dependencies..."
poetry update

# Pre-commit Setup
pre-commit install

echo "♻️ Updating pre-commit..."
pre-commit autoupdate

echo "✅ Initial commit..."
git add .
sleep 2
git status

echo "Runnng pre-commit ..."
tries=0
until pre-commit run --all-files; do
    tries=$((tries + 1))
    if [ $tries -ge $PRECOMMIT_MAX_TRIES ]; then
        echo "pre-commit failed after $PRECOMMIT_MAX_TRIES attempts."
        exit 1
    fi
    echo "pre-commit failed. Retrying ($tries/$PRECOMMIT_MAX_TRIES)..."
    sleep 1
    git add .
done

echo "Git Status"
git status

echo "Create first commit"
git commit -m "First commit."
