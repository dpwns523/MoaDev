import assert from "node:assert/strict";
import test from "node:test";

import { buildLoginRedirectPath, isPublicPath } from "./route-protection";

test("allows public auth and asset paths through the route boundary", () => {
  assert.equal(isPublicPath("/login"), true);
  assert.equal(isPublicPath("/api/auth/signin/google"), true);
  assert.equal(isPublicPath("/_next/static/chunks/app.js"), true);
  assert.equal(isPublicPath("/favicon.ico"), true);
});

test("marks application content paths as protected", () => {
  assert.equal(isPublicPath("/"), false);
  assert.equal(isPublicPath("/articles/123"), false);
});

test("builds a login redirect that preserves the original destination", () => {
  assert.equal(buildLoginRedirectPath("/", ""), "/login?callbackUrl=%2F");
  assert.equal(buildLoginRedirectPath("/articles/123", "?tab=notes"), "/login?callbackUrl=%2Farticles%2F123%3Ftab%3Dnotes");
});
