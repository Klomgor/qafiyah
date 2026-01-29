# Dataset Publisher

Publishes the Qafiyah poetry dataset to Hugging Face Hub.

## Setup

```bash
cd scripts/dataset-publisher
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

| Flag             | Description                                                    |
| ---------------- | -------------------------------------------------------------- |
| `--dry-run`      | Preview dataset without uploading                              |
| `--repo`         | Target repository (default: `qafiyah/classical-arabic-poetry`) |
| `--database-url` | PostgreSQL URL (default: `postgresql+psycopg2:///qafiyah`)     |
