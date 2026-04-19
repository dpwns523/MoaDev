import NextAuth, { type Session } from "next-auth";
import Google from "next-auth/providers/google";
import Kakao from "next-auth/providers/kakao";
import Naver from "next-auth/providers/naver";

import { listAuthProviderStatus } from "./lib/auth/provider-config";

type ExtendedSessionUser = Session["user"] & {
  id?: string;
  provider?: string | null;
};

type ExtendedToken = {
  sub?: string | null;
  provider?: string | null;
};

const authProviderStatus = listAuthProviderStatus();
const configuredAuthProviders = authProviderStatus.filter((provider) => provider.configured);

const providers = [
  ...(configuredAuthProviders.some((provider) => provider.id === "google") ? [Google] : []),
  ...(configuredAuthProviders.some((provider) => provider.id === "kakao") ? [Kakao] : []),
  ...(configuredAuthProviders.some((provider) => provider.id === "naver") ? [Naver] : []),
];

export { authProviderStatus, configuredAuthProviders };

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers,
  session: {
    strategy: "jwt",
  },
  pages: {
    signIn: "/login",
  },
  callbacks: {
    jwt({ token, account }) {
      const extendedToken = token as typeof token & ExtendedToken;

      if (account?.provider) {
        extendedToken.provider = account.provider;
      }

      return extendedToken;
    },
    session({ session, token }) {
      const sessionUser = (session.user ?? {}) as ExtendedSessionUser;
      const extendedToken = token as typeof token & ExtendedToken;

      sessionUser.id = extendedToken.sub ?? "";
      sessionUser.provider = typeof extendedToken.provider === "string" ? extendedToken.provider : null;
      session.user = sessionUser as typeof session.user;

      return session;
    },
  },
});
