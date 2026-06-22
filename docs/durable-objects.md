# Durable Objects

Durable Objects are stateful, single-instance objects that handle requests. Use them for chat rooms, game sessions, collaborative editing, or any feature requiring persistent state.

## Basic Usage

### Get a stub (proxy to DO instance)

```gleam
import gflare/bindings
import gflare/durable_object
import gflare/error
import gflare/response
import gleam/json
import gleam/javascript/promise

pub fn fetch(request, env, ctx) {
  case bindings.durable_object(env, "COUNTER") {
    Error(e) -> {
      response.new(500)
      |> response.set_body(error.to_string(e))
      |> promise.resolve
    }
    Ok(ns) -> {
      // Get a deterministic ID from a name
      let id = durable_object.id_from_name(ns, "user:42")

      // Get a stub (proxy to the DO instance)
      let stub = durable_object.get_stub(ns, id)

      // Call the DO
      use result <- promise.await(durable_object.get(stub))
      case result {
        Ok(data) -> {
          response.new(200)
          |> response.json(data)
          |> promise.resolve
        }
        Error(e) -> {
          response.new(500)
          |> response.set_body(error.to_string(e))
          |> promise.resolve
        }
      }
    }
  }
}
```

### Set a value

```gleam
use result <- promise.await(durable_object.set(stub, "count", json.int(1)))
case result {
  Ok(Nil) -> io.println("Saved!")
  Error(e) -> io.println_error(error.to_string(e))
}
```

### Delete a value

```gleam
use result <- promise.await(durable_object.delete_key(stub, "old_key"))
case result {
  Ok(Nil) -> io.println("Deleted!")
  Error(e) -> io.println_error(error.to_string(e))
}
```

### Work with alarms

```gleam
// Set alarm 60 seconds from now
let timestamp = 1_700_000_000_000 + 60_000
use result <- promise.await(durable_object.set_alarm(stub, timestamp))

// Get alarm
use result <- promise.await(durable_object.get_alarm(stub))
case result {
  Ok(Some(timestamp)) -> {
    io.println("Alarm set for: " <> int.to_string(timestamp))
  }
  Ok(None) -> io.println("No alarm set")
  Error(e) -> io.println_error(error.to_string(e))
}
```

### Custom fetch

```gleam
let opts = durable_object.fetch_options_with(
  method: "POST",
  body: Some(json.object([#("action", json.string("increment"))])),
)
use result <- promise.await(durable_object.fetch(stub, "/api/increment", opts))
case result {
  Ok(data) -> handle_response(data)
  Error(e) -> handle_error(e)
}
```

## Configuration

Add Durable Object classes to `gleam.toml`:

```toml
[cloudflare.durable_objects]
classes = [
  { name = "Counter", module = "my_worker/durable_objects/counter" },
]
```

## Available Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `id_from_name(ns, name)` | `Id` | Get deterministic ID from string |
| `id_from_string(ns, id)` | `Id` | Get ID from existing ID string |
| `get_stub(ns, id)` | `Stub` | Get stub (proxy) for DO instance |
| `fetch(stub, path, opts)` | `Promise(Result(Dynamic, Error))` | Call DO's fetch handler |
| `get(stub)` | `Promise(Result(Dynamic, Error))` | Get all storage values |
| `set(stub, key, value)` | `Promise(Result(Nil, Error))` | Set a storage value |
| `delete_key(stub, key)` | `Promise(Result(Nil, Error))` | Delete a storage value |
| `get_alarm(stub)` | `Promise(Result(Option(Int), Error))` | Get alarm timestamp |
| `set_alarm(stub, timestamp)` | `Promise(Result(Nil, Error))` | Set alarm |
| `delete_alarm(stub)` | `Promise(Result(Nil, Error))` | Delete alarm |

## Error Handling

```gleam
use result <- promise.await(durable_object.get(stub))
case result {
  Ok(data) -> handle_data(data)
  Error(e) -> {
    // Common errors:
    // - DurableObjectError("does not exist") — DO not initialized
    // - DurableObjectError("timeout") — DO took too long
    // - BindingNotFound("COUNTER") — binding not in gleam.toml
    io.println_error(error.to_string(e))
  }
}
```

## Related

- [Bindings](bindings.md) — how to get DO bindings
- [Configuration](configuration.md) — how to configure DO bindings
- [Error Handling](error-handling.md) — error handling patterns
