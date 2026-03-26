import assert from "node:assert/strict";
import test from "node:test";

import { getHomeContent } from "./get-home-content";

test("returns curated sections in the expected order", () => {
  const sections = getHomeContent();

  assert.deepEqual(
    sections.map((section) => section.id),
    ["news", "prs", "actions"],
  );
});

test("returns user-facing copy for every section", () => {
  const sections = getHomeContent();

  assert.ok(sections.every((section) => section.title.length > 0 && section.description.length > 0));
});
