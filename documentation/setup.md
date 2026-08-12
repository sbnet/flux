# Setup guide

What a project needs before `/flux:init`.

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

## Running the review

The PR review is not a GitHub Actions job: it runs locally, in a Claude
Code session, using the same `gh` authentication as the rest of the
skills. Nothing reviews a PR on its own, and there is no secret or
workflow to set up for it. Ask for it with:

```
/flux:review
```

for the current branch's PR, whenever a review is actually wanted, before
merging or again after further changes. It posts its findings as comments
on the PR, same as any other reviewer would.

## Staying in sync

Updating the plugin (see the [versioning section of
CONTRIBUTING.md](../CONTRIBUTING.md#versioning)) changes the marketplace
clone and, once repaired with `flux-doctor.sh`, which version your session
runs. It does not touch files `/flux:init` already copied into a project:
`flux-config.yml`, the two GitHub workflows, `flux-gate.sh`. Those only
change when `/flux:init` runs again.

So after updating the plugin, re-run `/flux:init` in every project that
was set up before the update, not just once globally. It is idempotent:
it fills in what's missing (a new `flux-config.yml` key at its template
default, a workflow that does not exist yet) and asks before touching a
workflow file that already exists and differs from the template, so
hand-adapted steps are not silently lost. `flux-config.yml` keys already
present are never overwritten, whatever the template default is.

## Troubleshooting

**A skill answers "Unknown command: /flux:&lt;name&gt;", or `/flux:feature`
does not exist while the marketplace is up to date.** The installed copy is
stale. Claude Code pins each plugin to one version in
`~/.claude/plugins/installed_plugins.json` and runs that pinned copy; the
pin does not always follow a marketplace update, and re-installing can
report success while changing nothing. Diagnose, then repair:

```shell
claude plugin marketplace update flux   # so the clone carries the script
bash ~/.claude/plugins/marketplaces/flux/scripts/flux-doctor.sh
bash ~/.claude/plugins/marketplaces/flux/scripts/flux-doctor.sh --fix
```

The first line matters when the doctor reports `No such file`: the script
ships with the marketplace clone, and a clone older than 0.5.4 does not
have it yet. The repair backs up `installed_plugins.json` next to itself
and prints the command to restore it. Restart the session afterwards: the
pin is read at startup, so `/reload-plugins` is not enough.

Note the shape of the symptom: because 0.5.0 renamed the skills
(`flux-feature` became `feature`), a stale pin shows up as a missing
command rather than as a wrong version, and the old names keep working.

**Why the pin goes stale.** A machine often carries two Claude Code builds,
the terminal CLI and the one bundled with the VS Code extension, and they
do not write `installed_plugins.json` the same way: one stores each plugin
as a list of entries carrying a `scope`, the other as a single object. A
`claude plugin install` typed in the terminal then writes a shape the
running session does not read, which is why it reports success and changes
nothing. The doctor prints which shape it found (`list form` or `object
form`) and repairs in place, without converting one into the other. This is
a Claude Code behavior flux works around, not a fix to the plugin manager.

**A job hangs then fails with "not acquired by Runner".** A GitHub
Actions infrastructure problem, unrelated to your configuration. Check
[githubstatus.com](https://www.githubstatus.com/) and re-run the job.

## What `/flux:init` handles for you

Everything else: `flux-config.yml` with the commands detected from your
stack, the gate script for CI runners, the two workflows, the
`CLAUDE.md` contract, the specs index, the GitHub labels, and automatic
deletion of merged branches.
