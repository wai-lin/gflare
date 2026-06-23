# Logging & Middleware

gflare provides structured logging with dependency injection (DI) support. Use the default console logger, or plug in your own implementation for services like Sentry, Datadog, or Datadog.

## Quick Start

```gleam
import gflare/log
import gflare/middleware
import gflare/router

// Create logging middleware
let logger = log.console_logger(Info, Production)
let config = middleware.default_config()
let logging = middleware.with_logging(logger, config)

// Add to router
let routes = router.new()
|> router.with_middleware(logging)
|> router.get("/users", list_users)
```

## Logger

### Log Levels

```gleam
pub type LogLevel {
  Debug
  Info
  Warning
  Err
}
```

### Creating Loggers

**Console logger** (default):

```gleam
let logger = log.console_logger(Info, Production)
```

**Custom logger** (DI):

```gleam
let logger = log.custom_logger(fn(level, message, context) {
  // Your implementation
  send_to_sentry(level, message, context)
}, Info)
```

### Log Functions

```gleam
log.debug(logger, "Debug message", [#("key", json.string("value"))])
log.info(logger, "Info message", [#("key", json.int(42))])
log.warning(logger, "Warning message", [])
log.error(logger, "Error message", [#("error", json.string("details"))])
```

### Lazy Evaluation

Use `_fn` variants to avoid building messages when level is not active:

```gleam
// Only builds message if Debug level is active
log.debug_fn(logger, fn() { "Expensive: " <> to_string(complex_data) }, [])
```

### Logger Modification

```gleam
// Change log level
let logger = log.set_level(logger, Debug)

// Add default context to all logs
let logger = log.with_context(logger, [
  #("app", json.string("my-app")),
  #("env", json.string("production")),
])
```

## Console Logger Formats

### Production (JSON)

Outputs structured JSON for Cloudflare Logpush:

```json
{"level":"info","message":"GET /api/users 200 45.2ms","timestamp":"2025-01-15T10:30:00Z","context":{"request_id":"abc123","method":"GET","path":"/api/users","status":200,"duration_ms":45.2}}
```

### Development (Text)

Outputs human-readable text:

```
[2025-01-15T10:30:00Z] INFO GET /api/users 200 45.2ms request_id=abc123 method=GET path=/api/users status=200 duration_ms=45.2
```

## Custom Logger (DI)

Create your own logger by providing a handler function:

```gleam
import gflare/log
import gleam/json

// Sentry logger
fn sentry_logger(dsn: String) -> log.Logger {
  log.custom_logger(fn(level, message, context) {
    let payload = json.object([
      #("level", json.string(log.level_to_string(level))),
      #("message", json.string(message)),
      #("extra", json.object(context)),
    ])
    send_to_sentry(dsn, payload)
  }, Info)
}

// Datadog logger
fn datadog_logger(api_key: String) -> log.Logger {
  log.custom_logger(fn(level, message, context) {
    let payload = json.object([
      #("ddsource", json.string("gleam")),
      #("level", json.string(log.level_to_string(level))),
      #("message", json.string(message)),
      #("attributes", json.object(context)),
    ])
    send_to_datadog(api_key, payload)
  }, Info)
}

// Multi-destination logger (stack)
fn stack_logger() -> log.Logger {
  log.custom_logger(fn(level, message, context) {
    // Log to console
    let console_logger = log.console_logger(level, Production)
    log.info(console_logger, message, context)
    
    // Also send to external service
    send_to_external(level, message, context)
  }, Info)
}
```

## Middleware

### Configuration

```gleam
pub type MiddlewareConfig {
  MiddlewareConfig(
    log_request_body: Bool,      // default: False
    log_response_body: Bool,     // default: False
    log_headers: Bool,           // default: False
    exclude_paths: List(String), // default: ["/health", "/healthz", "/ready", "/readyz"]
  )
}
```

### Default Config

```gleam
let config = middleware.default_config()
// log_request_body: False
// log_response_body: False
// log_headers: False
// exclude_paths: ["/health", "/healthz", "/ready", "/readyz"]
```

### Custom Config

```gleam
let config = middleware.MiddlewareConfig(
  log_request_body: False,
  log_response_body: True,  // Log response bodies
  log_headers: True,        // Log request headers
  exclude_paths: ["/health", "/metrics"],
)
```

### Using Middleware

```gleam
import gflare/log
import gflare/middleware
import gflare/router

pub fn fetch(request, env, ctx) {
  let logger = log.console_logger(Info, Production)
  let config = middleware.default_config()
  let logging = middleware.with_logging(logger, config)

  let routes = router.new()
  |> router.with_middleware(logging)
  |> router.get("/users", list_users)

  router.serve(routes, request, env, ctx)
}
```

The middleware automatically:
1. Generates a unique request ID
2. Logs request start (method, path, headers if enabled)
3. Measures request duration
4. Logs request end (status, duration, response body if enabled)
5. Excludes configured paths (e.g., health checks)

### Manual Logging

For more control, use the manual logging functions:

```gleam
import gflare/log
import gflare/middleware

pub fn fetch(request, env, ctx) {
  let logger = log.console_logger(Info, Production)
  let request_id = log.generate_request_id()
  
  // Log request start
  middleware.log_request_start(logger, request, request_id, middleware.default_config())
  
  // Your handler code
  let result = handle_request(request, env, ctx)
  
  // Log request end
  middleware.log_request_end(logger, request, result.response, request_id, result.duration_ms, middleware.default_config())
  
  promise.resolve(result.response)
}
```

## Request ID

The middleware generates a unique request ID using `crypto.randomUUID()`. This ID is:
- Added to all log entries as `request_id`
- Returned in the response header as `X-Request-Id`

```gleam
// Generate manually
let request_id = log.generate_request_id()
// Returns: "550e8400-e29b-41d4-a716-446655440000"
```

## Related

- [Error Handling](error-handling.md) — error patterns
- [Configuration](configuration.md) — worker configuration
