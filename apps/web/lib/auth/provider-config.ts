export type AuthProviderId = "google" | "kakao" | "naver";

export type AuthProviderStatus = {
  id: AuthProviderId;
  name: string;
  configured: boolean;
  envIdKey: string;
  envSecretKey: string;
};

const AUTH_PROVIDER_CATALOG: readonly Omit<AuthProviderStatus, "configured">[] = [
  {
    id: "google",
    name: "Google",
    envIdKey: "AUTH_GOOGLE_ID",
    envSecretKey: "AUTH_GOOGLE_SECRET",
  },
  {
    id: "kakao",
    name: "Kakao",
    envIdKey: "AUTH_KAKAO_ID",
    envSecretKey: "AUTH_KAKAO_SECRET",
  },
  {
    id: "naver",
    name: "Naver",
    envIdKey: "AUTH_NAVER_ID",
    envSecretKey: "AUTH_NAVER_SECRET",
  },
] as const;

export function listAuthProviderStatus(env: NodeJS.ProcessEnv = process.env): AuthProviderStatus[] {
  return AUTH_PROVIDER_CATALOG.map((provider) => ({
    ...provider,
    configured: hasValue(env[provider.envIdKey]) && hasValue(env[provider.envSecretKey]),
  }));
}

function hasValue(value: string | undefined): boolean {
  return typeof value === "string" && value.trim().length > 0;
}
