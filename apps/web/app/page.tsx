import { getHomeContent } from "../lib/get-home-content";
import { getHomeFeed, type HomeFeedItem } from "../lib/get-home-feed";

const briefingNotes = [
  "Lead with product and platform stories that change developer behavior, not just launch volume.",
  "Keep pull-request coverage focused on repositories with active maintainer attention.",
  "Always leave the reader with a next action: review, watch, contribute, or operational follow-up.",
];

export default async function HomePage() {
  const sections = getHomeContent();
  const feed = await getHomeFeed();
  const [leadStory, ...secondaryStories] = feed.items;

  return (
    <main className="home-page">
      <header className="masthead">
        <div className="masthead__brand">
          <span className="masthead__brand-mark">M</span>
          <span>MoaDev Journal</span>
        </div>
        <div className="masthead__meta">Issue #6 web home, built for live API briefing and quiet review.</div>
      </header>

      <section className="hero">
        <div className="hero__copy">
          <p className="eyebrow">Editorial developer feed</p>
          <h1 className="hero__title">Read the software week before it gets noisy.</h1>
          <p className="hero__summary">
            Inspired by the editorial pacing of Stripe&apos;s blog, this home surface turns the MoaDev feed into
            a calm briefing room for launches, open-source motion, and next-step execution.
          </p>
          <div className="hero__status-row">
            <span className={`status-pill status-pill--${feed.status}`}>
              {feed.status === "live" ? "Live API feed" : "Preview mode"}
            </span>
            <span>{feed.message}</span>
          </div>
        </div>

        <aside className="hero__panel">
          <div>
            <p className="card-eyebrow">This edition</p>
            <h2>{leadStory.title}</h2>
            <p>{getStorySummary(leadStory)}</p>
          </div>
          <dl className="hero__stats">
            <div>
              <dt>Lead source</dt>
              <dd>{formatSource(leadStory.source)}</dd>
            </div>
            <div>
              <dt>Feed mode</dt>
              <dd>{feed.status === "live" ? "Connected" : "Preview"}</dd>
            </div>
            <div>
              <dt>Total stories</dt>
              <dd>{feed.total}</dd>
            </div>
            <div>
              <dt>Coverage</dt>
              <dd>{formatKind(leadStory.kind)}</dd>
            </div>
          </dl>
        </aside>
      </section>

      <section className="section-strip" aria-label="Coverage areas">
        {sections.map((section) => (
          <article className="section-strip__item" key={section.id}>
            <p className="section-strip__id">{section.id}</p>
            <h2>{section.title}</h2>
            <p>{section.description}</p>
          </article>
        ))}
      </section>

      <section className="feed-layout" aria-label="Featured feed stories">
        <article className="feature-story">
          <p className="card-eyebrow">Featured signal</p>
          <div className="feature-story__meta">
            <span>{formatKind(leadStory.kind)}</span>
            <span>{formatSource(leadStory.source)}</span>
          </div>
          <h2 className="feature-story__title">{leadStory.title}</h2>
          <p className="feature-story__lede">{getStorySummary(leadStory)}</p>
          <div className="feature-story__footer">
            <span className="feature-story__signal">Built to connect directly to `/api/v1/feeds`.</span>
            <span className="feature-story__tag">MoaDev briefing</span>
          </div>
        </article>

        <div className="story-column">
          {secondaryStories.map((story) => (
            <article className="story-card" key={story.id}>
              <div>
                <p className="card-eyebrow">{formatKind(story.kind)}</p>
                <h3>{story.title}</h3>
                <p>{getStorySummary(story)}</p>
              </div>
              <div className="story-card__meta">
                <span>{formatSource(story.source)}</span>
                <span>{story.id}</span>
              </div>
            </article>
          ))}
        </div>

        <aside className="briefing-card">
          <p className="briefing-card__eyebrow">Desk notes</p>
          <p>
            The page is intentionally resilient: when the FastAPI service is not reachable, the layout stays intact
            and swaps to preview stories instead of collapsing.
          </p>
          <ul className="briefing-card__list">
            {briefingNotes.map((note) => (
              <li key={note}>{note}</li>
            ))}
          </ul>
        </aside>
      </section>

      <section className="signal-grid" aria-label="Signal cards">
        {feed.items.map((story) => (
          <article className="signal-card" key={`${story.id}-signal`}>
            <p className="signal-card__eyebrow">{formatKind(story.kind)}</p>
            <h3>{story.title}</h3>
            <p>{getSignalDescription(story)}</p>
            <div className="signal-card__meta">
              <span>{formatSource(story.source)}</span>
              <span>{story.id}</span>
            </div>
          </article>
        ))}
      </section>
    </main>
  );
}

function formatKind(kind: HomeFeedItem["kind"]): string {
  return kind === "pull-request" ? "Open pull requests" : "Product and platform";
}

function formatSource(source: string): string {
  return source
    .split("-")
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(" ");
}

function getStorySummary(story: HomeFeedItem): string {
  if (story.kind === "pull-request") {
    return "Open-source work with enough momentum to justify review time, watchlists, or direct contribution.";
  }

  return "High-signal coverage focused on the product, infrastructure, and tooling shifts developers should notice first.";
}

function getSignalDescription(story: HomeFeedItem): string {
  if (story.kind === "pull-request") {
    return "A review queue entry shaped for maintainers, contributors, and teams deciding where to spend attention.";
  }

  return "An editorial signal card for launches, ecosystem movement, and product changes that affect technical decisions.";
}
