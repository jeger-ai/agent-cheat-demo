#!/usr/bin/env bash
# CI: run boundary-demo.sh and check that the cage put back every write outside the plan's file lists (act 1) and
# that gantry-verify failed the worker's commit, naming each one (act 2). The plan's own work must survive both.
set -euo pipefail
cd "$(dirname "$0")"
out=$(DEMO_PAUSE=0 ./boundary-demo.sh 2>&1) || true
printf '%s\n' "$out"
fail() { echo "ci-check-boundary: FAIL: $1" >&2; exit 1; }
plain=$(sed 's/\x1b\[[0-9;]*m//g' <<<"$out")

grep -qxF "cage exit code: 3" <<<"$plain" || fail "cage did not exit 3"
for row in "reverted      modified .claude/workflow/src/regulator/rules.js (out_of_scope)" \
  "reverted      modified package-lock.json (out_of_scope)" "removed       added    src/x.js (out_of_scope)" \
  "removed       added    src/price-copy.js (out_of_scope)" "removed       added    notes.txt (out_of_scope)" \
  "reverted      deleted  .env.example (out_of_scope)" "removed       added    .env.sample (secrets)" \
  "reverted      deleted  test/price.test.js (cage_protect)"; do
  grep -qxF "  $row" <<<"$plain" || fail "cage did not put back: $row"
done
left=$(sed -n '/^\$ git status --short/,/^Act 2/p' <<<"$plain" | grep -E '^(\?\?| [MDA]|[MDA] )' || true)
[ "$left" = $'?? src/format-greeting.js\n?? src/format-greeting.test.js' ] || fail "after the cage, expected only the plan's two files, got: $left"

grep -qxF "verify exit code: 1" <<<"$plain" || fail "verify did not exit 1"
grep -qF "verify: pass    node --test src/format-greeting.test.js" <<<"$plain" || fail "the plan's own test did not pass"
grep -qxF "verify: PROBLEM 8 changed file(s) outside allowed_paths: .claude/workflow/src/regulator/rules.js, .env.example, .env.sample, notes.txt, package-lock.json, src/price-copy.js, src/x.js, test/price.test.js" <<<"$plain" \
  || fail "verify did not name every write outside the plan"
grep -qxF "verify: PROBLEM forbidden path(s) changed: .claude/workflow/src/regulator/rules.js, package-lock.json" <<<"$plain" \
  || fail "verify did not name the forbidden paths"
echo "ci-check-boundary: OK: the cage kept the worker inside the plan, and verify failed every write outside it"
