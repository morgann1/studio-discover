import type { Handler } from "hono";

const REPO_URL = "https://github.com/morgann1/studio-discover";

export const ghRedirect: Handler = (c) => c.redirect(REPO_URL, 302);
