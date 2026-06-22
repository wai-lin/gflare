# CORS Middleware

Cross-Origin Resource Sharing (CORS) middleware for handling cross-origin requests.

## Quick Start

```gleam
import gflare/router
import gflare/middleware/cors

let routes = router.new()
|> router.with_middleware(cors.permissive())
|> router.get("/users", list_users)

pub fn fetch(request, env, ctx) {
  router.serve(routes, request, env, ctx)
}
```

## Configuration

```gleam
let config = cors.CorsConfig(
  allow_origins: ["https://example.com", "https://app.example.com"],
  allow_methods: ["GET", "POST", "PUT", "DELETE"],
  allow_headers: ["Content-Type", "Authorization"],
  expose_headers: ["X-Request-Id"],
  allow_credentials: True,
  max_age: 3600,
)

let routes = router.new()
|> router.with_middleware(cors.custom(config))
```

## Presets

### Permissive

Allows all origins, all methods:

```gleam
cors.permissive()
// allow_origins: ["*"]
// allow_methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
// allow_headers: ["Content-Type", "Authorization", "X-Requested-With"]
// allow_credentials: False
// max_age: 86400
```

### Restrictive

Allows specific origins:

```gleam
cors.restrictive(["https://example.com", "https://app.example.com"])
// allow_methods: ["GET", "POST", "PUT", "DELETE"]
// allow_headers: ["Content-Type", "Authorization"]
// allow_credentials: False
// max_age: 3600
```

## How It Works

1. **Preflight requests** (OPTIONS) are handled automatically
2. **CORS headers** are added to all responses
3. **Origin matching** checks if the request origin is in the allowed list
4. **Wildcards** (`*`) allow all origins

## Headers Set

| Header | Description |
|--------|-------------|
| `Access-Control-Allow-Origin` | Allowed origin |
| `Access-Control-Allow-Methods` | Allowed HTTP methods |
| `Access-Control-Allow-Headers` | Allowed request headers |
| `Access-Control-Expose-Headers` | Headers available to the browser |
| `Access-Control-Allow-Credentials` | Whether credentials are allowed |
| `Access-Control-Max-Age` | How long preflight response is cached |

## Related

- [Router](router.md) — middleware integration
- [Rate Limiting](rate-limiting.md) — another common middleware
