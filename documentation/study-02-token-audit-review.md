# Flux: Review of the token consumption audit

Second opinion on the audit "flux, token consumption optimization"
(2026-11-20, flux v0.11.0). Each claim was checked against the plugin
sources. The audit's recommendations are referred to by their ids (R1 to R10).

---

## 1. Verdict

The audit is sound. Its factual claims match the code:

- the 4 agents are pinned on `model: sonnet`;
- `flux-gate.sh` keeps only `tail -30` of a failing gate;
- `gates.on_edit` runs `pint --test` on the whole project, even when a
  Markdown spec is edited;
- `comment-triage` fetches raw comments through REST
  (`gh pr view --comments`, `gh api .../pulls/<n>/comments`);
- duke runs `reviewer` (step 3) and then always `pr-review`;
- `gh-pr` waits on `gh pr checks --watch --fail-fast` without filtering.

The "no model router in a hook" section and the list of rejected options are
correct and should stay as they are.

## 2. Keep as proposed

- **R7, targeted `on_edit` gate.** The best item of the audit, mostly for
  quality rather than tokens: today a style error in any file makes every
  edit fail, and the model ends up fixing files outside its scope. The hook
  already receives the tool input on stdin.
- **R2, GraphQL `reviewThreads`.** Also a quality gain: `isResolved` replaces
  a fragile inference from diffs.
- **R3, R6, R8.** Simple, low risk, well argued.

## 3. Corrections and additions

### R2 is incomplete

The proposed script only covers inline review threads. `comment-triage` also
reads top-level PR comments and review bodies. The script must include them,
and exclude flux's own `<!-- flux-review -->` summary comment. The
`first:100` / `first:20` limits have no pagination: acceptable for flux PRs,
but worth a comment in the script (or a truncation warning).

### R1 relies on an unverified claim

"Subagents can spawn other subagents up to 3 levels deep" must be tested
before any design work. Historically a subagent had no access to the Agent
tool. If that is still true, the `issue-worker` cannot launch `qa` or
`reviewer`, and the orchestrator has to launch them instead. Also confirm that
the `PreToolUse` gate on `git push` fires for a subagent's Bash calls,
otherwise a safeguard is lost.

### R10: `experimental: {cacheTtl: 1h}` is doubtful

No source is given and the field is not a known agent frontmatter key. Check
the documentation before adopting it. `maxTurns` is plausible but needs the
same check.

### R9 underestimates the quality risk

The main context knows *why* the changes were made; a fork that only reads
the diff does not, and the PR body exists precisely to explain intent. With a
"low to medium" gain, drop it rather than keep it at the end of the list.

### R4 has a security blind spot

A lockfile that changes without its manifest changing is exactly what a
reviewer should read (supply chain). Keep the exclusions, with one rule:
"lockfile changed without `composer.json` / `package.json` changed: read it".
Also check whether the installed `gh pr diff` supports an exclusion flag,
which would avoid the `git fetch` detour.

### R5: marker compatibility

Moving from `<!-- flux-review -->` to `<!-- flux-review sha=... -->` must stay
compatible with markers already posted: match on the prefix, not on equality.

## 4. Main gap: no baseline

The "high / medium" gains are estimates. Before changing anything, run
`ccusage` (including subagent transcripts) on an existing duke session to see
where tokens actually go. This may reorder the list: if CI waits weigh little,
R3 moves down.

The protocol of section 6 (sandbox repo, planted defects, 2 to 3 runs per
configuration) is rigorous but heavy for a solo developer. Reserve it for the
items that change what an agent sees (R5, R6), as the audit itself suggests.

## 5. Proposed order

1. Baseline measurement.
2. R7, then R2 (completed as above).
3. R8, R3, R6.
4. R1, once the nested subagent question is settled.
5. R4 (with the lockfile rule), R5.
6. R9 and R10: last, or not at all.
