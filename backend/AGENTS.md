# Backend (Cloudflare Worker)

Thin proxy that forwards plugin traffic to `api.wally.run` with a proper `User-Agent`. See the root [`AGENTS.md`](../AGENTS.md) for project-wide priorities and style guides (TypeScript style lives at [`docs/process/typescript-style.md`](../docs/process/typescript-style.md)).

## Commands

| Command               | Purpose                                |
| --------------------- | -------------------------------------- |
| `npx wrangler dev`    | Local development                      |
| `npx wrangler deploy` | Deploy to Cloudflare                   |
| `npx wrangler types`  | Regenerate `worker-configuration.d.ts` |

Run `wrangler types` after editing bindings in `wrangler.jsonc`.

## Docs

- Workers runtime + APIs: https://developers.cloudflare.com/workers/
- Error reference: https://developers.cloudflare.com/workers/observability/errors/

Cloudflare ships fast — if you're doing anything non-trivial, fetch the current docs before writing code.

## Scope

This worker is deliberately small: a `fetch` handler that rewrites the URL and adds a header. Stay in that lane. If it grows to need KV, R2, D1, Durable Objects, Queues, Workflows, etc., add the relevant best-practices link back into this file before using them.
