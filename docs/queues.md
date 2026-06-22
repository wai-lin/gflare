# Queues (Message Queue)

Queues let you send and process messages asynchronously. Use them for background jobs, email sending, or any task that can wait.

## Basic Usage

### Send a message

```gleam
import gflare/bindings
import gflare/queue
import gflare/error
import gflare/response
import gleam/json
import gleam/javascript/promise

pub fn enqueue_job(request, env, ctx) {
  case bindings.queue_producer(env, "EVENTS") {
    Error(e) -> {
      response.new(500)
      |> response.set_body(error.to_string(e))
      |> promise.resolve
    }
    Ok(queue) -> {
      // Create a JSON message
      let message = json.object([
        #("type", json.string("email")),
        #("to", json.string("user@example.com")),
        #("subject", json.string("Welcome!")),
      ])

      // Send the message
      use result <- promise.await(queue.send(queue, message))
      case result {
        Ok(Nil) -> {
          response.new(200)
          |> response.set_body("Job queued!")
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

### Send a batch of messages

```gleam
let messages = [
  json.object([#("type", json.string("email")), #("to", json.string("a@test.com"))]),
  json.object([#("type", json.string("email")), #("to", json.string("b@test.com"))]),
  json.object([#("type", json.string("email")), #("to", json.string("c@test.com"))]),
]

use result <- promise.await(queue.send_batch(q, messages))
case result {
  Ok(Nil) -> io.println("Sent " <> int.to_string(list.length(messages)) <> " messages")
  Error(e) -> io.println_error(error.to_string(e))
}
```

### Process messages (Consumer)

```gleam
pub fn queue(batch, env, ctx) {
  // batch.messages is a list of messages
  list.each(batch.messages, fn(msg) {
    // Get message metadata
    let id = queue.message_id(msg)
    let attempts = queue.message_attempts(msg)
    let body = queue.message_body(msg)

    io.println("Processing message " <> id <> " (attempt " <> int.to_string(attempts) <> ")")

    // Process the message
    case process_message(body) {
      Ok(_) -> {
        // Acknowledge — message is done
        let assert Ok(_) = queue.ack(msg)
      }
      Error(e) -> {
        // Retry — message will be redelivered later
        io.println_error("Failed: " <> error.to_string(e))
        let assert Ok(_) = queue.retry(msg)
      }
    }
  })

  // Return Nil to acknowledge all messages
  promise.resolve(Nil)
}

fn process_message(body) {
  // Your processing logic here
  Ok(Nil)
}
```

## Configuration

Add queue bindings to `gleam.toml`:

```toml
[cloudflare.bindings]
queues_producers = ["EVENTS"]  # For sending messages
queues_consumers = ["events"]  # For receiving messages
```

## Message Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `queue.send(q, message)` | `Promise(Result(Nil, Error))` | Send one message |
| `queue.send_batch(q, messages)` | `Promise(Result(Nil, Error))` | Send multiple messages |
| `queue.ack(msg)` | `Promise(Result(Nil, Error))` | Acknowledge message (done) |
| `queue.retry(msg)` | `Promise(Result(Nil, Error))` | Retry message later |
| `queue.message_id(msg)` | `String` | Get message ID |
| `queue.message_body(msg)` | `a` | Get message body (generic) |
| `queue.message_attempts(msg)` | `Int` | Get attempt count |
| `queue.message_timestamp(msg)` | `Int` | Get timestamp |

## Error Handling

```gleam
use result <- promise.await(queue.send(q, message))
case result {
  Ok(Nil) -> io.println("Sent!")
  Error(e) -> {
    // Common errors:
    // - QueueError("queue not found") — queue not in gleam.toml
    // - QueueError("payload too large") — message too big
    // - BindingNotFound("EVENTS") — binding not in gleam.toml
    io.println_error(error.to_string(e))
  }
}
```

## Related

- [Bindings](bindings.md) — how to get queue bindings
- [Configuration](configuration.md) — how to configure queue bindings
- [Error Handling](error-handling.md) — error handling patterns
