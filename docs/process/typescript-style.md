# TypeScript Style

Adapted from [Google's TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html). Full source is the canonical reference — this is a working summary biased toward what matters for small server-side code (Cloudflare Workers, edge proxies), skipping Angular/Closure-specific parts.

## Philosophy

- **Strictness is the default.** Turn on `strict` in `tsconfig.json`. The whole language works better when nothing is implicitly `any`.
- **Prefer inference to annotation.** Annotate what crosses module boundaries; let the compiler infer the rest.
- **No `any`, ever.** If you need an escape hatch, use `unknown` and narrow.
- **Code should be obvious.** Prefer plain code the reader can scan over clever types the reader has to decode.

## Source files

- **UTF-8, LF.** No BOM.
- **One concept per file.** Don't pack unrelated helpers into one module.
- **No default exports.** Always named exports — they rename cleanly, auto-import cleanly, and keep imports consistent across callers.

## Imports

- **Use ES module imports** (`import { foo } from "./foo"`) — no CommonJS `require` in application code.
- **No namespace imports from your own code** (`import * as Foo from ...`) unless the module intentionally exposes a namespace shape. Named imports are clearer.
- **Alphabetize imports** and group them: stdlib/runtime first, then third-party, then local. Most formatters do this for you.
- **Use `import type` for type-only imports** so the compiler can drop them cleanly.
- **Avoid renaming imports** (`import { foo as bar }`) unless resolving a real name collision.

## Variables

- **`const` by default, `let` when reassigned, never `var`.**
- **One declaration per statement.** `const a = 1, b = 2` obscures intent.
- **Declare at point of use**, not at the top of a long function.

## Types

- **Prefer `interface` over `type` for object shapes.** Interfaces support declaration merging and usually produce better error messages. Use `type` for unions, intersections, mapped types, or anything an interface can't express.
- **Always annotate exported function signatures** (params + return). Let inference handle internal helpers.
- **Use `unknown`, not `any`.** `unknown` forces narrowing at the use site, which is the point.
- **Prefer `undefined` over `null`** for "not set" / "not yet computed". Only use `null` when an API or JSON payload specifically produces it. Don't mix the two for the same field.
- **String-literal unions beat enums.** `type Mode = "read" | "write"` — they're inferrable, erasable, and don't ship runtime cost like real enums. Never use `const enum`.
- **Avoid type assertions (`x as T`).** They silence the checker. If you need one, prefer a user-defined type guard (`function isT(x): x is T`).
- **Don't use wrapper types** (`String`, `Number`, `Boolean`). Use primitives.

## Naming

- **`camelCase`** for variables, functions, parameters, methods, properties.
- **`PascalCase`** for classes, interfaces, type aliases, enums, type parameters.
- **`UPPER_SNAKE_CASE`** for module-level constants that are truly constant (e.g. magic numbers, config keys). Not for every `const`.
- **No Hungarian notation, no `I` prefix on interfaces, no `T` prefix on type aliases.**
- **Descriptive names win.** `retryCount` > `n`, `requestHeaders` > `h`. Single-letter names are acceptable only for loop indices and very short lambdas.
- **Boolean names read as yes/no questions.** `isReady`, `hasToken`, not `ready` or `token`.

## Functions

- **`function` declarations for named, top-level exports.** They hoist and show up nicely in stack traces.
- **Arrow functions for callbacks and short inline uses.** Use the concise body (`x => x + 1`) when the function fits on one line.
- **No `function` expressions** — arrows or named declarations, nothing in between.
- **Return types on exported functions.** Skip them on internal helpers where inference is fine.
- **Prefer rest/spread over `arguments`.** `arguments` is untyped and doesn't play well with arrows.

## Async

- **`async`/`await` over raw Promise chains** for readability.
- **Don't `await` in loops** when the iterations are independent — build an array of promises and `Promise.all` them.
- **Every async function has a return type annotation** (usually `Promise<T>`) so the caller sees the shape without hovering.
- **Errors propagate by `throw`** from async functions; callers `try`/`catch` or let it bubble. Don't return `{ ok, error }` tuples unless there's a real reason.

## Control flow

- **`===` and `!==` only.** `==` coercion is never what you want.
- **Early-return over deep nesting.** Same rule as Luau.
- **`for-of` or `.forEach` / `.map` for arrays.** Never `for-in` on arrays — it enumerates all enumerable keys including inherited ones.
- **`switch` statements fall through explicitly** (with a comment) if intended; otherwise each case ends in `break` or `return`. Include a `default` branch — use an exhaustiveness helper for string unions.
- **Keep `try` blocks narrow.** Wrap only the code that can actually throw, so you don't accidentally catch unrelated bugs.

## Disallowed

- **`var`** — always `const`/`let`.
- **`any`** — `unknown` or a real type.
- **`==` / `!=`** — strict equality only.
- **`eval`, `new Function(...)`, and friends** — dynamic code evaluation.
- **`const enum`** — use string-literal unions.
- **Modifying built-ins** (adding methods to `Array.prototype`, etc.).
- **Default exports.**
- **Namespaces** (use modules).
- **Debugger statements in committed code.**

## Comments

- **JSDoc for exported APIs**, plain `//` for internal notes.
- **Describe *why*, not *what*.** Same rule as everywhere else.
- **No historical commentary, no changelogs in source, no commented-out code.** Git is the history.
- **Don't duplicate the type system in JSDoc.** `@param {string} name` is noise when the param is already typed `name: string`.

## Errors

- **Throw `Error` or a subclass.** Never `throw "string"` — strings lose the stack.
- **Create a narrow subclass** (`class RateLimitError extends Error`) when callers need to distinguish reasons.
- **Preserve the cause** when re-throwing: `throw new Error("...", { cause: err })`.
