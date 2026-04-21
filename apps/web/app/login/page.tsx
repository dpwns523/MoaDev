import { redirect } from "next/navigation";

import { auth, configuredAuthProviders, signIn } from "../../auth";

type LoginPageProps = {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const session = await auth();
  const resolvedSearchParams = (await searchParams) ?? {};
  const callbackUrl = readCallbackUrl(resolvedSearchParams.callbackUrl);

  if (session?.user) {
    redirect(callbackUrl);
  }

  return (
    <main className="auth-shell">
      <section className="auth-card">
        <div className="auth-card__intro">
          <p className="eyebrow">Authenticated knowledge workflow</p>
          <h1>Sign in to enter the MoaDev knowledge desk.</h1>
          <p>
            This MVP keeps the editorial home and API feed behind an authenticated session boundary. OAuth is handled
            in the web app, then the session is forwarded to the API through a signed internal bearer token.
          </p>
        </div>

        <div className="auth-actions">
          {configuredAuthProviders.length > 0 ? (
            configuredAuthProviders.map((provider) => (
              <form
                key={provider.id}
                action={async () => {
                  "use server";

                  await signIn(provider.id, {
                    redirectTo: callbackUrl,
                  });
                }}
              >
                <button className="auth-provider-button" type="submit">
                  Continue with {provider.name}
                </button>
              </form>
            ))
          ) : (
            <div className="auth-setup">
              <h2>No OAuth provider is configured yet.</h2>
              <p>
                Add at least one of Google, Kakao, or Naver in the web environment, then restart the Next.js app.
              </p>
            </div>
          )}
        </div>

        <div className="auth-checklist">
          <p className="card-eyebrow">Local development checklist</p>
          <ul>
            <li>Set `AUTH_SECRET` plus the provider `AUTH_*_ID` and `AUTH_*_SECRET` values in `apps/web`.</li>
            <li>Use `http://localhost:3000/api/auth/callback/&lt;provider&gt;` as the OAuth callback URL.</li>
            <li>Share the same `MOADEV_INTERNAL_AUTH_SECRET` between `apps/web` and `services/api`.</li>
          </ul>
        </div>
      </section>
    </main>
  );
}

function readCallbackUrl(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return readCallbackUrl(value[0]);
  }

  if (!value || !value.startsWith("/")) {
    return "/";
  }

  return value;
}
