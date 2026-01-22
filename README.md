# Qafiyah

The open-source home of Arabic poetry: 944K+ verses from 932 poets across 10 historical eras, with a DB, API, and web interface.

## Links

- Website: [qafiyah.com](https://qafiyah.com)
- API: [api.qafiyah.com](https://api.qafiyah.com)
- Bot: [@qafiyahdotcom](https://x.com/qafiyahdotcom)
- Database Dumps: [Database Backup](https://github.com/alwalxed/qafiyah/tree/main/.db_dumps)

## Architecture

**Monorepo structure:**
- `apps/web` — Next.js application (Cloudflare Pages)
- `apps/api` — Hono REST API (Cloudflare Workers)
- `apps/bot` — Automated Twitter bot
- `packages/` — Shared schemas, configs

**Stack:** Next.js, Hono, PostgreSQL, Drizzle ORM.

## Database

**Current Statistics:**
- 944,844 verses
- 85,342 poems
- 932 poets
- 10 eras
- 44 meters
- 47 rhyme patterns
- 27 themes

**Access:** Database dumps in `.db_dumps/` are updated automatically. Use these for research or integration instead of scraping.

## Quick Start

**Requirements:**
- Node.js 18+
- pnpm 8+
- Docker

**Installation:**
```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
pnpm install
./scripts/setup-local-db.sh
pnpm dev
```

Application runs at `http://localhost:3000`

## Documentation

- [Search Implementation](notes/features/SEARCH.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

## License

[MIT](LICENSE)