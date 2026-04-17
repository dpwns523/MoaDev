# Product Plan

## Purpose

This document turns the PRD into an implementation-facing MVP plan. It is intentionally narrower than the long-term platform vision and focuses on the first releasable product.

Primary source-of-truth documents:

- `docs/prd.md`
- `docs/prd.ko.md`

## First Release Definition

The first release of `MoaDev` is a private, authenticated AI knowledge web application for reading technology content in structured Korean form.

The product must let a signed-in user:

- find useful technology articles from approved sources
- open a processed article detail page
- read line-by-line Korean translation and structured explanations
- continue learning through categories and related concepts

## Primary Personas

### Persona 1: Working Developer

- wants fast understanding of useful technology content
- does not want to read raw English sources across many sites every day
- values translation accuracy and concise context

### Persona 2: Technical Learner

- wants concept and terminology explanations, not just summary
- prefers a guided path from one article to adjacent topics
- values category structure and related concept navigation

### Persona 3: Technical Lead

- wants a high-signal reading surface for meaningful articles
- cares about trustworthy explanations and consistent source selection

## MVP User Journey

1. User signs in.
2. User lands on a knowledge home page with category and source entry points.
3. User opens a category or source list.
4. User selects an article.
5. User reads structured knowledge sections:
   - article overview
   - line-by-line translation
   - summary
   - glossary
   - concept explanations
   - related concepts
6. User continues exploration from category or related-concept links.

## MVP Screens

### 1. Sign-In Gate

- blocks all content access until authentication succeeds
- supports session recovery and redirect back to the intended destination

### 2. Knowledge Home

- highlights categories
- shows recent or featured processed articles
- lets the user navigate by source and category

### 3. Category Or Source List

- shows processed articles with title, source, category, publish date, and processing state
- keeps filters minimal in the first release

### 4. Article Detail

- is the core product page
- displays article metadata, source context, structured translation, summary, glossary, concept explanations, and related concepts
- shows partial or degraded states clearly if enrichment is incomplete

## MVP Feature Priorities

### Must Have

- authenticated access
- approved source registry
- article ingestion and enrichment pipeline for one source family
- source and category browsing
- structured article detail output
- processing status visibility

### Should Have Soon After MVP

- expansion to more IT company blogs
- better category curation
- simple saved-history or continue-reading affordance

### Deferred

- public access
- open user-submitted links
- notes, bookmarks, or collaborative features
- finance knowledge ingestion
- generalized super-app navigation across many non-technology domains

## Content Governance

- Only approved sources are allowed in the first release.
- Source-specific licensing and storage policy must be reviewed before ingestion is enabled.
- The product should store enough normalized text to support the structured knowledge experience, but it must respect source policy constraints.
- Low-confidence outputs should be published with explicit status markers or withheld for review.

## Quality Bar

- translation must be segment-aligned and understandable
- summaries must stay faithful to the source
- glossary items must explain terms in article context, not as generic dictionary snippets
- related concepts must be adjacent and useful, not arbitrary keyword expansion

## Release Sequence

### Phase 0: Product Contract

- finalize PRD, agent-role plan, and production plan

### Phase 1: Closed MVP

- authenticate users
- ingest `Keek news`
- publish categorized article lists and article detail pages

### Phase 2: Source Expansion

- add selected IT company tech blogs
- refine category coverage and operator workflows

## Open Decisions

- exact source onboarding policy for each external provider
- final category names exposed in the UI
- whether saved items are part of MVP or immediate post-MVP work
- exact auth provider selection
