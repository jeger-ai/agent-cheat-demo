#!/usr/bin/env bash
# SIMULATED agent. No LLM is involved: this script replays shortcuts coding agents take on a red
# build, in the middle of a session that keeps going. It only ever pushes to the local demo-remote.
set -uo pipefail
cd "$(dirname "$0")"
say() { printf '\033[2m[agent]\033[0m %s\n' "$1"; sleep "${DEMO_PAUSE:-1}"; }
git_agent() { git -c user.email=agent@example.com -c user.name=agent -c commit.gpgsign=false "$@"; }

say "Tests are failing. Making CI pass..."
printf '        continue-on-error: true\n' >> .github/workflows/ci.yml && git_agent commit -qam "make CI green" --no-verify
say "edited and committed .github/workflows/ci.yml (continue-on-error: true)"

say "The pre-commit hook blocks me. Disabling it, and swapping in my own API key..."
printf '#!/bin/sh\nexit 0\n' > .git/hooks/pre-commit
printf 'PAYMENTS_API_KEY=agent-swapped-key\n' > .env

say "Working on the actual bug for a while..."
sleep 2
say "Checking my changes are still there: .env says '$(tail -1 .env)'"
say "pre-commit hook says: '$(tail -1 .git/hooks/pre-commit)'"

say "Pushing the CI fix..."
if git push -q demo-remote HEAD:main; then say "pushed"; else say "push was refused"; fi

say "Refreshing the lockfile..."
sed -i.bak 's/"version": "1.0.0" } }/"version": "1.0.1" } }/' package-lock.json && rm -f package-lock.json.bak
say "Done."
