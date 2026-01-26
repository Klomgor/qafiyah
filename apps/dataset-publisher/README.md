# Dataset Publisher

Publishes the Qafiyah dataset to Hugging Face Hub.

## Prerequisites

- Python 3.10+
- PostgreSQL 16+ (with `pg_restore` available)
- A Hugging Face account with write access to the target repository

## Setup

1. Create and activate a virtual environment:

```bash
cd apps/dataset-publisher
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Set up environment variables:

```bash
cp .env.example .env
```

Then edit `.env` and add your Hugging Face token:

```
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

You can get a token from [Hugging Face Settings](https://huggingface.co/settings/tokens). The token needs **write** access.

## Database Setup

Before running the publisher, you need to restore the database dump to a local PostgreSQL instance:

1. Create the database:

```bash
createdb -U postgres qafiyah
```

2. Restore the latest dump (the script will automatically find it):

```bash
pg_restore \
  -U postgres \
  -d qafiyah \
  -F c \
  --no-owner \
  --no-acl \
  ../../.db_dumps/0002_10_06_2025/qafiyah_public_20250610_1424.dump
```

Or use the setup script from the repository root:

```bash
./scripts/setup-local-db.sh
```

## Usage

Run the publisher:

```bash
python publish.py
```

### Options

- `--dry-run`: Preview what would be uploaded without actually pushing to Hugging Face
- `--repo`: Override the target repository (default: `qafiyah/classical-arabic-poetry`)

```bash
# Preview the dataset
python publish.py --dry-run

# Push to a different repository
python publish.py --repo your-username/your-dataset
```

## Dataset Schema

The published dataset includes the following fields:

| Field           | Type         | Description             |
| --------------- | ------------ | ----------------------- |
| `poem_id`       | int64        | Unique poem identifier  |
| `poem_slug`     | string       | URL-friendly poem slug  |
| `title`         | string       | Poem title              |
| `content`       | string       | Full poem text (raw)    |
| `poet_name`     | string       | Poet name               |
| `poet_slug`     | string       | URL-friendly poet slug  |
| `poet_bio`      | string       | Poet biography          |
| `era_name`      | string       | Historical era name     |
| `era_slug`      | string       | URL-friendly era slug   |
| `meter_name`    | string       | Poetic meter name       |
| `meter_slug`    | string       | URL-friendly meter slug |
| `theme_name`    | string       | Primary theme name      |
| `theme_slug`    | string       | URL-friendly theme slug |
| `rhyme_pattern` | string       | Rhyme pattern (qafiyah) |
| `verses`        | list[string] | Individual verses       |
| `text`          | string       | Formatted full text     |

## License

MIT - See [LICENSE](../../LICENSE) for details.
