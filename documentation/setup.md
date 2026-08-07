# Setup guide

What a project needs before `/flux:init`, and the one step the skill
cannot do for you: the review secret.

## Requirements

| Tool | Version | Used by | Check |
|---|---|---|---|
| `yq` | v4 (mikefarah) | the gate hook, to read `flux-config.yml` | `yq --version` |
| `gh` | 2.20 or later, authenticated | the issue, PR and review skills | `gh auth status` |

Two traps worth knowing:

- **`yq` has a namesake.** The Python package also called `yq` is a
  different tool with a different syntax. Flux needs the Go one from
  mikefarah. If `yq --version` does not print `mikefarah/yq`, install the
  binary from its GitHub releases.
- **Distribution packages of `gh` are often ancient.** Ubuntu's apt
  package can be several years behind and misses subcommands the skills
  use (`gh label`, `gh issue delete --yes`). Install from the official
  releases or the GitHub apt repository.

## The review secret

The automated PR review runs `claude-code-action` inside GitHub Actions.
That job needs its own credential, because a workflow has no access to
the session you are authenticated in locally. This is the only manual
step of the setup, and without it the review workflow fails at
authentication and no review is ever posted.

Two ways to provide it. Pick one.

### Option A: subscription token (recommended)

Uses your Claude subscription, no extra billing.

```shell
claude setup-token
```

The command requires a Claude subscription and prints a long-lived token.
Copy it, then store it as a repository secret:

```shell
gh secret set CLAUDE_CODE_OAUTH_TOKEN -R <owner>/<repo>
```

Paste the token when prompted. This matches the workflow template shipped
by flux, which reads `secrets.CLAUDE_CODE_OAUTH_TOKEN`.

### Option B: API key

Bills per use on the Claude API, useful if you have no subscription or
want the review isolated from your personal account.

```shell
gh secret set ANTHROPIC_API_KEY -R <owner>/<repo>
```

Then edit `.github/workflows/claude-review.yml` to swap the input:

```yaml
          # replace
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          # with
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Verify

```shell
gh secret list -R <owner>/<repo>
```

The secret name and its creation date appear; the value is never
displayed again, by design. The real check is the first PR: the review
workflow should complete and post a comment within a few minutes.

## Choosing the review model

The action has no dedicated model input. Set it through `claude_args` in
`claude-review.yml`:

```yaml
          claude_args: |
            --model claude-sonnet-5
            --allowedTools "…"
```

Pinning the model explicitly is deliberate: without it, the workflow
follows the CLI default, which changes between versions and silently
changes how your reviews behave. `claude-sonnet-5` is a good default for
PR review; a larger model is worth it only for consistently large or
architecture-heavy diffs.

## Troubleshooting

**The review workflow fails immediately.** Almost always the secret:
missing, misnamed, or set on the wrong repository. Compare
`gh secret list` with the input name in the workflow.

**The review never appears on PRs from forks.** Expected GitHub behavior,
not a flux issue: secrets are not exposed to workflows triggered by pull
requests from forks. Branches inside the repository are unaffected.

**The workflow used to work and now fails at authentication.** The token
was revoked or expired. Run `claude setup-token` again and re-set the
secret; nothing else needs to change.

**A job hangs then fails with "not acquired by Runner".** A GitHub
Actions infrastructure problem, unrelated to your configuration. Check
[githubstatus.com](https://www.githubstatus.com/) and re-run the job.

## What `/flux:init` handles for you

Everything else: `flux-config.yml` with the commands detected from your
stack, the gate script for CI runners, the three workflows, the
`CLAUDE.md` contract, the specs index, the GitHub labels, and automatic
deletion of merged branches. It also tells you if the review secret is
still missing.
