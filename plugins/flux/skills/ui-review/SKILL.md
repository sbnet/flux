---
name: ui-review
description: "Heuristic UI/UX review of the running app: screenshots at multiple breakpoints, state coverage, consistency, form ergonomics. Use when the user asks for a UI review, UX feedback, or a design pass on pages or flows."
---

# Skill: ui-review

## Purpose

Review the interface as a user experiences it, not as the code reads.
Complements, without duplicating, the accessibility skill (full WCAG pass)
and the frontend-design skill (building new UI): this one evaluates what
exists.

## Depth

Two levels. Default to quick unless the user asks for a deep/full/thorough
review, or the quick pass turns up something that looks breakpoint- or
state-specific (in which case say so and offer to go deep on that page).

- **Quick (default):** screenshot each reviewed page at 1440 (desktop) and
  375 (mobile), normal/success state only.
- **Deep:** add 768 (tablet), and walk the full state matrix per page
  (below) instead of just normal/success.

## Method

1. **Run the app** (commands from `flux-config.yml` / project scripts) and
   drive it with `playwright-cli`. Screenshot per the Depth above. Look at
   the screenshots; do not judge from the Vue/Blade source alone.
2. **State matrix (deep only).** Empty (no data yet), loading, error,
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

State which depth was used. Findings ordered by severity (blocking >
confusing > polish), each with: the page/state, a screenshot reference,
what a user experiences, and a concrete fix. Separate "fix now" from
"polish backlog". If asked to fix, apply the retained findings; the gates
and normal flux cycle handle the rest.
