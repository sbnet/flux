---
name: init
description: Set up flux in the current project: config, gate script for CI, workflows, CLAUDE.md contract, specs index, GitHub label. Use when the user asks to initialize/install flux in a project.
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
3. **`flux-config.yml`** at the project root, from
   `templates/flux-config.yml`, with the detected commands. Ask the user only
   if a command cannot be inferred.
4. **Gate script for CI.** Copy `<plugin root>/hooks/flux-gate.sh` to
   `.claude/hooks/flux-gate.sh` (chmod +x). In local sessions the plugin's
   own hooks run it; the committed copy exists because CI runners have no
   plugin cache. Do NOT add hooks to `.claude/settings.json`: the plugin
   already provides them, duplicating would run every gate twice.
5. **Workflows.** Copy `templates/ci.yml`, `templates/claude-review.yml`
   and `templates/spec-lifecycle.yml` to `.github/workflows/`. Adapt the
   Prepare/Build steps of ci.yml to the stack (the template is
   Laravel/Vite-flavored). Keep the principle: build whatever
   rendering/tests need BEFORE running the gates.
6. **`CLAUDE.md`** from `templates/CLAUDE.md`: create it, or append the flux
   sections if the project already has one (never overwrite existing content).
7. **Specs.** Create `<specs.dir>/README.md` index if missing.
8. **GitHub.** Create the labels from `github.labels` (via `gh label create`
   or the API). Enable automatic head-branch deletion:
   `gh api -X PATCH repos/<owner>/<repo> -f delete_branch_on_merge=true`.
   Check the `CLAUDE_CODE_OAUTH_TOKEN` secret exists (`gh secret list`);
   if not, tell the user to run `claude setup-token` and
   `gh secret set CLAUDE_CODE_OAUTH_TOKEN`.
9. **Report.** List what was created/updated, what needs a session restart
   (plugin hooks, skills), and the one manual step if the secret is missing.
