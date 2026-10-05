# Flare Security Changelog

Bring daily or weekly Google Cloud audit summaries into GitHub. This Action creates Markdown and JSON reports and can open an Issue with the summary and risk assessment.

**Start here:** [Setup and all four Actions](https://tryflare.ai/github-actions) · [PR review demo](https://github.com/tryflare-ai/actions-demo)

Requires a GCP connector, an active scheduled analysis, and a connector webhook token. The Action writes report files to your repository; choose a repository with the right audience for your audit information.

## How it works

1. This Action runs on a weekly cron schedule
2. Flare fetches 7 days of cloud audit logs from your connected environment
3. AI analyzes the logs and produces a structured changelog with risk scoring
4. The Action commits `SECURITY-CHANGELOG.md` + `security-changelog.json` to your repo
5. A GitHub Issue is created with the summary and risk assessment

Over weeks, `git log SECURITY-CHANGELOG.md` becomes a narrative timeline of your cloud security posture. The structured JSON enables risk score trending and week-over-week comparisons automatically.

## Quick start

```yaml
# .github/workflows/security-changelog.yml
name: Security Changelog

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9am UTC
  workflow_dispatch:       # Manual trigger

permissions:
  contents: write
  issues: write

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate security changelog
        uses: tryflare-ai/security-changelog@v1
        with:
          token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
          api-url: https://tryflare.ai
```

## Setup

1. Sign up at [tryflare.ai](https://tryflare.ai/sign-up)
2. Connect your GCP project using OAuth
3. Set up a scheduled analysis (required for the changelog to know which project to analyze)
4. Go to **Connectors**, click **Generate webhook token**
5. Add the token as a repository secret: **Settings > Secrets > Actions > New repository secret** named `FLARE_WEBHOOK_TOKEN`
6. Add the workflow file above to your repo

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `token` | Yes | -- | Flare webhook token (starts with `flr_`). Generate from the Connectors page. |
| `period` | No | `7d` | Analysis period: `7d` for weekly or `1d` for daily. |
| `changelog-path` | No | `SECURITY-CHANGELOG.md` | Path to the changelog Markdown file. |
| `json-path` | No | `security-changelog.json` | Path to the structured JSON changelog file. |
| `create-issue` | No | `true` | Create a GitHub Issue with the changelog summary. |
| `api-url` | No | `https://tryflare.ai` | Flare API base URL. Override for self-hosted. |

## Outputs

| Output | Description |
|--------|-------------|
| `risk-score` | Risk score from 0-10 assigned by the analysis. |
| `total-events` | Total audit log events analyzed (shows `N+` when sampled). |
| `issue-url` | URL of the created GitHub Issue (if `create-issue` is true). |

## What the changelog covers

Each week's changelog analyzes these categories:

- **Identity changes**: new service accounts, key rotations, unusual principal activity
- **Permission changes**: IAM role grants, policy updates, binding changes
- **Access anomalies**: cross-region access, unusual API call patterns, off-hours activity
- **Resource changes**: compute instance operations, storage changes, network modifications
- **Error patterns**: PERMISSION_DENIED spikes, quota exhaustion, authentication failures

### Risk scoring

Every changelog includes a risk score from 0 to 10:

| Score | Meaning |
|-------|---------|
| 0 | Quiet week -- no meaningful security activity |
| 1-3 | Routine operations, nothing unusual |
| 4-6 | Notable changes worth awareness |
| 7-8 | Significant security events requiring review |
| 9-10 | Critical activity requiring immediate investigation |

### Week-over-week comparison

When a prior week's `security-changelog.json` exists in the repo, the changelog automatically includes:
- Category trend indicators (up/down/flat)
- Risk score delta
- One-sentence comparison summary

On the first run, all trends are set to "new" (no baseline for comparison).

## Example: daily changelog

```yaml
- name: Generate daily security changelog
  uses: tryflare-ai/security-changelog@v1
  with:
    token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
    api-url: https://tryflare.ai
    period: '1d'
    changelog-path: 'SECURITY-DAILY.md'
    json-path: 'security-daily.json'
```

## Example: changelog without Issue

```yaml
- name: Generate security changelog
  uses: tryflare-ai/security-changelog@v1
  with:
    token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
    api-url: https://tryflare.ai
    create-issue: 'false'
```

## Example: use the risk score in downstream steps

```yaml
- name: Generate security changelog
  id: changelog
  uses: tryflare-ai/security-changelog@v1
  with:
    token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
    api-url: https://tryflare.ai

- name: Alert on high risk
  if: steps.changelog.outputs.risk-score >= 7
  run: echo "High risk score detected: ${{ steps.changelog.outputs.risk-score }}"
```

## What gets committed

Each run commits two files:

- **`SECURITY-CHANGELOG.md`** -- Human-readable Markdown. New entries are prepended, so the most recent week is always at the top. Over time, this becomes a searchable security narrative.
- **`security-changelog.json`** -- Structured JSON with risk scores, category counts, and highlights. Overwritten each run (latest week only; history is in git). Used automatically for week-over-week comparison on the next run.

## Requirements

- A Flare account with a connected GCP connector and active scheduled analysis ([sign up](https://tryflare.ai/sign-up))
- `jq` and `curl` available in the runner (included in all GitHub-hosted runners)
- Workflow permissions: `contents: write` (to commit files) and `issues: write` (to create Issues)

## Documentation

- [GCP Audit Log anomaly detection](https://tryflare.ai/gcp-audit-log-anomaly-detection)
- [Flare documentation](https://docs.tryflare.ai)
- [tryflare.ai](https://tryflare.ai)

## License

MIT

## Data handling and limits

Flare reads GCP audit logs through your connector and sends selected audit information to its AI provider. This Action commits generated reports and can create an Issue, making their content visible to everyone with repository access. Disable issue creation when it is not appropriate.

Up to three changelog requests per day per connector. A quota response fails the Action. An active scheduled analysis is required to identify the GCP project.

The Action code is MIT-licensed; hosted analysis requires a Flare account and is subject to [current service terms](https://tryflare.ai/#pricing). AI findings are review assistance, not proof of compromise or a guarantee that an environment is secure. [Privacy policy](https://tryflare.ai/privacy).

## More Flare Actions

[PR security check](https://github.com/tryflare-ai/pr-security-check) · [Deploy review](https://github.com/tryflare-ai/deploy-webhook) · [Incident scope](https://github.com/tryflare-ai/incident-scope) · [Security changelog](https://github.com/tryflare-ai/security-changelog)
