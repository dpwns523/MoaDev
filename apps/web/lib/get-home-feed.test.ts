import assert from "node:assert/strict";
import test from "node:test";

import { getHomeFeed } from "./get-home-feed";

test("returns live feed items from the FastAPI contract", async () => {
  let requestedUrl = "";

  const feed = await getHomeFeed({
    apiBaseUrl: "https://api.moadev.test",
    fetchFeed: async (input) => {
      requestedUrl = input;

      return {
        ok: true,
        json: async () => ({
          data: [
            {
              id: "story-1",
              kind: "news",
              title: "Live story",
              source: "signal-desk",
            },
          ],
          meta: {
            total: 1,
          },
        }),
      };
    },
  });

  assert.equal(requestedUrl, "https://api.moadev.test/api/v1/feeds");
  assert.equal(feed.status, "live");
  assert.equal(feed.total, 1);
  assert.equal(feed.items[0]?.title, "Live story");
});

test("falls back to preview stories when the API request fails", async () => {
  const feed = await getHomeFeed({
    fetchFeed: async () => {
      throw new Error("connection lost");
    },
  });

  assert.equal(feed.status, "fallback");
  assert.equal(feed.total, 3);
  assert.equal(feed.items.length, 3);
});

test("falls back when the API payload shape is invalid", async () => {
  const feed = await getHomeFeed({
    fetchFeed: async () => ({
      ok: true,
      json: async () => ({
        data: [
          {
            id: "story-1",
            kind: "unsupported-kind",
            title: "Broken story",
            source: "signal-desk",
          },
        ],
      }),
    }),
  });

  assert.equal(feed.status, "fallback");
  assert.equal(feed.items[0]?.id, "preview-ai-tooling");
});
