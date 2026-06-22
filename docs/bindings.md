# Bindings

Bindings connect your Gleam code to Cloudflare services. Each binding is resolved from the Worker's `env` object.

## How Bindings Work

When your worker receives a request, Cloudflare passes an `env` object containing all configured bindings. gflare provides typed functions to access them.

## Getting Bindings

```gleam
import gflare/bindings
import gflare/error
import gflare/response
import gleam/javascript/promise

pub fn fetch(request, env, ctx) {
  // Each binding returns Result(T, Error)
  case bindings.kv(env, "CACHE") {
    Ok(cache) -> {
      // Use the KV binding
      handle_request(cache)
    }
    Error(e) -> {
      // Binding not found in gleam.toml
      response.new(500)
      |> response.set_body(error.to_string(e))
      |> promise.resolve
    }
  }
}
```

## Available Bindings

| Binding | Function | Returns | Description |
|---------|----------|---------|-------------|
| KV | `bindings.kv(env, name)` | `Result(Kv, Error)` | Key-value storage |
| D1 | `bindings.d1(env, name)` | `Result(Database, Error)` | SQLite database |
| R2 | `bindings.r2(env, name)` | `Result(Bucket, Error)` | Object storage |
| DO | `bindings.durable_object(env, name)` | `Result(Namespace, Error)` | Durable Objects |
| Queue | `bindings.queue_producer(env, name)` | `Result(Queue, Error)` | Message queue |
| Var | `bindings.var(env, name)` | `Result(String, Error)` | Plain text variable |
| Secret | `bindings.secret(env, name)` | `Result(String, Error)` | Encrypted variable |

## Example: Multiple Bindings

```gleam
pub fn fetch(request, env, ctx) {
  // Get all bindings we need
  let cache_result = bindings.kv(env, "CACHE")
  let db_result = bindings.d1(env, "DB")
  let bucket_result = bindings.r2(env, "ASSETS")

  // Check each binding
  case cache_result, db_result, bucket_result {
    Ok(cache), Ok(db), Ok(bucket) -> {
      // All bindings available
      handle_request_with_all(cache, db, bucket)
    }
    Error(e), _, _ -> missing_binding_error("CACHE", e)
    _, Error(e), _ -> missing_binding_error("DB", e)
    _, _, Error(e) -> missing_binding_error("ASSETS", e)
  }
}

fn missing_binding_error(name, error) {
  response.new(500)
  |> response.set_body("Missing binding: " <> name)
  |> promise.resolve
}
```

## Configuration

Add bindings to your `gleam.toml`:

```toml
[cloudflare.bindings]
kv = ["CACHE", "SESSIONS"]
d1 = ["DB"]
r2 = ["ASSETS"]
queues_producers = ["EVENTS"]
queues_consumers = ["events"]
```

See [Configuration](configuration.md) for full details.

## Related

- [KV](kv.md) — key-value storage
- [D1](d1.md) — SQLite database
- [Turso](turso.md) — Turso database over HTTP
- [R2](r2.md) — object storage
- [Queues](queues.md) — message queues
- [Durable Objects](durable-objects.md) — stateful objects
- [Error Handling](error-handling.md) — handling binding errors
