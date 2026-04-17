import { Hono } from "hono";
import { describe, expect, it } from "vitest";

import { ghRedirect } from "../routes/gh-redirect";

describe("ghRedirect", () => {
	it("responds with a 302 redirect to the repo", async () => {
		const app = new Hono();
		app.get("/", ghRedirect);

		const response = await app.fetch(new Request("http://localhost/"));

		expect(response.status).toBe(302);
		expect(response.headers.get("Location")).toBe("https://github.com/morgann1/studio-discover");
	});
});
