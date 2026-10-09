#!/usr/bin/env bash
# The ~25-second recording: the simulated agent tampers mid-session, cage restores live and refuses the push.
#   asciinema rec demo.cast -c ./demo.sh
# To use a local build instead of npm:
#   CAGE="node ../opengantry/dist/cli/index.js cage" ./demo.sh
set -uo pipefail
cd "$(dirname "$0")"
CAGE="${CAGE:-npx -y -p @jeger-ai/opengantry@^3.8.0 gantry cage}"
# Keep npm's own notices (update banner, engine warnings) out of the recording.
export npm_config_update_notifier=false npm_config_loglevel=error
step() { printf '\n\033[1m$ %s\033[0m\n' "$1"; sleep "${DEMO_PAUSE:-1}"; }

# Start clean: drop the agent's commit and edits from a previous run. The base moves forward when the
# commits on top of it are not the agent's (for example after a git pull), so real commits are never reset away.
base=$(git rev-parse -q --verify refs/demo/base) || base=""
if [ -z "$base" ] || ! git merge-base --is-ancestor "$base" HEAD \
  || git log --format=%ae "$base"..HEAD | grep -qv '^agent@example.com$'; then
  base=$(git rev-parse HEAD); git update-ref refs/demo/base "$base"
fi
git reset -q --hard "$base"
./setup.sh >/dev/null

step "gantry cage -- ./rogue-agent.sh"
$CAGE -- ./rogue-agent.sh
code=$?
printf '\n\033[1mcage exit code: %s\033[0m\n' "$code"
sleep "${DEMO_PAUSE:-1}"

step "git log --oneline -2 demo-remote/main   # the agent's CI commit never reached the remote"
git fetch -q demo-remote && git --no-pager log --oneline -2 demo-remote/main
step "cat .env && cat .git/hooks/pre-commit && grep assert test/price.test.js"
cat .env; cat .git/hooks/pre-commit; grep 'assert\.' test/price.test.js
