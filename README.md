# Qafiyah

![License](https://img.shields.io/github/license/alwalxed/qafiyah)
![TypeScript](https://img.shields.io/badge/TypeScript-5.8-blue)
![Cloudflare Workers](https://img.shields.io/badge/Cloudflare-Workers-orange)

An open-source repository of Arabic poetry containing over 944,000 verses from 932 poets spanning 10 historical eras, with database dumps, REST API, and web interface.

## Features

- Full-text search across 944,844 verses with Arabic diacritics normalization
- Browse by era, meter (44 types), rhyme pattern (47 patterns), and theme (27 themes)
- Static site pre-rendered at build time from the public API
- Public REST API on Cloudflare Workers with OpenAPI documentation
- X/Twitter bot posting a random poem four times daily via GitHub Actions
- Downloadable PostgreSQL database dumps for offline research and integration
- Hugging Face dataset for ML/NLP use cases

## Links

- [Website](https://qafiyah.com)
- [Public API](https://api.qafiyah.com)
- [X Bot](https://x.com/qafiyahdotcom)
- [Database Download](dumps/)
- [Hugging Face Dataset](https://huggingface.co/datasets/qafiyah/classical-arabic-poetry)

## Architecture

bun + Turborepo monorepo:

- `apps/web`, Astro 6 static site; queries the API at build time via oRPC (`src/lib/api/static.ts`), and at runtime from the browser against the production API
- `apps/api`, Hono REST API on Cloudflare Workers
- `apps/bot`, X (Twitter) bot that posts a random poem 4× daily via GitHub Actions cron
- `packages/db`, Shared Drizzle ORM schema, queries, and Postgres client; sole consumer is `apps/api`
- `packages/contracts`, Shared oRPC contract definitions consumed by `apps/api` and typed at build time by `apps/web`
- `packages/constants`, Shared brand, URLs, and dev-port constants
- `packages/typescript`, Shared TypeScript configs (base, astro, cloudflare, node)

**Tech stack:**

| Tool | Version | Purpose |
|------|---------|---------|
| [bun](https://bun.sh) | 1.3.14 | Package manager and JavaScript runtime |
| [Turborepo](https://turbo.build) | 2.5 | Monorepo task orchestration and build caching |
| [TypeScript](https://www.typescriptlang.org) | 5.8 | Language across all packages |
| [Astro](https://astro.build) | 6.3 | Static site framework for `apps/web`; all pages pre-rendered at build time |
| [React](https://react.dev) | 19 | Interactive islands in `apps/web` (search, nav, random poem) |
| [TailwindCSS](https://tailwindcss.com) | 3 | Utility-first CSS for `apps/web` |
| [Radix UI](https://www.radix-ui.com) |, | Unstyled accessible UI primitives (used in search island) |
| [TanStack Query](https://tanstack.com/query) | 5 | Server-state and data-fetching in React islands |
| [Hono](https://hono.dev) | 4.11 | Lightweight HTTP framework for `apps/api` on Cloudflare Workers |
| [oRPC](https://orpc.unnoq.com) | 1.14 | Type-safe RPC, shared contracts (`packages/contracts`), server procedures (`apps/api`), typed client (`apps/web`) |
| [Valibot](https://valibot.dev) | 1.0 | Schema validation for all oRPC contract inputs and outputs |
| [OpenAPI](https://www.openapis.org) | 3.1 | API spec auto-generated from oRPC contracts via `@orpc/openapi`; served as interactive docs at `/docs` |
| [Drizzle ORM](https://orm.drizzle.team) | 0.45 | SQL query builder and schema definitions in `packages/db` |
| [PostgreSQL](https://www.postgresql.org) | ≥17 | Primary database; full-text search via `tsvector`/GIN indexes with Arabic diacritics normalization |
| [Cloudflare Workers](https://workers.cloudflare.com) |, | Serverless runtime for `apps/api`; deployed via Wrangler |
| [Docker](https://www.docker.com) |, | Local Postgres containers for development and testing (`bun run db:setup`) |
| [Biome](https://biomejs.dev) | 2.3 | Linting and formatting for all JS/TS files |
| [Vitest](https://vitest.dev) | 4 | Unit and integration tests across all workspaces |
| [Hugging Face](https://huggingface.co) |, | Public dataset hosting for ML/NLP use cases |

## Database

**Current statistics:**

- 944,844 verses
- 85,342 poems
- 932 poets
- 10 eras
- 44 meters
- 47 rhyme patterns
- 27 themes

PostgreSQL custom-format dumps are published in [`dumps`](dumps) and refreshed periodically. They are provided for research and integration as an alternative to scraping the API. See the [restore instructions](dumps/README.md) (requires PostgreSQL ≥ 17 and `pg_restore`).

## Quick Start

**Requirements:**

- Node.js ≥ 20
- bun ≥ 1.3.14 (enforced via `packageManager`)
- Docker (for the local Postgres containers spun up by `db:setup`)

**Installation:**

```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
bun install
bun run db:setup   # boots dev + test Postgres in Docker and restores the latest dump
bun run dev        # runs all workspaces via Turbo
```

## Contributing

Contributions are welcome. See the [Contributing Guidelines](.github/CONTRIBUTING.md) and the [Code of Conduct](.github/CODE_OF_CONDUCT.md) before opening a pull request.

## Acknowledgments

The Qafiyah project acknowledges the following contributors, listed chronologically by date of contribution:

- [Khalid Alraddady](https://www.linkedin.com/in/khalid-alraddady/), AI Engineer at [HRSD](https://www.hrsd.gov.sa/en), Development of the semantic search feature currently under active development.

- [Khalid Almulaify](https://github.com/khalidmfy), PhD in Morphology and Syntax at [IMSIU](https://imamu.edu.sa), Ongoing financial sponsorship ($100/month) and extensive usage of the public API through a widely used [Telegram bot](https://t.me/QafiyahVerseBot).

- [Malath Alsaif](https://www.linkedin.com/in/malath-a-alsaif-a49a382a7/), Software Engineer at [Ejari](https://www.ejari.sa), UI improvements and implementation of the local database development workflow.

- [Fahad Alghamdi](https://github.com/v0id-user), Software Engineer at [Thmanyah](https://thmanyah.com), Flagged a redundant per-request `SELECT 1` health check in the DB middleware that added unnecessary latency on every request.

## Documentation

- [Search Implementation](docs/SEARCH_FEATURE_IMPLEMENTATION.md)
- [Contributing Guidelines](.github/CONTRIBUTING.md)
- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Security Policy](.github/SECURITY.md)

## License

[MIT](LICENSE)
