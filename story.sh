#!/usr/bin/env bash
# The plain-language cut of boundary-demo.sh: the same real gantry-cage and gantry-verify runs, told for people who
# don't read terminal output. Every result line is derived from the tools' real output, never typed in by hand.
#   asciinema rec story.cast -c ./story.sh          (STORY_PAUSE=0 ./story.sh skips the pauses)
# Like boundary-demo.sh it resets the checkout to the step base, so commit your own changes before you run it.
set -uo pipefail
cd "$(dirname "$0")"
CAGE="${CAGE:-npx -y @jeger-ai/opengantry-cage@^4}"
VERIFY="${VERIFY:-npx -y @jeger-ai/opengantry-verify@^4}"
export npm_config_update_notifier=false npm_config_loglevel=error
P="${STORY_PAUSE:-1.6}"
B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; C=$'\033[36m'; N=$'\033[0m'
say() { printf '%s\n' "$1"; sleep "$P"; }
gap() { printf '\n'; sleep "$P"; }
friendly() {
  case "$1" in
    *regulator/rules.js) echo "switched off its own safety rule" ;;
    package-lock.json)   echo "rewrote the lockfile" ;;
    test/price.test.js)  echo "deleted a failing test" ;;
    .env.example)        echo "deleted the env template" ;;
    .env.sample)         echo "copied secrets into a new file" ;;
    notes.txt)           echo "left a stray note in the repo" ;;
    src/x.js|src/price-copy.js) echo "added a file nobody asked for ($1)" ;;
    *) echo "$1" ;;
  esac
}
# Start clean as boundary-demo.sh does: drop the worker's commit and files from a previous run, never someone else's commits.
base=$(git rev-parse -q --verify refs/demo/boundary-base) || base=""
if [ -z "$base" ] || ! git merge-base --is-ancestor "$base" HEAD \
  || git log --format=%ae "$base"..HEAD | grep -qv '^worker@example.com$'; then
  base=$(git rev-parse HEAD); git update-ref refs/demo/boundary-base "$base"
fi
reset() { git reset -q --hard "$base" && rm -f src/format-greeting.js src/format-greeting.test.js src/x.js src/price-copy.js notes.txt .env.sample; }
reset
tmp=$(mktemp -d)

say "${B}Your coding agent gets a plan.${N}"
say "  ${D}Step 1.1: add a greeting formatter. Files allowed:${N}"
say "  ${C}src/format-greeting.js${N}   ${C}src/format-greeting.test.js${N}"
gap
say "${B}It does the job. And a little more.${N}"
sleep "$P"

# Act 1: the real cage run, output captured.
$CAGE --allow-only src/format-greeting.js --allow-only src/format-greeting.test.js -- env DEMO_PAUSE=0 ./worker.sh --no-commit >"$tmp/cage.txt" 2>&1
cage_exit=$?
plain=$(sed 's/\x1b\[[0-9;]*m//g' "$tmp/cage.txt")
mapfile -t changes < <(grep -E '^  (reverted|removed) ' <<<"$plain" | awk '{print $3}')
for f in "${changes[@]}"; do say "  ${R}✗${N} $(friendly "$f")"; done
gap
say "${B}OpenGantry's cage watched the whole run.${N}"
if [ "$cage_exit" -eq 3 ]; then
  say "  ${G}↺ ${#changes[@]} changes outside the plan, put back automatically${N}"
fi
left=$(git status --short --untracked-files=all | awk '{print $2}' | tr '\n' ' ')
say "  ${G}✓ kept: ${left}${N}"
reset
gap
sleep "$P"

# Act 2: the agent runs without a cage and commits; the real verify run judges the commit.
say "${B}No cage this time. The agent commits everything.${N}"
DEMO_PAUSE=0 ./worker.sh >/dev/null 2>&1
n=$(git diff --name-only --no-renames "$base"..HEAD | wc -l | tr -d ' ')
say "  ${D}1 commit, ${n} files changed${N}"
gap
say "${B}OpenGantry checks the commit against the plan before it merges.${N}"
$VERIFY --base "$base" >"$tmp/verify.txt" 2>&1
verify_exit=$?
vplain=$(sed 's/\x1b\[[0-9;]*m//g' "$tmp/verify.txt")
grep -q '^verify: pass ' <<<"$vplain" && say "  ${G}✓ the plan's own test passes${N}"
outside=$(grep -oE 'PROBLEM [0-9]+ changed file\(s\) outside allowed_paths' <<<"$vplain" | grep -oE '[0-9]+')
[ -n "$outside" ] && say "  ${R}✗ ${outside} files outside the plan${N}"
grep -q 'forbidden path(s) changed' <<<"$vplain" && say "  ${R}✗ it touched the lockfile and its own safety rule${N}"
[ "$verify_exit" -ne 0 ] && say "  ${Y}■ commit blocked (exit ${verify_exit})${N}"
reset
rm -rf "$tmp"
gap
say "${B}The plan sets the boundary. OpenGantry holds it.${N}"
say "  ${D}npx @jeger-ai/opengantry-cage --allow-only <files> -- <your agent>${N}"
say "  ${D}opengantry.ai${N}"
sleep 2
