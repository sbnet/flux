---
name: ui-review
description: Heuristic UI/UX review of the running app — screenshots at multiple breakpoints, state coverage, consistency, form ergonomics. Use when the user asks for a UI review, UX feedback, or a design pass on pages or flows.
---

# Skill: ui-review

## Purpose

Review the interface as a user experiences it, not as the code reads.
Complements — never duplicates — the accessibility skill (full WCAG pass)
and the frontend-design skill (building new UI): this one evaluates what
exists.

## Method

1. **Run the app** (commands from `flux-config.yml` / project scripts) and
   drive it with `playwright-cli`. Screenshot every reviewed page at three
   widths: 375 (mobile), 768 (tablet), 1440 (desktop). Look at the
   screenshots — do not judge from the Vue/Blade source alone.
2. **State matrix per page.** Empty (no data yet), loading, error,
   success/normal, and overflowing (long names, 1000+ rows, tiny screen).
   Empty and error states are where most UIs fail: is the user told what
   happened and what to do next?
3. **Forms.** Labels tied to inputs, required fields marked, validation
   errors adjacent to their field and specific, submit state (disabled?
   spinner? double-submit protected?), value preservation on error.
4. **Consistency.** Same action = same word, same place, same component
   everywhere (one "Delete" pattern, one toast style, one empty-state
   layout). Spacing and typography reuse the design system's scale rather
   than ad-hoc values.
5. **Flow friction.** For each user flow in the spec: count the clicks,
   note dead ends (where the user lands with nothing to do), check that
   destructive actions confirm and that success is acknowledged.

## Report

Findings ordered by severity (blocking > confusing > polish), each with:
the page/state, a screenshot reference, what a user experiences, and a
concrete fix. Separate "fix now" from "polish backlog". If asked to fix,
apply the retained findings — the gates and normal flux cycle handle the
rest.
