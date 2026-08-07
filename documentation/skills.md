# Skills and agents reference

Every skill is invocable as `/flux:<name>` once the plugin is installed.
Claude also invokes them on its own when the conversation matches their
purpose; the "When" sections below describe both triggers. Agents are not
invoked directly: Claude launches them as subagents when their conditions
apply, or when you ask.

Where each one sits in the cycle:

```
/flux:feature (single entry point, calibrates the path)
  └→ [spec-interview → gh-issue]  (full path only; standard: auto-issue;
      trivial: neither)
  └→ implementation + gates → qa / reviewer → gh-pr → CI
  └→ automated review → triage (human, in-session) → human merge
      └→ post-merge: spec status + branch deletion, automated

init = one-time project setup       geo / ui-review = on demand
```

---

## init

**What.** Sets up flux in the current project: detects the stack, writes
`flux-config.yml`, installs the CI gate script (`.claude/hooks/flux-gate.sh`),
the GitHub workflows (gates CI + automated review), the `CLAUDE.md`
workflow contract, the specs index, and the GitHub labels.

**When.** Once per project, right after installing the plugin. Also safe to
re-run: it refreshes the managed files (e.g. after a plugin update that
changed `flux-gate.sh`).

**Reads.** The project tree (composer.json, package.json…) to infer lint /
static analysis / types / test / build commands.

**Produces.** `flux-config.yml`, `.claude/hooks/flux-gate.sh`,
`.github/workflows/{ci,claude-review,spec-lifecycle}.yml`, `CLAUDE.md`,
`specs/README.md`. Also enables automatic head-branch deletion on the
repository. The spec-lifecycle workflow flips a merged PR's linked spec to
`status: implemented` and updates the index, deterministically.

**You still have to.** Create the `CLAUDE_CODE_OAUTH_TOKEN` secret
(`claude setup-token`, then `gh secret set`; full instructions in the
[setup guide](setup.md)), and review the inferred commands in
`flux-config.yml`.

```
/flux:init
```

## spec-interview

**What.** Interviews you in depth about a feature (implementation, UX,
business rules, edge cases, tradeoffs), then writes one spec file per
feature: `specs/SPEC-<ref>.md` with a status frontmatter
(`draft → validated → implemented`), and maintains the `specs/README.md`
index.

**When.** At the start of any non-trivial feature, before any code.
Usually launched by the feature skill on its full path; invoke it directly to
write a spec without starting the build. The spec's acceptance criteria
become the contract that `qa`, `reviewer` and the automated PR review all
check against.

**Produces.** `specs/SPEC-<ref>.md` (`<ref>` = issue number or stable
slug), updated index. On your validation the status moves to `validated`
and the skill offers to chain into `/flux:gh-issue`.

```
/flux:spec-interview candidate management (CRUD)
```

## gh-issue

**What.** Writes and creates a GitHub issue (context, observable goal,
acceptance criteria, spec reference) with the project labels, and
back-links the issue number into the spec's frontmatter and index row.

**When.** Usually automatic: the feature skill creates the issue itself on its
standard and full paths. Invoke it standalone for bugs and tasks that need
tracking without building right away.

**Reads.** `flux-config.yml` (`github.labels`), the spec if one exists.

**Produces.** The GitHub issue (one issue = one deliverable; several if the
spec implies independent work streams), updated spec frontmatter.

```
/flux:gh-issue
```

## feature

**What.** The single entry point to build anything. Calibrates the path to
the change and announces it: **trivial** (no spec, no issue), **standard**
(issue auto-generated from your description), **full** (interview → spec →
auto-issue). Then drives everything: branch → implementation (tests
included) → gates → local verification (`qa` when there are user flows;
`reviewer` per the risk rule) → PR → CI watch-and-fix → waits for the
automated review and runs the triage in the same session. Stops only for
scope changes, destructive operations, or after 3 failed attempts on one
error.

**When.** Any "build / fix / implement X" request. This is the standard way
to work; the other skills remain available standalone. For the full
picture read the [walkthrough](walkthrough.md).

**Never does.** Merge, approve, bypass a gate, address review comments
without the human triage.

```
/flux:feature implement SPEC-candidate-management
```

## gh-pr

**What.** Opens the PR for the current branch: conventional-commit title,
body built from the real diff (summary, `Closes #N`, spec link, test plan,
review notes), then watches CI and fixes failures autonomously (3-attempt
cap per error). Ends by pointing you to the automated review for triage.

**When.** Implementation done and pushed, either invoked by the feature skill
or standalone if you drove the implementation manually.

**Reads.** `git diff main...HEAD`, `flux-config.yml` (`github.labels`),
the linked issue/spec.

```
/flux:gh-pr
```

## gh-address-comments

**What.** The review-triage step. Collects all PR comments (top-level and
inline), gives you **its own assessment of each finding** (it reads the
code first and may disagree with the reviewer), lets you pick what to
address in one multi-choice question, then fixes the retained items
autonomously and replies on every comment: addressed (with commit) or
declined (with your reason).

**When.** Inside a `/flux:feature` session, this flow runs as soon as the
automated review lands. Invoke it standalone when the review arrived after
your session ended. Either way the triage itself is **always human**: it
is the step that gives the merge decision its substance.

```
/flux:gh-address-comments
```

## geo

**What.** Audits and improves visibility in generative engines (AI answers,
LLM-powered search), in strict order: renderability (what a no-JS crawler
sees; an SPA shell is invisible), machine surface (`llms.txt`, robots
rules for AI crawlers, server-side JSON-LD), then content citability
(self-contained answers, question-phrased headings, dated facts).

**When.** The project has public pages and you care about being cited by
AI assistants. Complementary to a classic SEO pass: meta, sitemap and
Core Web Vitals are not its job.

```
/flux:geo audit the public pages
```

## ui-review

**What.** Reviews the interface as a user experiences it: drives the
running app with playwright-cli, screenshots each page at 375/768/1440,
checks the state matrix (empty / loading / error / overflow), form
ergonomics, pattern consistency, and flow friction against the spec.
Report ordered blocking > confusing > polish.

**When.** A feature's UI is functional and you want a design pass; before
a demo; or periodically on the main flows. Complementary to the
accessibility skill (full WCAG) and frontend-design (building new UI).

```
/flux:ui-review the candidates pages
```

---

## Agents

### reviewer

Pre-PR review of the branch diff: logic, architecture, security, spec
conformance, never what the gates already enforce. **Conditional by
design**: run it when a post-PR finding would be expensive: diff spanning
many files/layers, schema or data migration, sensitive area (auth,
payments, permissions, files), spec with many criteria. Skip it for small
contained changes: the automated PR review covers those. Rationale and a
worked example: [walkthrough](walkthrough.md), part 2 step 5.

### qa

Runs the app for real and walks the spec's user flows (curl, or
playwright-cli when the flow needs a browser), probes unhappy paths,
cleans up after itself, and reports pass/fail per acceptance criterion
with reproduction commands. **Unconditional** whenever the feature has
observable flows; nothing else in the cycle actually runs the app.
