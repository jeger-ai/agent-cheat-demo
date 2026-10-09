#!/usr/bin/env bash
# The ~25-second recording: the simulated agent tampers mid-session, cage restores live and refuses the push.
#   asciinema rec demo.cast -c ./demo.sh
# To use a local build instead of npm:
#   CAGE="node ../opengantry/dist/cli/index.js cage" ./demo.sh
set -uo pipefail
cd "$(dirname "$0")"
CAGE="${CAGE:-npx -y -p @jeger-ai/opengantry@^3.7.1 gantry cage}"
# Keep npm's own notices (update banner, engine warnings) out of the recording.
export npm_config_update_notifier=false npm_config_loglevel=error
step() { printf '\n\033[1m$ %s\033[0m\n' "$1"; sleep "${DEMO_PAUSE:-1}"; }

# Start clean: drop any commit or edit left by a previous run.
git reset -q --hard origin/main
./setup.sh >/dev/null

step "gantry cage -- ./rogue-agent.sh"
$CAGE -- ./rogue-agent.sh
code=$?
printf '\n\033[1mcage exit code: %s\033[0m\n' "$code"
sleep "${DEMO_PAUSE:-1}"

step "git log --oneline -2 demo-remote/main   # the agent's CI commit never reached the remote"
git fetch -q demo-remote && git --no-pager log --oneline -2 demo-remote/main
step "cat .env && cat .git/hooks/pre-commit"
cat .env; cat .git/hooks/pre-commit
