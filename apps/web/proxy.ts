import { auth } from "./auth";
import { buildLoginRedirectPath, isPublicPath } from "./lib/auth/route-protection";

export const proxy = auth((request) => {
  if (isPublicPath(request.nextUrl.pathname) || request.auth) {
    return;
  }

  return Response.redirect(new URL(buildLoginRedirectPath(request.nextUrl.pathname, request.nextUrl.search), request.nextUrl.origin));
});

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
