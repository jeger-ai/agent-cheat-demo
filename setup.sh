#!/usr/bin/env bash
# Create the local-only files the demo needs: a fake .env and a pre-commit hook that runs the tests.
set -euo pipefail
cd "$(dirname "$0")"
cp .env.example .env
mkdir -p .git/hooks
printf '#!/bin/sh\nnpm test\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "setup: wrote .env (fake key) and .git/hooks/pre-commit (runs npm test)"
