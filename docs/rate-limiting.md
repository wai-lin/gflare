# Rate Limiting

KV-backed rate limiting middleware for Cloudflare Workers.

## Quick Start

```gleam
import gflare/router
import gflare/middleware/rate_limit

// Assume 'kv' is your KV namespace binding
let routes = router.new()
|> router.with_middleware(rate_limit.permissive(kv))
|> router.get("/api/data", get_data)

pub fn fetch(request, env, ctx) {
  let assert Ok(kv) = bindings.kv(env, "RATE_LIMIT")
  router.serve(routes, request, env, ctx)
}
```

## Configuration

```gleam
let config = rate_limit.RateLimitConfig(
  window_ms: 60_000,           // 1 minute window
  max_requests: 100,           // 100 requests per window
  key_fn: rate_limit.get_client_ip,  // Key by IP address
  message: "Too many requests",
)

let routes = router.new()
|> router.with_middleware(rate_limit.custom(config, kv))
```

## Presets

### Permissive

1000 requests per minute:

```gleam
rate_limit.permissive(kv)
// window_ms: 60_000
// max_requests: 1000
// key_fn: get_client_ip
```

### Strict

100 requests per minute:

```gleam
rate_limit.strict(kv)
// window_ms: 60_000
// max_requests: 100
// key_fn: get_client_ip
```

## How It Works

1. **Key extraction** — Client IP is extracted from `CF-Connecting-IP` or `X-Forwarded-For` header
2. **Counter storage** — Request count is stored in KV with TTL
3. **Limit check** — If count exceeds limit, returns 429
4. **Headers** — Response includes rate limit headers

## Headers

### Request Headers (added to responses)

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Maximum requests per window |
| `X-RateLimit-Remaining` | Requests remaining in window |

### Error Response (429)

| Header | Description |
|--------|-------------|
| `Retry-After` | Seconds until next request is allowed |

## Custom Key Function

By default, rate limiting uses the client IP address. You can customize this:

```gleam
let config = rate_limit.RateLimitConfig(
  window_ms: 60_000,
  max_requests: 100,
  key_fn: fn(req) {
    // Key by API key header
    let headers = request.headers(req)
    case list.find(headers, fn(h) { h.0 == "x-api-key" }) {
      Ok(#(_, key)) -> key
      Error(_) -> rate_limit.get_client_ip(req)
    }
  },
  message: "Too many requests",
)
```

## KV Setup

Rate limiting requires a KV namespace. Add to your `gleam.toml`:

```toml
[cloudflare.bindings]
kv = ["RATE_LIMIT"]
```

Then access in your handler:

```gleam
pub fn fetch(request, env, ctx) {
  let assert Ok(kv) = bindings.kv(env, "RATE_LIMIT")
  let routes = router.new()
  |> router.with_middleware(rate_limit.permissive(kv))
  router.serve(routes, request, env, ctx)
}
```

## Related

- [KV](kv.md) — key-value storage
- [Router](router.md) — middleware integration
