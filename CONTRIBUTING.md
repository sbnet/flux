# Contributing to Flux

## Repository layout

This repository is both a **plugin marketplace** and the **flux plugin**:

```
.claude-plugin/marketplace.json   # marketplace catalog (lists the plugin)
plugins/flux/                     # the plugin itself
├── .claude-plugin/plugin.json    # plugin manifest (name, version, license)
├── skills/                       # one directory per skill (SKILL.md)
├── agents/                       # subagents (reviewer, qa)
├── hooks/                        # hooks.json + flux-gate.sh
└── templates/                    # files the init skill copies into projects
documentation/                    # scoping study, annotated config reference
```

Key design rule: flux is a **convention and configuration layer** over
native Claude Code and GitHub primitives, not an engine. Before adding
machinery, check whether a hook, a skill, branch protection or a workflow
already does the job. See the
[scoping study](documentation/study-01-scoping.md).

## Development setup

```shell
git clone https://github.com/sbnet/flux
# In Claude Code, register your local clone as a marketplace:
/plugin marketplace add ./flux
/plugin install flux@flux
```

Edits to `SKILL.md` files take effect immediately in a session; changes to
`hooks/`, `agents/` or manifests need `/reload-plugins` or a restart.

Test a change against a real project: a Laravel or Node app with a
`flux-config.yml` at its root ([reference](documentation/flux-config.example.yml)).

## Versioning

Semver, bumped in **both** `plugins/flux/.claude-plugin/plugin.json` and the
plugin entry of `.claude-plugin/marketplace.json`, in the same commit as the
change:

- **patch**: fixes, docs, wording of skills
- **minor**: new skill, agent, template, or new config key (backward
  compatible)
- **major**: breaking change to `flux-config.yml` schema, hook behavior,
  or a skill's contract

Users pick up new versions with `/plugin marketplace update flux`.

Each version bump also gets a **git tag and a GitHub release** on the bump
commit, so the repository sidebar always shows the current version:

```shell
git tag -a vX.Y.Z -m "short summary"
git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z: short summary" --notes "…"
```

## Pull requests

- English everywhere: code, comments, commits, PR, docs.
- [Conventional commits](https://www.conventionalcommits.org/): the subject
  says what, the body says why.
- CI must pass: `claude plugin validate` (marketplace + plugin) and
  `shellcheck` on `flux-gate.sh`. Run both locally before pushing.
- One PR = one concern. Skills are written in imperative English, and stay
  thin: conventions and steps, not essays.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
