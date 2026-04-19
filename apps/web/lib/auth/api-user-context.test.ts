import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import test from "node:test";

import { buildApiAuthHeaders } from "./api-user-context";

test("builds a signed bearer token header from an authenticated session user", () => {
  const headers = buildApiAuthHeaders(
    {
      id: "user-123",
      email: "dev@moadev.test",
      name: "Moa Developer",
      image: "https://example.com/avatar.png",
      provider: "google",
    },
    {
      secret: "bridge-secret",
      issuedAt: 1_700_000_000,
    },
  );

  const authorizationHeader = headers.authorization;

  assert.ok(authorizationHeader?.startsWith("Bearer "));

  const token = authorizationHeader?.slice("Bearer ".length) ?? "";
  const [encodedPayload, signature] = token.split(".");

  assert.ok(encodedPayload);
  assert.ok(signature);

  assert.deepEqual(JSON.parse(Buffer.from(encodedPayload, "base64url").toString("utf8")), {
    sub: "user-123",
    email: "dev@moadev.test",
    name: "Moa Developer",
    image: "https://example.com/avatar.png",
    provider: "google",
    iat: 1_700_000_000,
  });
  assert.equal(signature, createHmac("sha256", "bridge-secret").update(encodedPayload).digest("base64url"));
});

test("rejects a missing auth bridge secret", () => {
  assert.throws(
    () =>
      buildApiAuthHeaders(
        {
          id: "user-123",
        },
        {
          secret: "",
        },
      ),
    /secret/i,
  );
});

test("rejects a missing session user id", () => {
  assert.throws(
    () =>
      buildApiAuthHeaders(
        {
          id: "   ",
        },
        {
          secret: "bridge-secret",
        },
      ),
    /user id/i,
  );
});
