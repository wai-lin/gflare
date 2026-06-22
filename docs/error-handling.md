# Error Handling

gflare uses Gleam's `Result` type for all error handling. No exceptions, no nulls.

## Core Pattern

Every operation that can fail returns `Result(T, Error)`. You must handle both cases:

```gleam
use result <- promise.await(kv.get(cache, "key", kv.get_options()))
case result {
  Ok(value) -> {
    // Success — use the value
    response.new(200) |> response.set_body(value) |> promise.resolve
  }
  Error(e) -> {
    // Failure — handle the error
    response.new(500) |> response.set_body(error.to_string(e)) |> promise.resolve
  }
}
```

## Pattern 1: Binding Lookup

Bindings can fail if the name doesn't match your `gleam.toml`:

```gleam
case bindings.kv(env, "CACHE") {
  Ok(cache) -> handle_request(cache)
  Error(e) -> {
    // e is BindingNotFound("CACHE")
    response.new(500)
    |> response.set_body("Missing binding: " <> error.to_string(e))
    |> promise.resolve
  }
}
```

## Pattern 2: Chaining Operations

Chain multiple async operations, handling each step:

```gleam
pub fn fetch(request, env, ctx) {
  // Step 1: Get binding
  case bindings.kv(env, "CACHE") {
    Error(e) -> respond_with_error(e)
    Ok(cache) -> {
      // Step 2: Get value
      use result <- promise.await(kv.get(cache, "users", kv.get_options()))
      case result {
        Ok(cached) -> {
          // Cache hit
          response.new(200) |> response.set_body(cached) |> promise.resolve
        }
        Error(_) -> {
          // Cache miss — query database
          case bindings.d1(env, "DB") {
            Error(e) -> respond_with_error(e)
            Ok(db) -> query_and_cache(db, cache)
          }
        }
      }
    }
  }
}
```

## Pattern 3: Sequential Operations

Use `use` for cleaner sequential async code:

```gleam
use user_result <- promise.await(get_user(db, user_id))
case user_result {
  Ok(user) -> {
    use save_result <- promise.await(save_to_cache(cache, user))
    case save_result {
      Ok(Nil) -> respond_with_user(user)
      Error(e) -> {
        // Cache save failed, but user exists
        io.println_error("Cache error: " <> error.to_string(e))
        respond_with_user(user)
      }
    }
  }
  Error(e) -> respond_with_error(e)
}
```

## Error Types

### gflare/error.Error

Used by KV, D1, R2, Queues, and Durable Objects:

```gleam
pub type Error {
  KvError(message: String)
  D1Error(message: String)
  R2Error(message: String)
  DurableObjectError(message: String)
  QueueError(message: String)
  BindingNotFound(name: String)
  EncodingError(message: String)
  DecodingError(message: String)
}
```

### gflare/turso/error.TursoError

Used by Turso operations:

```gleam
pub type TursoError {
  ApiError(message: String)
  NotFound(name: String)
  Conflict(name: String)
  NetworkError(message: String)
  DecodeError(message: String)
}
```

## Converting Errors to Strings

```gleam
import gflare/error

case result {
  Ok(value) -> handle_value(value)
  Error(e) -> {
    // Convert error to human-readable string
    let message = error.to_string(e)
    // message might be: "KV error: not found"
    io.println_error(message)
  }
}
```

For Turso errors:

```gleam
import gflare/turso/error as turso_err

case result {
  Ok(value) -> handle_value(value)
  Error(e) -> {
    let message = turso_err.to_string(e)
    // message might be: "Database not found: my-db"
    io.println_error(message)
  }
}
```

## When to Use `let assert`

Only use `let assert` when you're **certain** the operation can't fail:

```gleam
// OK: binding name is hardcoded and must exist in gleam.toml
let assert Ok(cache) = bindings.kv(env, "CACHE")

// BAD: user input might not exist as a key
let assert Ok(value) = kv.get(cache, user_input_key, kv.get_options())
// This will crash the worker if the key doesn't exist!
```

## Best Practices

1. **Always handle errors** — don't ignore `Error` cases
2. **Log errors** — use `io.println_error` for debugging
3. **Return meaningful messages** — users need to know what went wrong
4. **Use `let assert` sparingly** — only for guaranteed-to-succeed operations
5. **Chain operations carefully** — handle each step's errors

## Related

- [Bindings](bindings.md) — how binding errors occur
- [KV](kv.md), [D1](d1.md), [Turso](turso.md), [R2](r2.md), [Queues](queues.md), [Durable Objects](durable-objects.md) — service-specific error handling
