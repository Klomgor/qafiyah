# Database Restoration Guide

This guide provides instructions for restoring the database dump into a local PostgreSQL instance.

## Prerequisites

The database dump was created using **PostgreSQL 16**. Verify your PostgreSQL version before proceeding:

```bash
pg_restore --version
```

If your version is lower than 16, update PostgreSQL to ensure compatibility.

## Restoration Steps

### 1. Create the Database

Create a new database named `qafiyah`:

```bash
createdb -U postgres qafiyah
```

### 2. Restore the Dump

Execute the following command to restore the database dump:

```bash
pg_restore \
  -U postgres \
  -d qafiyah \
  -F c \
  --no-owner \
  --no-acl \
  /path/to/qafiyah_public_YYYYMMDD_HHMM.dump
```

Replace `/path/to/qafiyah_public_YYYYMMDD_HHMM.dump` with the actual path to your dump file.

## Notes

- The warning `schema "public" already exists` can be safely ignored.
- Ensure the PostgreSQL service is running before executing these commands.
- If authentication issues occur, verify your PostgreSQL user permissions and connection settings.

## Verification

After restoration, verify the database contents:

```bash
psql -U postgres -d qafiyah -c "\dt"
```

This command lists all tables in the restored database.