#!/bin/bash
set -e

PROJECT_NAME="myproject"
PYTHON_VERSION=">=3.13,<4.0"
DATA_DIR="data"

# Remote template URLs
download() {
  url="$1"
  dest="$2"
  echo "Downloading $url -> $dest"
  curl -sSL "$url" -o "$dest"
}

GITIGNORE_URL="https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore"
MAKEFILE_URL="https://gist.githubusercontent.com/inquilabee/e23e7418577b04cfea578088d579b82f/raw/eb0090031efa581d59fceee343304d97c60cd60e/Makefile"
PRECOMMIT_CONF_URL="https://gist.githubusercontent.com/inquilabee/485e066f6e76562b06d126a8d642ef79/raw/738c973ac73d1a10d74619dadfbb3c47f845263c/pre-commit-config.yaml"
BASE_REQ_URL="https://gist.githubusercontent.com/inquilabee/f1245d78da5ca6327053933b4412b96b/raw/7cb4eef61b450b5dad1928428acdca81ca88be4e/base.txt"
DEV_REQ_URL="https://gist.githubusercontent.com/inquilabee/69b5c55bbda8c3094e25b2654418ab82/raw/a0aa423b2354ce9d02e7d5c361c5f5a3c3e3401c/dev.txt"

echo "📁 Setting up project directories..."
mkdir -p $PROJECT_NAME tests
touch $PROJECT_NAME/__init__.py tests/__init__.py

echo "🔃 Git init & .gitignore..."
git init
download "$GITIGNORE_URL" .gitignore

echo "📄 Downloading Makefile..."
download "$MAKEFILE_URL" Makefile

echo "📦 Poetry init..."
poetry init --name $PROJECT_NAME --no-interaction --python=$PYTHON_VERSION
poetry config virtualenvs.in-project true

echo "📜 Downloading requirements..."
mkdir -p requirements
download "$BASE_REQ_URL" requirements/base.txt
download "$DEV_REQ_URL" requirements/dev.txt

echo "📜 Installing dependencies..."
if [ -s "requirements/base.txt" ]; then
  grep -vE '^(#|$)' requirements/base.txt | sed 's/[><=].*//' | xargs -r poetry add
fi

if [ -s "requirements/dev.txt" ]; then
  grep -vE '^(#|$)' requirements/dev.txt | sed 's/[><=].*//' | xargs -r poetry add --group dev
fi

echo "📄 Downloading pre-commit config..."
download "$PRECOMMIT_CONF_URL" .pre-commit-config.yaml
poetry run pre-commit install

echo "♻️ Updating dependencies..."
poetry update

echo "♻️ Updating pre-commit..."
pre-commit autoupdate

echo "Runnng pre-commit ..."
tries=0
max_tries=3
until pre-commit run --all-files; do
  tries=$((tries+1))
  if [ $tries -ge $max_tries ]; then
    echo "pre-commit failed after $max_tries attempts."
    exit 1
  fi
  echo "pre-commit failed. Retrying ($tries/$max_tries)..."
  sleep 1
done

echo "✅ Initial commit..."
git add .
git commit -m "Initial project setup with Poetry, linting, testing, and pre-commit"
