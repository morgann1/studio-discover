import { ghRedirect } from "./routes";

type Handler = (request: Request) => Response | Promise<Response>;

const routes: Record<string, Handler> = {
	"/": ghRedirect,
};

export default {
	async fetch(request): Promise<Response> {
		const url = new URL(request.url);
		const handler = routes[url.pathname];

		if (handler) {
			return handler(request);
		}

		return new Response("Not found", { status: 404 });
	},
} satisfies ExportedHandler<Env>;
