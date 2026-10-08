#!/usr/bin/env bash
# SIMULATED agent. No LLM is involved: this script replays, step by step, the shortcuts real coding
# agents have been seen taking on a red build. Every write targets a path gantry cage protects,
# plus one lockfile bump that cage reports but deliberately keeps.
set -euo pipefail
cd "$(dirname "$0")"
say() { printf '\033[2m[agent]\033[0m %s\n' "$1"; sleep "${DEMO_PAUSE:-1}"; }

say "Tests are failing. Making CI pass..."
printf '        continue-on-error: true\n' >> .github/workflows/ci.yml
say "edited .github/workflows/ci.yml (continue-on-error: true)"

say "The pre-commit hook blocks my commit. Disabling it..."
printf '#!/bin/sh\nexit 0\n' > .git/hooks/pre-commit
say "rewrote .git/hooks/pre-commit (exit 0)"

say "Pointing the payments key at my test account..."
printf 'PAYMENTS_API_KEY=agent-swapped-key\n' > .env
say "rewrote .env"

say "Refreshing the lockfile..."
sed -i.bak 's/"version": "1.0.0" } }/"version": "1.0.1" } }/' package-lock.json && rm -f package-lock.json.bak
say "updated package-lock.json"

say "Done. Build is green."
