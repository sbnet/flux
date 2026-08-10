---
name: init
description: "Set up flux in the current project: config, gate script for CI, workflows, CLAUDE.md contract, specs index, GitHub label. Use when the user asks to initialize/install flux in a project."
---

# Skill: init

## Purpose

Scaffold everything a project needs to be flux-managed. Idempotent: on a
project that already has flux, refresh the managed files instead of
duplicating them.

The plugin root is two levels up from this skill's base directory; templates
live in `<plugin root>/templates/`.

## Steps

1. **Prerequisites.** Check `yq` (v4, mikefarah) and `gh` (≥ 2.20, authenticated)
   are available. Install or tell the user how before continuing.
2. **Detect the stack.** Look at the project (composer.json, package.json,
   pyproject.toml…) and derive the real commands for lint / static analysis /
   types / tests / build.
3. **`flux-config.yml`** at the project root. If it does not exist yet,
   create it from `templates/flux-config.yml` with the detected commands,
   asking the user only if a command cannot be inferred. If it already
   exists, do NOT regenerate it: diff its keys against the current
   template and add only the ones missing (new schema keys from a plugin
   update, e.g. `github.auto_review`), at the template's default. Never
   touch a key already present, that is the user's customization to keep.
4. **Gate script for CI.** Copy `<plugin root>/hooks/flux-gate.sh` to
   `.claude/hooks/flux-gate.sh` (chmod +x), overwriting unconditionally:
   this file is not meant to be hand-edited, so there is nothing local to
   preserve. Do NOT add hooks to `.claude/settings.json`: the plugin
   already provides them, duplicating would run every gate twice.
5. **Workflows.** For each of `templates/ci.yml`, `templates/claude-review.yml`
   and `templates/spec-lifecycle.yml`: if the target under
   `.github/workflows/` does not exist, copy it (adapting the Prepare/Build
   steps of ci.yml to the stack; the template is Laravel/Vite-flavored). If
   it already exists and differs from the template, these files are
   routinely hand-adapted (a custom `allowedTools`, a stack-specific build
   step), so do not overwrite silently: show a diff and ask the user
   whether to replace it, keep it, or merge by hand. Identical content
   needs no prompt.
6. **`CLAUDE.md`** from `templates/CLAUDE.md`: create it, or append the flux
   sections if the project already has one (never overwrite existing content).
7. **Specs.** Create `<specs.dir>/README.md` index if missing.
8. **GitHub.** Create the labels from `github.labels` (via `gh label create`
   or the API). Enable automatic head-branch deletion:
   `gh api -X PATCH repos/<owner>/<repo> -f delete_branch_on_merge=true`.
   Check the `CLAUDE_CODE_OAUTH_TOKEN` secret exists (`gh secret list`);
   if not, tell the user to run `claude setup-token` then
   `gh secret set CLAUDE_CODE_OAUTH_TOKEN -R <owner>/<repo>`, and point
   them to `documentation/setup.md` in the flux repository for the
   API-key alternative and troubleshooting.
9. **Report.** List what was created/updated, what needs a session restart
   (plugin hooks, skills), and the one manual step if the secret is missing.
