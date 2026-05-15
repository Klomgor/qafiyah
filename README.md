# Qafiyah

An open-source repository of Arabic poetry containing over 944,000 verses from 932 poets spanning 10 historical eras, with database dumps, REST API, and web interface.

## Links

- [Website](https://qafiyah.com)
- [Public API](https://api.qafiyah.com)
- [X Bot](https://x.com/qafiyahdotcom)
- [Database Download](dumps/)
- [Hugging Face Dataset](https://huggingface.co/datasets/qafiyah/classical-arabic-poetry)

## Architecture

bun + Turborepo monorepo:

- `apps/web`, Astro 6 static site; queries the database directly at build time
- `apps/api`, Hono REST API on Cloudflare Workers
- `apps/bot`, X (Twitter) bot that posts a random poem 4× daily via GitHub Actions cron
- `packages/db`, Shared Drizzle ORM schema, queries, and Postgres client
- `packages/constants`, Shared brand, URLs, and dev-port constants
- `packages/typescript`, Shared TypeScript configs (base, astro, cloudflare, node)

**Tech stack:** Astro 6, React (islands), Hono, Cloudflare Workers, PostgreSQL, Drizzle ORM, Turborepo, Biome, Vitest

## Database

**Current statistics:**

- 944,844 verses
- 85,342 poems
- 932 poets
- 10 eras
- 44 meters
- 47 rhyme patterns
- 27 themes

PostgreSQL custom-format dumps are published in [`dumps`](dumps) and refreshed periodically. They are provided for research and integration as an alternative to scraping the API. See the [restore instructions](dumps/README.md) (requires PostgreSQL ≥ 17 and `pg_restore`)

## Quick Start

**Requirements:**

- Node.js ≥ 20
- bun ≥ 1.3 (enforced via `packageManager`)
- Docker (for the local Postgres containers spun up by `db:setup`)

**Installation:**

```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
bun install
bun run db:setup   # boots dev + test Postgres in Docker and restores the latest dump
bun run dev        # runs all workspaces via Turbo
```

## Acknowledgments

The Qafiyah project acknowledges the following contributors, listed chronologically by date of contribution:

- **<a href="https://www.linkedin.com/in/khalid-alraddady/" target="_blank" rel="noopener">Khalid Alraddady</a>**, AI Engineer @ <a href="https://www.hrsd.gov.sa/en" target="_blank" rel="noopener">HRSD</a><br>
  Development of the semantic search feature currently under active development.

- **<a href="https://github.com/khalidmfy" target="_blank" rel="noopener">Khalid Almulaify</a>**, PhD in Morphology and Syntax @ <a href="https://imamu.edu.sa" target="_blank" rel="noopener">IMSIU</a><br>
  Ongoing financial sponsorship ($100/month) and extensive usage of the public API through a widely used <a href="https://t.me/QafiyahVerseBot" target="_blank" rel="noopener">Telegram bot</a>.

- **<a href="https://www.linkedin.com/in/malath-a-alsaif-a49a382a7/" target="_blank" rel="noopener">Malath Alsaif</a>**, Software Engineer @ <a href="https://www.ejari.sa" target="_blank" rel="noopener">Ejari</a><br>
  UI improvements and implementation of the local database development workflow.

- **<a href="https://github.com/v0id-user" target="_blank" rel="noopener">Fahad Alghamdi</a>**, Software Engineer @ <a href="https://thmanyah.com" target="_blank" rel="noopener">Thmanyah</a><br>
  Flagged a redundant per-request `SELECT 1` health check in the DB middleware that added unnecessary latency on every request.

## Documentation

- [Search Implementation](docs/SEARCH_FEATURE_IMPLEMENTATION.md)
- [Contributing Guidelines](.github/CONTRIBUTING.md)
- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Security Policy](.github/SECURITY.md)

## License

[MIT](LICENSE)
