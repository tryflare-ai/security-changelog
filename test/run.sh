#!/usr/bin/env bash
# shellcheck disable=SC2016 # hostile strings are literal on purpose
# shellcheck source=test/lib.sh
# Smoke tests for action.yml. Usage: bash test/run.sh
. "$(dirname "$0")/lib.sh"

REPO_DIR="$WORK/repo"
mkdir -p "$REPO_DIR" && cd "$REPO_DIR" || exit 1
git init -q && git config user.email t@example.com && git config user.name test
git checkout -q -b main
git commit -q --allow-empty -m init
git init -q --bare "$WORK/remote.git"
git remote add origin "$WORK/remote.git"
git push -q origin HEAD:refs/heads/main
git branch -q --set-upstream-to=origin/main

CHANGELOG='docs/weird $(id) `id` changelog.md'
JSON='sec$(id).json'
mkdir -p docs

changelog_run() { # changelog_run <token>
  run_step 0 JSON_PATH="$JSON"
  local has_prior
  has_prior=$(output has_prior)
  run_step 1 FLARE_TOKEN="$1" FLARE_API_URL="$API/" PERIOD=7d HAS_PRIOR="$has_prior"
}

changelog_run flr_test_token
check "first run has no prior" "$(last_request | "$PY" -c 'import json,sys; print("prior_changelog" in json.load(sys.stdin)["body"])')" False
check "api step exits 0" "$RC" 0
check "risk-score output" "$(output risk-score)" 7.5
check "total-events output" "$(output total-events)" 1000

run_step 2 CHANGELOG_PATH="$CHANGELOG" JSON_PATH="$JSON"
check "update step exits 0" "$RC" 0
check "changelog created with header" "$(head -1 "$CHANGELOG")" "# Security Changelog"
check "markdown kept literal" "$(grep -c '100% sure: %s %n' "$CHANGELOG")" 1

run_step 3 CHANGELOG_PATH="$CHANGELOG" JSON_PATH="$JSON" PERIOD=7d
check "commit step exits 0" "$RC" 0
check "commit message" "$(git log -1 --format=%s)" "security: weekly changelog (risk: 7.5/10)"
check "commit pushed" "$(git rev-parse HEAD)" "$(git rev-parse origin/main)"

run_step 4 REPO=o/r
check "issue step exits 0" "$RC" 0
check "issue-url output" "$(output issue-url)" https://github.com/o/r/issues/1
check "risk label" "$(grep -c 'Security Changelog: 2026-09-28 to 2026-10-05 \[HIGH RISK\]' "$GH_LOG")" 1

changelog_run flr_test_token
check "second run sends prior changelog" \
  "$(last_request | "$PY" -c 'import json,sys; print(json.load(sys.stdin)["body"]["prior_changelog"]["risk_score"])')" 7.5

changelog_run ""
check "missing token fails" "$RC" 1

changelog_run bad-token-0000
check "invalid token fails" "$RC" 1

finish
