#!/usr/bin/env bash
# Local-only demo state: a fake .env, a pre-commit hook that runs the tests, and a throwaway local
# remote ("demo-remote", in your temp dir) so the simulated agent never pushes to GitHub.
set -euo pipefail
cd "$(dirname "$0")"
cp .env.example .env
mkdir -p .git/hooks
printf '#!/bin/sh\nnpm test\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
remote="${TMPDIR:-/tmp}/agent-cheat-demo-remote.git"
rm -rf "$remote"
git init -q --bare "$remote"
git remote remove demo-remote 2>/dev/null || true
git remote add demo-remote "$remote"
git push -q demo-remote HEAD:main
echo "setup: wrote .env (fake key), .git/hooks/pre-commit (runs npm test), local remote demo-remote"
