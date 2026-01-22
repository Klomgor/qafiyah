# Qafiyah | قافية

An open-source Arabic poetry database and web platform containing over 944,000 verses from 932 poets spanning 10 historical eras. Built with Next.js, Hono, and PostgreSQL.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Data Statistics](#data-statistics)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Database Setup](#database-setup)
  - [Development](#development)
- [Database Access](#database-access)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Overview

Qafiyah is a comprehensive digital archive of classical and contemporary Arabic poetry. The platform provides structured access to poetic works with detailed metadata including poet information, historical periods, poetic meters, rhyme schemes, and thematic classifications.

**Website:** [qafiyah.com](https://qafiyah.com)
**API:** [api.qafiyah.com](https://api.qafiyah.com)
**Twitter Bot:** [@qafiyahdotcom](https://x.com/qafiyahdotcom)

## Features

- Searchable database of 944,844+ verses across 85,342+ poems
- Poetry organized by historical era, meter, rhyme, and theme
- RESTful API for programmatic access
- Open database dumps updated with every change
- Automated Twitter bot posting curated selections

## Architecture

The project is structured as a monorepo with the following components:

- **Web Application:** Next.js frontend deployed on Cloudflare Pages
- **API Service:** Hono-based REST API running on Cloudflare Workers
- **Twitter Bot:** Automated posting service scheduled via GitHub Actions
- **Shared Packages:** Common Zod schemas, ESLint configurations, and TypeScript definitions

## Technology Stack

| Layer | Technologies |
|-------|-------------|
| Frontend | Next.js, React Query, Tailwind CSS, Zustand |
| Backend | Hono, Cloudflare Workers |
| Database | PostgreSQL, Drizzle ORM |
| Infrastructure | Cloudflare Pages, Cloudflare Workers, GitHub Actions |

## Data Statistics

- **Total Verses:** 944,844
- **Total Poems:** 85,342
- **Poets:** 932
- **Historical Eras:** 10
- **Poetic Meters:** 44
- **Rhyme Schemes:** 47
- **Thematic Categories:** 27

For the most current data, refer to the database dumps in `.db_dumps/` rather than scraping the API or website.

## Getting Started

### Prerequisites

- Node.js 18.x or higher
- pnpm 8.x or higher
- Docker (for local database)

### Installation
```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
pnpm install
```

### Database Setup
```bash
./scripts/setup-local-db.sh
```

### Development
```bash
pnpm dev
```

The web application will be available at `http://localhost:3000`.

## Database Access

Complete database dumps are available in the `.db_dumps/` directory and are updated automatically with each schema or data change. These dumps are provided for research, analysis, local development, data integration, and archival purposes.

Please use these dumps instead of scraping the website or API.

## Documentation

- [Search Implementation](./notes/features/SEARCH.md)
- [Contributing Guidelines](./CONTRIBUTING.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)
- [Security Policy](./SECURITY.md)

## Contributing

Contributions are welcome. Please read the [Contributing Guidelines](./CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.