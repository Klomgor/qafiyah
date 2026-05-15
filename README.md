<div align="center">

# Qafiyah | قافية

**An open-source repository of Arabic poetry, with database dumps, REST API, and web interface.**

[![Turborepo](https://img.shields.io/badge/Turborepo-monorepo-EF4444?logo=turborepo&logoColor=white)](https://turbo.build/repo)
[![Cloudflare Workers](https://img.shields.io/badge/Cloudflare-Workers-F97316?logo=cloudflare&logoColor=white)](https://workers.cloudflare.com)
[![Astro](https://img.shields.io/badge/Astro-framework-BC52EE?logo=astro&logoColor=white)](https://astro.build)
[![Bun](https://img.shields.io/badge/Bun-runtime-F59E0B?logo=bun&logoColor=white)](https://bun.sh)
[![TypeScript](https://img.shields.io/badge/TypeScript-language-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Hono](https://img.shields.io/badge/Hono-router-E36002?logo=hono&logoColor=white)](https://hono.dev)
[![Drizzle](https://img.shields.io/badge/Drizzle-ORM-C5F74F?logo=drizzle&logoColor=black)](https://orm.drizzle.team)
[![Elasticsearch](https://img.shields.io/badge/Elasticsearch-search-00BCD4?logo=elasticsearch&logoColor=white)](https://www.elastic.co)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-spec-6BA539?logo=openapiinitiative&logoColor=white)](https://api.qafiyah.com)
[![oRPC](https://img.shields.io/badge/oRPC-typesafe%20API-8B5CF6)](https://orpc.unnoq.com)
[![Valibot](https://img.shields.io/badge/Valibot-validation-FACC15?logoColor=black)](https://valibot.dev)
[![Scalar](https://img.shields.io/badge/Scalar-API%20docs-06B6D4)](https://scalar.com)

[Website](https://qafiyah.com) · [API](https://api.qafiyah.com) · [X Bot](https://x.com/qafiyahdotcom) · [HuggingFace Dataset](https://huggingface.co/datasets/qafiyah/classical-arabic-poetry) · [Database Dumps](dumps/)

</div>

---

## About

Qafiyah is an open-source classical Arabic poetry corpus containing **944,844 verses** from **932 poets** spanning **10 historical eras**. The project provides a static website, a public REST API, downloadable PostgreSQL dumps, and a Hugging Face dataset to support readers, researchers, and developers building on top of classical Arabic literature.

## Table of Contents

- [Qafiyah | قافية](#qafiyah--قافية)
  - [About](#about)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Tech Stack](#tech-stack)
    - [Core](#core)
    - [Web (`apps/web`)](#web-appsweb)
    - [API (`apps/api`)](#api-appsapi)
    - [Bot (`apps/bot`)](#bot-appsbot)
    - [Data Layer](#data-layer)
    - [Tooling](#tooling)
  - [Architecture](#architecture)
  - [Database](#database)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
    - [Development](#development)
  - [Scripts](#scripts)
  - [API Documentation](#api-documentation)
  - [Contributing](#contributing)
  - [Acknowledgments](#acknowledgments)
  - [Documentation](#documentation)
  - [License](#license)

## Features

- **Full-text search** across 944,844 verses with Arabic diacritics normalization
- **Faceted browsing** by era, meter (44 types), rhyme pattern (47 patterns), and theme (27 themes)
- **Static-first web app** pre-rendered at build time from the public API
- **Public REST API** on Cloudflare Workers with auto-generated OpenAPI docs
- **X/Twitter bot** posting a random poem four times daily via GitHub Actions
- **Downloadable PostgreSQL dumps** for offline research and integration
- **Hugging Face dataset** for ML/NLP use cases

## Tech Stack

### Core

| Tool                                         | Purpose                                       |
| -------------------------------------------- | --------------------------------------------- |
| [Bun](https://bun.sh)                        | Package manager and JavaScript runtime        |
| [Turborepo](https://turbo.build)             | Monorepo task orchestration and build caching |
| [TypeScript](https://www.typescriptlang.org) | Language across all packages                  |

### Web (`apps/web`)

| Tool                                         | Purpose                                                 |
| -------------------------------------------- | ------------------------------------------------------- |
| [Astro](https://astro.build)                 | Static site framework; pages pre-rendered at build time |
| [React](https://react.dev)                   | Interactive islands (search, nav, random poem)          |
| [TailwindCSS](https://tailwindcss.com)       | Utility-first CSS                                       |
| [Radix UI](https://www.radix-ui.com)         | Unstyled accessible UI primitives                       |
| [TanStack Query](https://tanstack.com/query) | Server-state and data-fetching in React islands         |

### API (`apps/api`)

| Tool                                                 | Purpose                                                         |
| ---------------------------------------------------- | --------------------------------------------------------------- |
| [Hono](https://hono.dev)                             | Lightweight HTTP framework on Cloudflare Workers                |
| [oRPC](https://orpc.unnoq.com)                       | Type-safe RPC with shared contracts                             |
| [Valibot](https://valibot.dev)                       | Schema validation for all oRPC contract inputs and outputs      |
| [OpenAPI](https://www.openapis.org)                  | API spec auto-generated from oRPC contracts via `@orpc/openapi` |
| [Scalar](https://scalar.com)                         | Interactive API documentation served at `/docs`                 |
| [Cloudflare Workers](https://workers.cloudflare.com) | Serverless runtime; deployed via Wrangler                       |

### Bot (`apps/bot`)

| Tool                                                            | Purpose                                 |
| --------------------------------------------------------------- | --------------------------------------- |
| [twitter-api-v2](https://github.com/PLhery/node-twitter-api-v2) | X/Twitter API client                    |
| [tsx](https://github.com/privatenumber/tsx)                     | TypeScript execution for the bot script |
| [dotenv](https://github.com/motdotla/dotenv)                    | Environment variable loading            |

### Data Layer

| Tool                                     | Purpose                                                       |
| ---------------------------------------- | ------------------------------------------------------------- |
| [Drizzle ORM](https://orm.drizzle.team)  | SQL query builder and schema definitions in `packages/db`     |
| [PostgreSQL](https://www.postgresql.org) | Primary database; full-text search via `tsvector`/GIN indexes |
| [Elasticsearch](https://www.elastic.co)  | Semantic search index (in active development)                 |
| [Docker](https://www.docker.com)         | Local Postgres containers for development and testing         |

### Tooling

| Tool                                      | Purpose                                              |
| ----------------------------------------- | ---------------------------------------------------- |
| [Biome](https://biomejs.dev)              | Linting and formatting for all JS/TS files           |
| [Prettier](https://prettier.io)           | Formatting for non-JS assets                         |
| [Vitest](https://vitest.dev)              | Unit and integration tests across all workspaces     |
| [Husky](https://typicode.github.io/husky) | Git hooks                                            |
| [commitlint](https://commitlint.js.org)   | Conventional commit enforcement                      |
| [Knip](https://knip.dev)                  | Detection of unused files, dependencies, and exports |
| [Madge](https://github.com/pahen/madge)   | Circular dependency detection                        |
| [Hugging Face](https://huggingface.co)    | Public dataset hosting for ML/NLP use cases          |

## Architecture

Qafiyah is a Bun + Turborepo monorepo.

```
qafiyah/
├── apps/
│   ├── web/          Astro 6 static site; queries the API at build time via oRPC
│   ├── api/          Hono REST API on Cloudflare Workers
│   └── bot/          X/Twitter bot; posts 4× daily via GitHub Actions cron
└── packages/
    ├── db/           Shared Drizzle ORM schema, queries, and Postgres client
    ├── contracts/    Shared oRPC contract definitions
    ├── constants/    Shared brand, URLs, and dev-port constants
    └── typescript/   Shared TypeScript configs (base, astro, cloudflare, node)
```

**Data flow:**

- `apps/web` is fully static. It queries the API at build time via oRPC (`src/lib/api/static.ts`) and falls back to the production API from the browser for interactive features.
- `apps/api` is the single source of truth for queries, with `packages/db` as its sole consumer of the database.
- `packages/contracts` defines the oRPC contracts shared between `apps/api` (server procedures) and `apps/web` (typed client).

## Database

**Current statistics:**

| Entity         | Count   |
| -------------- | ------- |
| Verses         | 944,844 |
| Poems          | 85,342  |
| Poets          | 932     |
| Eras           | 10      |
| Meters         | 44      |
| Rhyme patterns | 47      |
| Themes         | 27      |

PostgreSQL custom-format dumps are published in [`dumps/`](dumps) and refreshed periodically. They are provided for research and integration as an alternative to scraping the API. See the [restore instructions](dumps/README.md); restoring requires PostgreSQL ≥ 17 and `pg_restore`.

## Getting Started

### Prerequisites

- Node.js ≥ 20
- Bun ≥ 1.3.14 (enforced via `packageManager`)
- Docker (for the local Postgres containers spun up by `db:setup`)

### Installation

```bash
git clone https://github.com/alwalxed/qafiyah.git
cd qafiyah
bun install
```

### Development

```bash
bun run db:setup   # boots dev + test Postgres in Docker and restores the latest dump
bun run dev        # runs all workspaces via Turbo
```

## Scripts

| Script             | Description                                                |
| ------------------ | ---------------------------------------------------------- |
| `bun run dev`      | Run all workspaces in development mode via Turbo           |
| `bun run build`    | Build all workspaces                                       |
| `bun run test`     | Run Vitest across all workspaces                           |
| `bun run lint`     | Lint with Biome                                            |
| `bun run format`   | Format with Biome                                          |
| `bun run db:setup` | Boot dev + test Postgres in Docker and restore latest dump |

## API Documentation

The public REST API is hosted at [`api.qafiyah.com`](https://api.qafiyah.com) and ships with interactive documentation at [`api.qafiyah.com/docs`](https://api.qafiyah.com/docs), generated from oRPC contracts via `@orpc/openapi` and rendered with Scalar.

## Contributing

Contributions are welcome. Before opening a pull request, please read:

- [Contributing Guidelines](.github/CONTRIBUTING.md)
- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Security Policy](.github/SECURITY.md)

## Acknowledgments

Listed chronologically by date of contribution:

- **[Khalid Alraddady](https://www.linkedin.com/in/khalid-alraddady/)**, AI Engineer at [HRSD](https://www.hrsd.gov.sa/en). Development of the semantic search feature currently under active development.
- **[Khalid Almulaify](https://github.com/khalidmfy)**, PhD in Morphology and Syntax at [IMSIU](https://imamu.edu.sa). Ongoing financial sponsorship ($100/month) and extensive usage of the public API through a widely used [Telegram bot](https://t.me/QafiyahVerseBot).
- **[Malath Alsaif](https://www.linkedin.com/in/malath-a-alsaif-a49a382a7/)**, Software Engineer at [Ejari](https://www.ejari.sa). UI improvements and implementation of the local database development workflow.
- **[Fahad Alghamdi](https://github.com/v0id-user)**, Software Engineer at [Thmanyah](https://thmanyah.com). Flagged a redundant per-request `SELECT 1` health check in the DB middleware that added unnecessary latency on every request.

## Documentation

- [Search Implementation](docs/SEARCH_FEATURE_IMPLEMENTATION.md)
- [Contributing Guidelines](.github/CONTRIBUTING.md)
- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Security Policy](.github/SECURITY.md)

## License

Released under the [MIT License](LICENSE).
