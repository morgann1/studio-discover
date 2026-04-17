import type { Handler } from "hono";

import type { HonoEnv } from "../types";
import { isValidSearchQuery } from "../validation";

const UPSTREAM_ORIGIN = "https://api.wally.run";
const REPO_URL = "github.com/morgann1/studio-discover";

export const packageSearch: Handler<HonoEnv> = async (c) => {
	const query = c.req.query("query");
	if (!query || !isValidSearchQuery(query)) {
		return c.text("Invalid or missing query parameter", 400);
	}

	const uid = c.get("uid");
	const version = c.get("version");

	const upstreamUrl = new URL("/v1/package-search", UPSTREAM_ORIGIN);
	upstreamUrl.searchParams.set("query", query);

	const userAgent = `StudioDiscover/${version} (+${REPO_URL}; uid=${uid})`;

	let upstream: Response;
	try {
		upstream = await fetch(upstreamUrl, {
			headers: {
				"User-Agent": userAgent,
				Accept: "application/json",
			},
		});
	} catch {
		return c.text("Upstream unreachable", 502);
	}

	return new Response(upstream.body, {
		status: upstream.status,
		headers: upstream.headers,
	});
};
