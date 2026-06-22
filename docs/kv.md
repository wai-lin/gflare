# KV (Key-Value Storage)

KV is Cloudflare's global key-value store. Use it for caching, session storage, or any data that needs fast reads worldwide.

## Basic Usage

### Get a value

```gleam
import gflare/bindings
import gflare/kv
import gflare/error
import gflare/response
import gleam/javascript/promise

pub fn fetch(request, env, ctx) {
  // Get the KV binding
  case bindings.kv(env, "CACHE") {
    Error(e) -> {
      response.new(500)
      |> response.set_body(error.to_string(e))
      |> promise.resolve
    }
    Ok(cache) -> {
      // Get a value from KV
      use result <- promise.await(kv.get(cache, "greeting", kv.get_options()))
      case result {
        Ok(value) -> {
          // Key found
          response.new(200)
          |> response.set_body(value)
          |> promise.resolve
        }
        Error(_) -> {
          // Key not found
          response.new(404)
          |> response.set_body("Not found")
          |> promise.resolve
        }
      }
    }
  }
}
```

### Put a value

```gleam
// Put with default options
use result <- promise.await(kv.put(cache, "key", "value", kv.put_options()))
case result {
  Ok(Nil) -> io.println("Saved!")
  Error(e) -> io.println_error(error.to_string(e))
}

// Put with TTL (expires in 1 hour)
let opts = kv.put_options_with(
  expiration: None,
  expiration_ttl: Some(3600),
)
use result <- promise.await(kv.put(cache, "session:123", data, opts))
```

### Delete a key

```gleam
use result <- promise.await(kv.delete(cache, "old_key"))
case result {
  Ok(Nil) -> io.println("Deleted!")
  Error(e) -> io.println_error(error.to_string(e))
}
```

### List keys

```gleam
use result <- promise.await(kv.list(cache, kv.list_options()))
case result {
  Ok(list_result) -> {
    // list_result.keys: List(KvKey)
    // list_result.list_complete: Bool
    // list_result.cursor: Option(String) for pagination
    list.each(list_result.keys, fn(key) {
      io.println(key.name)
    })
  }
  Error(e) -> io.println_error(error.to_string(e))
}
```

## Configuration

Add KV bindings to `gleam.toml`:

```toml
[cloudflare.bindings]
kv = ["CACHE", "SESSIONS"]
```

Then access them in code:

```gleam
case bindings.kv(env, "CACHE") {
  Ok(cache) -> use_cache(cache)
  Error(e) -> handle_error(e)
}
```

## Options

### Get Options

```gleam
// Default: text type, no cache
kv.get_options()

// Custom: JSON type, 60 second cache
kv.get_options_with(type_: "json", cache_ttl: Some(60))
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type_` | `String` | `"text"` | Value type: `"text"`, `"json"`, `"arrayBuffer"` |
| `cache_ttl` | `Option(Int)` | `None` | Cache for N seconds |

### Put Options

```gleam
// Default: no expiration
kv.put_options()

// Custom: expires in 1 hour
kv.put_options_with(
  expiration: None,
  expiration_ttl: Some(3600),
)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `expiration` | `Option(Int)` | `None` | Unix timestamp for expiration |
| `expiration_ttl` | `Option(Int)` | `None` | Seconds until expiration |

## Error Handling

All KV operations return `Result(T, gflare/error.Error)`:

```gleam
use result <- promise.await(kv.get(cache, "key", kv.get_options()))
case result {
  Ok(value) -> handle_value(value)
  Error(e) -> {
    // Common errors:
    // - KvError("not found") — key doesn't exist
    // - KvError("type mismatch") — wrong type requested
    // - BindingNotFound("CACHE") — binding not in gleam.toml
    io.println_error(error.to_string(e))
  }
}
```

See [Error Handling](error-handling.md) for more patterns.

## Related

- [Bindings](bindings.md) — how to get KV bindings
- [Configuration](configuration.md) — how to configure KV bindings
- [Error Handling](error-handling.md) — error handling patterns
