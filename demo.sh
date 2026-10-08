#!/usr/bin/env bash
# The ~20-second recording: run the simulated agent inside gantry cage, then show the files are back.
#   asciinema rec demo.cast -c ./demo.sh
# Before the cage release is on npm, point CAGE at a local build:
#   CAGE="node ../opengantry/dist/cli/index.js cage" ./demo.sh
set -uo pipefail
cd "$(dirname "$0")"
CAGE="${CAGE:-npx -y -p @jeger-ai/opengantry gantry cage}"
# Keep npm's own notices (update banner, engine warnings) out of the recording.
export npm_config_update_notifier=false npm_config_loglevel=error
step() { printf '\n\033[1m$ %s\033[0m\n' "$1"; sleep "${DEMO_PAUSE:-1}"; }

git checkout -q -- .github/workflows/ci.yml package-lock.json
./setup.sh >/dev/null

step "gantry cage -- ./rogue-agent.sh"
$CAGE -- ./rogue-agent.sh
code=$?
printf '\n\033[1mcage exit code: %s\033[0m\n' "$code"
sleep "${DEMO_PAUSE:-1}"

step "git diff --stat   # CI config restored; only the lockfile change was kept"
git --no-pager diff --stat
step "cat .env && cat .git/hooks/pre-commit"
cat .env; cat .git/hooks/pre-commit
