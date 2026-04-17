const REPO_URL = "https://github.com/morgann1/studio-discover";

export function ghRedirect(): Response {
	return Response.redirect(REPO_URL, 302);
}
