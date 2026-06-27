# Configuration

gflare uses your `gleam.toml` for both Gleam package settings and Cloudflare Worker configuration.

## Basic Configuration

Add a `[cloudflare]` section to your `gleam.toml`:

```toml
name = "my-worker"
version = "1.0.0"
target = "javascript"

[dependencies]
gflare = ">= 1.0.0 and < 2.0.0"

[cloudflare]
name = "my-worker"                    # Worker name (must be unique in your account)
compatibility_date = "2025-01-15"     # Cloudflare compatibility date
```

## Bindings

Bindings connect your code to Cloudflare services.

### KV, R2, Queues

Add these under `[cloudflare.bindings]`:

```toml
[cloudflare.bindings]
kv = ["CACHE", "SESSIONS"]           # Key-value namespaces
r2 = ["ASSETS"]                      # R2 buckets
queues_producers = ["EVENTS"]        # Queue producers
queues_consumers = ["events"]        # Queue consumers
```

### D1 Databases

D1 uses per-binding configuration via `[[cloudflare.d1]]`:

```toml
[[cloudflare.d1]]
binding = "DB"                        # Binding name (env.DB in your worker)
database_name = "my-database"         # Database name in Cloudflare
database_id = "your-uuid-here"       # Database ID from Cloudflare dashboard
migrations_dir = "./db/migrations"   # Path to migration SQL files
```

All fields except `binding` are optional. If omitted, gflare uses sensible defaults:
- `database_name`: `<worker-name>-<binding>` (lowercased)
- `database_id`: `YOUR_D1_DATABASE_ID` (placeholder)
- `migrations_dir`: not set

Multiple D1 databases:

```toml
[[cloudflare.d1]]
binding = "DB"
database_name = "main-db"
database_id = "abc-123"

[[cloudflare.d1]]
binding = "DB_REPLICA"
database_name = "replica-db"
database_id = "xyz-789"
```

Legacy format still works (no extra fields):

```toml
[cloudflare.bindings]
d1 = ["DB"]
```

## Environment Variables

Add plain-text or secret variables under `[cloudflare.vars]`:

```toml
[cloudflare.vars]
ENVIRONMENT = "production"
DEBUG = "true"
```

For secrets (encrypted at rest), use `wrangler secret put API_KEY` after deployment.

## Durable Objects

Configure Durable Object classes:

```toml
[cloudflare.durable_objects]
classes = [
  { name = "Counter", module = "my_worker/durable_objects/counter" },
]
```

## Full Example

```toml
name = "my-worker"
version = "1.0.0"
target = "javascript"

[dependencies]
gflare = ">= 1.0.0 and < 2.0.0"
gleam_json = ">= 3.0.0 and < 4.0.0"

[cloudflare]
name = "my-worker"
compatibility_date = "2025-01-15"

[cloudflare.bindings]
kv = ["CACHE", "SESSIONS"]
r2 = ["ASSETS"]
queues_producers = ["EVENTS"]
queues_consumers = ["events"]

[[cloudflare.d1]]
binding = "DB"
database_name = "my-worker-db"
database_id = "your-uuid-here"
migrations_dir = "./db/migrations"

[cloudflare.durable_objects]
classes = [
  { name = "Counter", module = "my_worker/durable_objects/counter" },
]

[cloudflare.vars]
ENVIRONMENT = "production"
```

## Related

- [Bindings](bindings.md) — how to use bindings in your code
- [Durable Objects](durable-objects.md) — working with Durable Objects
