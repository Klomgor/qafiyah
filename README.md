# Qafiyah

An open-source repository of Arabic poetry containing over 944,000 verses from 932 poets spanning 10 historical eras, with database dumps, REST API, and web interface.

## Links

- [Website](https://qafiyah.com)
- [Public API](https://api.qafiyah.com)
- [X Bot](https://x.com/qafiyahdotcom)
- [Database Download](data/datasets/)
- [Hugging Face Dataset](https://huggingface.co/datasets/qafiyah/classical-arabic-poetry)

## Architecture

pnpm + Turborepo monorepo:

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

PostgreSQL custom-format dumps are published in [`data/datasets`](data/datasets) and refreshed periodically. They are provided for research and integration as an alternative to scraping the API. See the [restore instructions](data/datasets/README.md) (requires PostgreSQL ≥ 17 and `pg_restore`)

## Quick Start

**Requirements:**

- Node.js ≥ 20
- pnpm 10 (enforced via `packageManager`)
- Docker (for the local Postgres containers spun up by `db:setup`)

**Installation:**

```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
pnpm install
pnpm db:setup   # boots dev + test Postgres in Docker and restores the latest dump
pnpm dev        # runs all workspaces via Turbo
```

## Acknowledgments

The Qafiyah project acknowledges the following contributors, listed chronologically by date of contribution:

- **Khalid Alraddady**, AI Engineer at [HRSD](https://www.hrsd.gov.sa/en)<br>
  Contribution: Development of the semantic search feature currently under active development.<br>
  Links: [LinkedIn](https://www.linkedin.com/in/khalid-alraddady/)

- **Khalid Almulaify**, PhD in Morphology and Syntax at [IMSIU](https://imamu.edu.sa)<br>
  Contribution: Ongoing financial sponsorship ($100/month) and extensive usage of the public API through a widely used [Telegram bot](https://t.me/QafiyahVerseBot).<br>
  Links: [GitHub](https://github.com/khalidmfy)

- **Malath Alsaif**, Software Engineer at [Ejari](https://www.ejari.sa)<br>
  Contribution: UI improvements and implementation of the local database development workflow.<br>
  Links: [LinkedIn](https://www.linkedin.com/in/malath-a-alsaif-a49a382a7/)

## Documentation

- [Search Implementation](data/docs/SEARCH_FEATURE_IMPLEMENTATION.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

## License

[MIT](LICENSE)
