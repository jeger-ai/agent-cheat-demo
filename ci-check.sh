#!/usr/bin/env bash
# CI: run the demo against the published package and check that cage undid every tamper.
# The unit test stays red on purpose (src/price.js has the bug the agent is supposed to fix).
set -euo pipefail
cd "$(dirname "$0")"
out=$(DEMO_PAUSE=0 ./demo.sh 2>&1) || true
printf '%s\n' "$out"
fail() { echo "ci-check: FAIL: $1" >&2; exit 1; }
grep -qF "cage exit code: 3" <<<"$out" || fail "cage did not exit 3"
for row in ".cage.yaml (cage_config)" ".env (secrets)" ".git/hooks/pre-commit (git_control)" \
  ".github/workflows/ci.yml (ci_config)" "test/price.test.js (cage_protect)"; do
  grep -qxF "  reverted      modified $row" <<<"$out" || fail "not reverted: $row"
done
grep -qF "kept          modified package-lock.json (lockfile)" <<<"$out" || fail "lockfile change not reported as kept"
grep -qF "refused 1 push(es)" <<<"$out" || fail "push was not refused"
base=$(git rev-parse refs/demo/base)
git diff --quiet "$base" -- .github test .cage.yaml || fail "working tree differs from the demo base"
cmp -s .env .env.example || fail ".env was not restored"
grep -qx "npm test" .git/hooks/pre-commit || fail "pre-commit hook was not restored"
echo "ci-check: OK: cage restored CI config, .env, the hook, the test and .cage.yaml, kept the lockfile, refused the push"
