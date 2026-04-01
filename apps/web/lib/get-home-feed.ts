export type HomeFeedItem = {
  id: string;
  kind: "news" | "pull-request";
  title: string;
  source: string;
};

export type HomeFeedResult = {
  items: HomeFeedItem[];
  total: number;
  status: "live" | "fallback";
  message: string;
};

type FeedFetcherResponse = {
  ok: boolean;
  json: () => Promise<unknown>;
};

type FeedFetcher = (input: string) => Promise<FeedFetcherResponse>;

type GetHomeFeedOptions = {
  apiBaseUrl?: string;
  fetchFeed?: FeedFetcher;
};

const DEFAULT_API_BASE_URL = "http://127.0.0.1:8000";

const FALLBACK_ITEMS: HomeFeedItem[] = [
  {
    id: "preview-ai-tooling",
    kind: "news",
    title: "AI tooling launches developers should evaluate this week",
    source: "preview-desk",
  },
  {
    id: "preview-infra-pr",
    kind: "pull-request",
    title: "Infrastructure pull requests gaining real maintainer momentum",
    source: "preview-review-queue",
  },
  {
    id: "preview-release-notes",
    kind: "news",
    title: "Release-note changes worth turning into follow-up actions",
    source: "preview-operator-brief",
  },
];

export async function getHomeFeed(options: GetHomeFeedOptions = {}): Promise<HomeFeedResult> {
  const apiBaseUrl = options.apiBaseUrl ?? process.env.MOADEV_API_BASE_URL ?? DEFAULT_API_BASE_URL;
  const fetchFeed = options.fetchFeed ?? defaultFetchFeed;

  try {
    const response = await fetchFeed(buildFeedUrl(apiBaseUrl));

    if (!response.ok) {
      return buildFallback("Showing preview stories while the FastAPI feed is unavailable.");
    }

    const payload = await response.json();
    const items = parseFeedItems(payload);
    const total = readTotal(payload, items.length);

    return {
      items,
      total,
      status: "live",
      message: "Connected to the live FastAPI feed.",
    };
  } catch {
    return buildFallback("Showing preview stories while the FastAPI feed is unavailable.");
  }
}

async function defaultFetchFeed(input: string): Promise<FeedFetcherResponse> {
  const response = await fetch(input, {
    headers: {
      accept: "application/json",
    },
  });

  return {
    ok: response.ok,
    json: async () => response.json(),
  };
}

function buildFeedUrl(apiBaseUrl: string): string {
  return new URL("/api/v1/feeds", ensureTrailingSlash(apiBaseUrl)).toString();
}

function ensureTrailingSlash(value: string): string {
  return value.endsWith("/") ? value : `${value}/`;
}

function parseFeedItems(value: unknown): HomeFeedItem[] {
  if (!isRecord(value) || !Array.isArray(value.data)) {
    throw new Error("Feed payload must include a data array.");
  }

  if (!value.data.every(isHomeFeedItem)) {
    throw new Error("Feed payload contained an invalid item.");
  }

  return value.data;
}

function readTotal(value: unknown, fallbackTotal: number): number {
  if (isRecord(value) && isRecord(value.meta) && typeof value.meta.total === "number") {
    return value.meta.total;
  }

  return fallbackTotal;
}

function buildFallback(message: string): HomeFeedResult {
  return {
    items: FALLBACK_ITEMS,
    total: FALLBACK_ITEMS.length,
    status: "fallback",
    message,
  };
}

function isHomeFeedItem(value: unknown): value is HomeFeedItem {
  return (
    isRecord(value) &&
    isNonEmptyString(value.id) &&
    (value.kind === "news" || value.kind === "pull-request") &&
    isNonEmptyString(value.title) &&
    isNonEmptyString(value.source)
  );
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
