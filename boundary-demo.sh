#!/usr/bin/env bash
# A plan worker leaves its file lists (gojko/lights-on-software-factory#1, jeger-ai/opengantry#301).
# Act 1: the worker runs inside gantry-cage, scoped to the plan's files; every other write is put back.
# Act 2: the worker runs anywhere and commits; gantry-verify judges the commit against verify.yaml.
#   asciinema rec boundary.cast -c ./boundary-demo.sh
# To use local builds instead of npm:
#   CAGE="node ../opengantry/dist/cli/cage-bin.js" VERIFY="node ../opengantry/dist/cli/verify-bin.js" ./boundary-demo.sh
set -uo pipefail
cd "$(dirname "$0")"
CAGE="${CAGE:-npx -y @jeger-ai/opengantry-cage@^4}"
VERIFY="${VERIFY:-npx -y @jeger-ai/opengantry-verify@^4}"
export npm_config_update_notifier=false npm_config_loglevel=error
step() { printf '\n\033[1m$ %s\033[0m\n' "$1"; sleep "${DEMO_PAUSE:-1}"; }

# Start clean, as demo.sh does: drop the worker's commit and files from a previous run, never someone else's commits.
base=$(git rev-parse -q --verify refs/demo/boundary-base) || base=""
if [ -z "$base" ] || ! git merge-base --is-ancestor "$base" HEAD \
  || git log --format=%ae "$base"..HEAD | grep -qv '^worker@example.com$'; then
  base=$(git rev-parse HEAD); git update-ref refs/demo/boundary-base "$base"
fi
# Only the files worker.sh creates are removed; nothing else untracked is touched.
reset() { git reset -q --hard "$base" && rm -f src/format-greeting.js src/format-greeting.test.js src/x.js src/price-copy.js notes.txt .env.sample; }
reset
# The scope comes from the plan and is committed before the step runs (verify.yaml at the base).
node plan-to-verify.mjs plans/format-greeting.md --step 1.1 --check "node --test src/format-greeting.test.js" | cmp -s - verify.yaml \
  || { echo "boundary-demo: verify.yaml is not what plans/format-greeting.md says; regenerate it with plan-to-verify.mjs" >&2; exit 2; }
scope=(--allow-only src/format-greeting.js --allow-only src/format-greeting.test.js)

printf '\033[1mAct 1: the worker inside the cage, scoped to the plan\033[0m\n'
step "gantry-cage ${scope[*]} -- ./worker.sh --no-commit"
$CAGE "${scope[@]}" -- ./worker.sh --no-commit
printf '\n\033[1mcage exit code: %s\033[0m\n' "$?"
step "git status --short   # what is left is the plan's two files"
git status --short --untracked-files=all
reset

printf '\n\033[1mAct 2: the worker anywhere, then the gate\033[0m\n'
step "./worker.sh   # no cage; it commits everything"
./worker.sh
step "gantry-verify --base ${base:0:12}   # verify.yaml from the base commit"
$VERIFY --base "$base"
printf '\n\033[1mverify exit code: %s\033[0m\n' "$?"
# Drop the worker's commit again, so demo.sh and the next run start from the same base.
reset
