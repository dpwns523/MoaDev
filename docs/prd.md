# Product Requirements Document

## Product

`MoaDev` is an authenticated AI knowledge web application that aggregates useful external content, then turns each article into structured Korean learning material.

The first release starts with `Keek news` as the seed technology source and expands to technology blogs from IT companies. The long-term direction is a broader knowledge platform that may later include financial knowledge, but the initial product stays focused on technology content.

## Product Thesis

Useful knowledge is scattered across many sites, written in different styles, and often harder to absorb quickly in Korean. `MoaDev` should reduce that friction by doing three things well:

- collect high-value content from approved external sources
- transform raw articles into structured Korean knowledge artifacts
- let authenticated users access that knowledge in one place without jumping across multiple platforms

## Target Users

- Developers who want to track useful technology content without manually checking many sources
- Engineers and technical leads who want fast Korean understanding of important articles
- Learners who want not only translation, but also terminology and concept explanations tied to the article context

## Core Problem

Technology knowledge is spread across news sites and company engineering blogs. Even when users find the right article, they still need time to translate it, summarize it, interpret unfamiliar terms, connect the article to surrounding concepts, and organize what matters.

That leads to three problems:

- discovery friction: useful content is spread across many platforms
- comprehension friction: users must translate and interpret the article themselves
- organization friction: users do not get a consistent categorized knowledge view across sources

## Goals

- Aggregate approved external technology content into one authenticated product experience
- Present each article as structured Korean knowledge instead of a raw link-only feed
- Help users move from reading to understanding by combining translation, summary, glossary, and concept explanation
- Organize content by source and category so users can browse intentionally instead of consuming noise
- Keep the first release small enough to ship with the current monorepo and service boundaries

## First Release Scope

The first release is an authenticated web application with these product surfaces:

- sign-in gate before accessing the content experience
- article list views grouped by source and category
- article detail view with structured AI output
- a minimal knowledge library experience for browsing previously processed content

The first release starts with:

- `Keek news`
- a small set of technology categories
- article ingestion and enrichment for approved sources only

The first release does not try to ingest every possible source or support every knowledge domain.

## Primary User Journey

1. A user signs in.
2. The user lands on a categorized knowledge home view.
3. The user selects an article from an approved source.
4. The user reads:
   - article metadata
   - source context
   - line-by-line Korean translation
   - concise summary
   - terminology explanations
   - concept explanations
   - related concepts
5. The user uses category and source navigation to continue exploring related content.

## MVP Features

- Authenticated access control for all product content
- Source-aware article ingestion from approved external providers
- Category-based browsing for processed articles
- Article detail page with structured AI knowledge output
- Consistent article metadata including source, publish time, category, and processing state
- Structured API contracts that support web rendering of article lists and article detail views

## Structured Article Output Contract

Each processed article should provide, at minimum:

- article title
- source name and source URL
- publish timestamp and ingestion timestamp
- category and tags
- original article excerpt or normalized content segments allowed by source policy
- line-by-line Korean translation mapped to the normalized segments
- short summary
- key terminology list with Korean explanation
- concept explanation section for important ideas introduced by the article
- related concepts or adjacent topics for continued learning
- processing status and quality notes when the enrichment output is incomplete or uncertain

## Content Scope

Initial content scope:

- `Keek news`

Near-term expansion scope:

- technology blogs from IT companies

Deferred scope:

- financial knowledge content
- non-technology general media coverage
- user-submitted arbitrary URLs without source approval

## Category Model

The MVP category model should stay small and understandable. The first release should group content into a manageable set of technology themes such as:

- AI and machine learning
- backend and infrastructure
- frontend and web platform
- cloud and DevOps
- data and platform engineering

Final category naming can be refined during implementation, but the product contract should assume category-based navigation from the start.

## Authentication And Access

- The product is not public-read in the first release.
- Users must authenticate before accessing curated article detail views.
- Admin or operator flows for approving sources and reviewing processing failures can be introduced separately from the reader experience.
- Exact identity provider choice is an implementation detail, but the PRD assumes authenticated sessions are required.

## Non-Goals

- This repo is not building a general social network or discussion community in the first release
- It is not a generic crawler that optimizes for maximum content volume
- It is not an open submission platform for arbitrary user links in the first release
- It is not a full note-taking or knowledge management suite in the first release
- It is not a financial knowledge platform in the first release
- It is not trying to deliver the entire long-term super web vision in one milestone

## User Stories

- As an authenticated user, I want one place to read useful technology articles translated and explained in Korean so I can understand them faster.
- As a developer, I want article-level terminology and concept explanations so I do not need to separately research every unfamiliar term.
- As a learner, I want related concepts next to each article so I can continue learning from a topic, not just consume one post.
- As an operator or product owner, I want approved sources and categories to stay consistent so the knowledge library remains high-signal.

## Acceptance Criteria

- Users must authenticate before accessing the main knowledge experience.
- Users can browse processed articles by source and category.
- Each article detail view includes structured Korean translation, summary, terminology explanations, concept explanations, and related concepts.
- The first-release product definition is clearly limited to technology content, with finance reserved for later expansion.
- The system presents consistent response and error shapes for API surfaces that support the authenticated web experience.

## Success Metrics

- Time to first useful understanding: users can reach one clearly useful processed article quickly after signing in.
- Comprehension quality: users report that translation and explanations reduce the time needed to understand an article.
- Knowledge navigation usefulness: users continue exploring through categories and related concepts instead of bouncing after one page.
- Content quality: approved sources consistently produce structured outputs that users consider trustworthy and useful.
- Expansion readiness: the first release stays small, but its data model and service boundaries can extend to additional sources later.

## Future Direction

The long-term direction is a microservices-based knowledge platform where users can access multiple types of curated information in one place. That may eventually include financial knowledge and broader domain-specific content, but the initial release should prove the technology-content workflow first.

## Notes

This PRD intentionally fixes the first-release product contract before large-scale feature or infrastructure expansion continues. Source licensing, storage policy, translation quality, and authentication boundaries must be reviewed as part of implementation planning.
