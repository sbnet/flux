---
name: geo
description: Audit and improve visibility in generative engines (AI answers, LLM-powered search) — GEO, complementary to classic SEO. Use when the user asks about GEO, AI search visibility, llms.txt, or being cited by AI assistants.
---

# Skill: GEO (Generative Engine Optimization)

## Purpose

Classic SEO optimizes for ranking in result lists; GEO optimizes for being
**retrieved, quoted and cited** by generative engines that compose answers.
This skill audits a site and applies the fixes. It complements — never
replaces — a classic SEO pass (meta, sitemap, Core Web Vitals stay SEO
territory; if a dedicated seo skill is available, use it for those).

## Audit

1. **Renderability.** Fetch key public pages with `curl` (no JS). What does
   a crawler actually see? SPA/Inertia pages render an empty shell —
   generative crawlers mostly do not execute JS. If the content that should
   be cited is invisible without JS, that is finding #1 and nothing else
   matters until it is fixed (SSR, prerendering, or dedicated
   server-rendered pages for public content).
2. **Machine surface.** Check for `/llms.txt` (curated map of the site's
   content for LLM crawlers), `robots.txt` rules for AI crawlers
   (GPTBot, ClaudeBot, PerplexityBot… — blocked intentionally or by
   accident?), and schema.org structured data (JSON-LD: Organization,
   Product, FAQPage, Article, BreadcrumbList as relevant).
3. **Citability of the content itself.** Generative engines quote passages,
   not pages. Look for: self-contained paragraphs that answer one question
   (quotable without surrounding context); headings phrased as the
   questions users actually ask; concrete facts with units, dates and
   sources rather than marketing prose; visible freshness (dated content);
   consistent naming of the product/entity so the model can attribute
   facts to it.

## Apply

- Fix in the order above: renderability → machine surface → citability.
- `llms.txt`: short markdown index — what the site/product is, links to
  the pages worth reading, one line of context each.
- JSON-LD blocks server-side (in the HTML head, not injected by JS).
- Rewrite key sections so each answers one question in its first sentence;
  keep the H2/H3 as the question.
- Never degrade the human page to please crawlers: GEO changes must be
  invisible or beneficial to human readers.

## Report

List findings ordered by impact, each with: what a generative engine
currently sees, what it should see, and the concrete fix applied or
proposed.
