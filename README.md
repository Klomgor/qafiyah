# Qafiyah

Open-source Arabic poetry database, web app, API, and bot. Built with Next.js, Hono, and PostgreSQL.

- **Website:** [qafiyah.com](https://qafiyah.com)
- **API:** [api.qafiyah.com](https://api.qafiyah.com)
- **Bot:** [@qafiyahdotcom](https://x.com/qafiyahdotcom)

## Features

- ~1M verses across ~86K poems from ~900 poets
- Organized by era, meter, rhyme, and theme
- RESTful API access
- Twitter bot posting a random verse hourly
- Open database dumps (auto-updated on changes)

## Tech Stack

| Layer       | Technologies                          |
|-------------|---------------------------------------|
| Frontend   | Next.js, React Query, Tailwind CSS, Zustand |
| Backend    | Hono, Cloudflare Workers              |
| Database   | PostgreSQL, Drizzle ORM               |
| Infra      | Cloudflare Pages/Workers, GitHub Actions, Hetzner |

## Data Stats

- Verses: 944,844
- Poems: 85,342
- Poets: 932
- Eras: 10
- Meters: 44
- Rhymes: 47
- Themes: 27

**Note:** Latest full `.db_dumps/` available for research/dev/integration. Auto-updated on changes. Use dumps instead of scraping the API/site.

## Getting Started

### Prerequisites

- Node.js ≥18
- pnpm ≥8
- Docker (for local DB)

### Install

```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
pnpm install
```

### Setup DB

```bash
./scripts/setup-local-db.sh
```

### Run

```bash
pnpm dev
```

Access at http://localhost:3000.

## Documentation

- [Search Implementation](notes/features/SEARCH.md)
- [Contributing](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

## License

MIT. See [LICENSE](LICENSE).