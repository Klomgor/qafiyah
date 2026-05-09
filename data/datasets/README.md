# Database Restore

## Requirements
- PostgreSQL ≥ 17 (required for dump format version 1.16)
- `pg_restore`

## Restore
```bash
dropdb --if-exists qafiyah && createdb qafiyah && \
pg_restore \
  -U qafiyah \
  -d qafiyah \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  ./0002_10_06_2025/qafiyah_public_20250610_1424.dump
```

## Expected Warning

```bash
ERROR: schema "public" already exists
```

## Verify

```bash
psql -U qafiyah -d qafiyah -c "\dt"
psql -U qafiyah -d qafiyah -c "SELECT count(*) FROM poems;"
```

