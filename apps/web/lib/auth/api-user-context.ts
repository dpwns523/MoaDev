import { createHmac } from "node:crypto";

export const API_AUTHORIZATION_HEADER = "authorization";

export type ApiSessionUser = {
  id: string;
  email?: string | null;
  name?: string | null;
  image?: string | null;
  provider?: string | null;
};

type BuildApiAuthOptions = {
  issuedAt?: number;
  secret?: string;
};

type ApiAuthTokenPayload = {
  sub: string;
  email: string | null;
  name: string | null;
  image: string | null;
  provider: string | null;
  iat: number;
};

export function buildApiAuthHeaders(
  user: ApiSessionUser,
  options: BuildApiAuthOptions = {},
): Record<string, string> {
  const secret = requireSecret(options.secret ?? process.env.MOADEV_INTERNAL_AUTH_SECRET);
  const userId = requireUserId(user.id);
  const payload: ApiAuthTokenPayload = {
    sub: userId,
    email: normalizeOptionalValue(user.email),
    name: normalizeOptionalValue(user.name),
    image: normalizeOptionalValue(user.image),
    provider: normalizeOptionalValue(user.provider),
    iat: options.issuedAt ?? Math.floor(Date.now() / 1000),
  };
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = createHmac("sha256", secret).update(encodedPayload).digest("base64url");

  return {
    [API_AUTHORIZATION_HEADER]: `Bearer ${encodedPayload}.${signature}`,
  };
}

function requireSecret(value: string | undefined): string {
  if (!value?.trim()) {
    throw new Error("A shared internal auth bridge secret is required.");
  }

  return value;
}

function requireUserId(value: string): string {
  if (!value.trim()) {
    throw new Error("An authenticated session user id is required.");
  }

  return value;
}

function normalizeOptionalValue(value: string | null | undefined): string | null {
  if (!value) {
    return null;
  }

  const normalizedValue = value.trim();
  return normalizedValue.length > 0 ? normalizedValue : null;
}
