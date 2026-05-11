# Qafiyah

An open-source repository of Arabic poetry containing over 944,000 verses from 932 poets spanning 10 historical eras, with database dumps, REST API, and web interface.

## Links

- [Website](https://qafiyah.com)
- [Public API](https://api.qafiyah.com)
- [Twitter Bot](https://x.com/qafiyahdotcom)
- [Database Download](data/datasets/)
- [Hugging Face Dataset](https://huggingface.co/datasets/qafiyah/classical-arabic-poetry)

## Architecture

This is a monorepo containing:

- `apps/web`: Astro static site
- `apps/api`: Hono REST API (Cloudflare Workers)
- `apps/bot`: Twitter bot that posts poems
- `packages/db`: Shared Drizzle ORM queries and schema
- `packages/typescript`: Shared TypeScript configuration

**Tech Stack:** Astro, Hono, PostgreSQL, Drizzle ORM

## Database

**Current Statistics:**

- 944,844 verses
- 85,342 poems
- 932 poets
- 10 eras
- 44 meters
- 47 rhyme patterns
- 27 themes

Database dumps are available in [`data/datasets`](data/datasets) and are updated automatically. These are provided for research and integration purposes as an alternative to scraping the API.

## Quick Start

**Requirements:**

- Node.js 18 or higher
- pnpm 10 or higher
- Docker

**Installation:**

```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
pnpm install
./dev/setup-database.sh
pnpm dev
```

The web app runs at `http://localhost:4321` and the API at `http://localhost:8787`.

**Local database:** `./dev/setup-database.sh` creates two PostgreSQL instances and writes `apps/api/.dev.vars` + `apps/web/.env` (dev, port 5433) and `apps/api/.dev.vars.test` (test/micro, port 5434, ~300 poems for fast build validation). Use `pnpm dev` for normal development; use `pnpm turbo run dev:test --filter=@qafiyah/api` then `pnpm turbo run build --filter=@qafiyah/web` for fast build validation. Production: set `DATABASE_URL` in `.env.prod` (manual).

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
