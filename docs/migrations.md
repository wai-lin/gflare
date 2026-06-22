# Migrations

gflare provides database migrations for both D1 and Turso. Migrations are versioned SQL files that apply in order.

## Create a Migration

```bash
gleam run -m gflare -- db migrate create create_users_table
```

This creates `db/migrations/0001_create_users_table.sql`:

```sql
-- Migration: create_users_table
-- Created at: 2025-01-15T10:30:00Z

-- Write your SQL here
```

Edit the file with your schema:

```sql
-- Migration: create_users_table
-- Created at: 2025-01-15T10:30:00Z

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);
```

## List Migrations

```bash
gleam run -m gflare -- db migrate list
```

Output:

```
Migration files:
  0001_create_users_table.sql
  0002_add_email_index.sql
  0003_create_posts.sql
```

## Apply Migrations

### Turso

```bash
# Set environment variables
export TURSO_DATABASE_URL=lib://my-db.turso.io
export TURSO_AUTH_TOKEN=eyJ...

# Apply pending migrations
gleam run -m gflare -- db migrate run --turso
```

### D1

D1 migrations require wrangler:

```bash
gleam run -m gflare -- db migrate run
# Follow the wrangler prompts
```

## Migration Files

Migrations are numbered sequentially:

```
db/migrations/
  0001_create_users_table.sql
  0002_add_email_index.sql
  0003_create_posts.sql
```

Each file:
- Starts with a version number (0001, 0002, etc.)
- Has a descriptive name
- Contains valid SQL
- Comments (lines starting with `--`) are stripped before execution

## Programmatic Migrations

Apply migrations from your Gleam code:

```gleam
import gflare/migrate
import gflare/turso

pub fn setup_database(url, token) {
  let config = turso.connect(url, token)

  // Apply all pending migrations
  use result <- promise.await(migrate.run_turso(config, "db/migrations"))
  case result {
    Ok(Nil) -> io.println("Migrations applied!")
    Error(e) -> io.println_error("Migration failed: " <> e)
  }
}
```

## Multi-Tenant Migrations

Create new tenant databases and apply migrations automatically:

```gleam
import gflare/migrate
import gflare/turso
import gflare/turso/cloud

pub fn create_tenant(api, tenant_id) {
  // Create database
  use result <- promise.await(cloud.create_database(api, tenant_id, "default"))
  case result {
    Ok(db) -> {
      // Generate auth token
      use token_result <- promise.await(
        cloud.create_token(api, tenant_id, "10y", "full-access"),
      )
      case token_result {
        Ok(token) -> {
          // Connect and apply migrations
          let config = turso.connect("lib://" <> db.hostname, token.jwt)
          use _ <- promise.await(migrate.run_turso(config, "db/migrations"))
          promise.resolve(Ok(Nil))
        }
        Error(e) -> promise.resolve(Error(e))
      }
    }
    Error(e) -> promise.resolve(Error(e))
  }
}
```

## Tracking Table

gflare creates a `_gflare_migrations` table automatically to track applied migrations:

```sql
CREATE TABLE IF NOT EXISTS _gflare_migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  applied_at TEXT DEFAULT (datetime('now'))
);
```

## Related

- [D1](d1.md) — D1 database usage
- [Turso](turso.md) — Turso database usage
- [Code Generation](code-generation.md) — generate typed functions from SQL
