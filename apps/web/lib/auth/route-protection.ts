const PUBLIC_EXACT_PATHS = new Set(["/login", "/favicon.ico"]);
const PUBLIC_PREFIXES = ["/api/auth", "/_next"];

export function isPublicPath(pathname: string): boolean {
  if (PUBLIC_EXACT_PATHS.has(pathname)) {
    return true;
  }

  return PUBLIC_PREFIXES.some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`));
}

export function buildLoginRedirectPath(pathname: string, search: string): string {
  const normalizedSearch = search.length > 0 ? search : "";
  const callbackUrl = `${pathname}${normalizedSearch}` || "/";
  return `/login?callbackUrl=${encodeURIComponent(callbackUrl)}`;
}
