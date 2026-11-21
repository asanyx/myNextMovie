// Shared by the Edge Functions of My Next Movie.

/// Whether the request comes from a signed-in user, not just with the anon key.
///
/// The gateway has already checked the token's signature and expiry, because
/// verify_jwt is on for every function (supabase/config.toml). So the claims can be
/// read here without asking Auth. The anon key is a valid token too, with role "anon".
/// With verify_jwt off, anyone could forge these claims: keep it on.
export function isSignedInUser(request: Request): boolean {
  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer /, "");
  const payload = token.split(".")[1] ?? "";
  try {
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const claims = JSON.parse(atob(base64));
    return claims.role === "authenticated";
  } catch {
    return false;
  }
}
