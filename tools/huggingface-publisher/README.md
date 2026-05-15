# Hugging Face Publisher

Publishes the Qafiyah poetry dataset to Hugging Face Hub.

## Prerequisites

- Python 3.10 or later
- The local database must be running on port 5433, run `bun run db:setup` from the monorepo root first
- A Hugging Face account with write access to the `qafiyah` organization

## Setup

```bash
cd tools/huggingface-publisher
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
hf auth login
```

## Usage

Preview without uploading:

```bash
python publish.py --dry-run
```

Publish to Hugging Face:

```bash
python publish.py
```

### Options

| Flag             | Description                                     | Default                           |
| ---------------- | ----------------------------------------------- | --------------------------------- |
| `--dry-run`      | Preview dataset without uploading               | false                             |
| `--repo`         | Target Hugging Face repository                  | `qafiyah/classical-arabic-poetry` |
| `--database-url` | SQLAlchemy-compatible PostgreSQL connection URL | `postgresql+psycopg2:///qafiyah`  |

## Environment Variables

The `--database-url` flag accepts any SQLAlchemy-compatible PostgreSQL URL. To connect to the Docker Postgres instance started by `bun run db:setup`:

```bash
python publish.py --database-url "postgresql+psycopg2://qafiyah:qafiyah@127.0.0.1:5433/qafiyah"
```

The Hugging Face token is read from the environment after `hf auth login`. Do not hard-code credentials.

## Output

Running `python publish.py` exports the following from the local database and uploads it to the `qafiyah/classical-arabic-poetry` repository on Hugging Face Hub:

- All poems with full content and `*`-separated verse structure
- Poet name, slug, and biography
- Era, meter, theme, and rhyme pattern metadata
- A `verses` field (list of individual verses, pre-split from content)
- A `text` field (verses joined by newlines for plain-text use)

The dataset card (`dataset_card.md`) is uploaded alongside the data as the repository README.
