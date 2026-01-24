# Qafiyah

An open-source repository of Arabic poetry containing over 944,000 verses from 932 poets spanning 10 historical eras, with database dumps, REST API, and web interface.

## Links

- Website: [qafiyah.com](https://qafiyah.com)
- API: [api.qafiyah.com](https://api.qafiyah.com)
- Bot: [@qafiyahdotcom](https://x.com/qafiyahdotcom)
- Database Dumps: [Database Backup](https://github.com/alwalxed/qafiyah/tree/main/.db_dumps)

## Architecture

This is a monorepo containing:

- `apps/web` — Next.js application (Cloudflare Pages)
- `apps/api` — Hono REST API (Cloudflare Workers)
- `apps/bot` — Automated Twitter bot
- `packages/` — Shared schemas and configurations

**Technology Stack:** Next.js, Hono, PostgreSQL, Drizzle ORM

## Database

**Current Statistics:**
- 944,844 verses
- 85,342 poems
- 932 poets
- 10 eras
- 44 meters
- 47 rhyme patterns
- 27 themes

Database dumps are available in `.db_dumps/` and are updated automatically. These are provided for research and integration purposes as an alternative to scraping the API.

## Quick Start

**Requirements:**
- Node.js 18 or higher
- pnpm 8 or higher
- Docker

**Installation:**
```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
pnpm install
./scripts/setup-local-db.sh
pnpm dev
```

The application will run at `http://localhost:3000`

## Documentation

- [Search Implementation](notes/features/SEARCH.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

## License

[MIT](LICENSE)

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