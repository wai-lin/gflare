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

Bindings connect your code to Cloudflare services. Add them under `[cloudflare.bindings]`:

```toml
[cloudflare.bindings]
kv = ["CACHE", "SESSIONS"]           # Key-value namespaces
d1 = ["DB"]                          # D1 databases
r2 = ["ASSETS"]                      # R2 buckets
queues_producers = ["EVENTS"]        # Queue producers
queues_consumers = ["events"]        # Queue consumers
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
d1 = ["DB"]
r2 = ["ASSETS"]
queues_producers = ["EVENTS"]
queues_consumers = ["events"]

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
