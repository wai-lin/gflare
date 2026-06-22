# Router

gflare includes a radix tree-based router with middleware support, path parameters, and automatic error handling.

## Quick Start

```gleam
import gflare/router
import gflare/response
import gflare/json

// Define handlers
fn list_users(req, env, ctx, params) {
  let users = [#(1, "Alice"), #(2, "Bob")]
  response.ok(json.array(users, fn(user) {
    json.object([#("id", json.int(user.0)), #("name", json.string(user.1))])
  }))
  |> promise.resolve
}

fn get_user(req, env, ctx, params) {
  let id = router.get_param(params, "id")
  response.ok(json.object([#("id", json.string(id))]))
  |> promise.resolve
}

fn create_user(req, env, ctx, params) {
  response.created(json.object([#("message", json.string("Created"))]))
  |> promise.resolve
}

// Build router
let routes = router.new()
|> router.get("/users", list_users)
|> router.get("/users/:id", get_user)
|> router.post("/users", create_user)

// Entry point
pub fn fetch(request, env, ctx) {
  router.serve(routes, request, env, ctx)
}
```

## Route Methods

```gleam
router.get(router, path, handler)      // GET
router.post(router, path, handler)     // POST
router.put(router, path, handler)      // PUT
router.delete(router, path, handler)   // DELETE
router.patch(router, path, handler)    // PATCH
router.options(router, path, handler)  // OPTIONS
router.any(router, path, handler)      // All methods
```

## Path Parameters

Extract parameters from URL paths using `:param` syntax:

```gleam
let routes = router.new()
|> router.get("/users/:id", get_user)
|> router.get("/users/:user_id/posts/:post_id", get_user_post)

fn get_user(req, env, ctx, params) {
  let id = router.get_param(params, "id")
  // id = Some("123") for /users/123
  
  let name = router.get_param_or(params, "name", "anonymous")
  // name = "anonymous" if not present
  
  response.ok(json.string(id)) |> promise.resolve
}
```

## Wildcards

Catch-all routes using `*name` syntax:

```gleam
let routes = router.new()
|> router.get("/files/*path", serve_file)

fn serve_file(req, env, ctx, params) {
  let path = router.get_param(params, "path")
  // path = Some("images/logo.png") for /files/images/logo.png
  
  response.ok(json.string(path)) |> promise.resolve
}
```

## Middleware

Middleware executes in onion model: Global → Group → Route

```gleam
// Create middleware
let auth_middleware = router.Middleware(fn(req, env, ctx, next) {
  // Check authentication
  case check_auth(req) {
    Ok(user) -> {
      // User is authenticated, continue
      let router.Handler(handler_fn) = next
      handler_fn(req, env, ctx, router.RouteParams([]))
    }
    Error(_) -> response.unauthorized("Not authenticated") |> promise.resolve
  }
})

// Add global middleware
let routes = router.new()
|> router.with_middleware(auth_middleware)
|> router.get("/users", list_users)
```

## Route Groups

Group routes with shared prefix and middleware:

```gleam
let routes = router.new()
|> router.group("/api/v1", [auth_middleware], fn(r) {
  r
  |> router.get("/users", list_users)
  |> router.post("/users", create_user)
  |> router.get("/users/:id", get_user)
})
```

This creates routes:
- GET /api/v1/users
- POST /api/v1/users
- GET /api/v1/users/:id

All with the `auth_middleware` applied.

## Error Handling

### 404 Not Found

Customize the 404 handler:

```gleam
let routes = router.new()
|> router.not_found(fn(req, env, ctx, params) {
  response.not_found()
  |> response.set_body("{\"error\": \"Custom 404\"}")
  |> response.set_header("content-type", "application/json")
  |> promise.resolve
})
```

### 405 Method Not Allowed

When a path matches but method doesn't, router returns 405 with Allow header:

```gleam
// GET /users exists
// Request: POST /users
// Response: 405 with Allow: GET
```

### Error Handler

Catch unhandled errors from handlers:

```gleam
let routes = router.new()
|> router.on_error(fn(req, error) {
  // Log the error
  io.println_error("Handler error: " <> error)
  // Return generic error response
  response.internal_error("Internal server error")
})
```

## Response Helpers

gflare provides convenience functions for common responses:

```gleam
import gflare/response

// Success
response.ok(data)              // 200 + JSON
response.ok_text(body)         // 200 + text
response.created(data)         // 201 + JSON
response.accepted()            // 202
response.no_content()          // 204

// Errors
response.bad_request("msg")    // 400
response.unauthorized("msg")   // 401
response.forbidden("msg")      // 403
response.not_found()           // 404
response.method_not_allowed(["GET", "POST"]) // 405
response.conflict("msg")       // 409
response.internal_error("msg") // 500

// Content types
response.html(content)         // text/html
response.text(content)         // text/plain
response.xml(content)          // application/xml
```

## Complete Example

```gleam
import gflare/router
import gflare/response
import gflare/json
import gflare/request

// Middleware
let logger = router.Middleware(fn(req, env, ctx, next) {
  let method = request.method(request)
  let url = request.url(request)
  io.println(method <> " " <> url)
  
  let router.Handler(handler_fn) = next
  handler_fn(req, env, ctx, router.RouteParams([]))
})

let auth = router.Middleware(fn(req, env, ctx, next) {
  case check_auth(req) {
    Ok(_) -> {
      let router.Handler(handler_fn) = next
      handler_fn(req, env, ctx, router.RouteParams([]))
    }
    Error(_) -> response.unauthorized("Invalid token") |> promise.resolve
  }
})

// Handlers
fn list_users(req, env, ctx, params) {
  response.ok(json.string("users")) |> promise.resolve
}

fn get_user(req, env, ctx, params) {
  let id = router.get_param(params, "id")
  response.ok(json.string("User " <> id)) |> promise.resolve
}

// Routes
let routes = router.new()
|> router.with_middleware(logger)
|> router.group("/api/v1", [auth], fn(r) {
  r
  |> router.get("/users", list_users)
  |> router.get("/users/:id", get_user)
})
|> router.not_found(fn(req, env, ctx, params) {
  response.not_found() |> promise.resolve
})

// Entry point
pub fn fetch(request, env, ctx) {
  router.serve(routes, request, env, ctx)
}
```

## API Reference

### Router

```gleam
pub fn new() -> Router
pub fn get(router, path, handler) -> Router
pub fn post(router, path, handler) -> Router
pub fn put(router, path, handler) -> Router
pub fn delete(router, path, handler) -> Router
pub fn patch(router, path, handler) -> Router
pub fn options(router, path, handler) -> Router
pub fn any(router, path, handler) -> Router
pub fn group(router, prefix, middleware, configure) -> Router
pub fn with_middleware(router, middleware) -> Router
pub fn not_found(router, handler) -> Router
pub fn on_error(router, handler) -> Router
pub fn serve(router, request, env, ctx) -> Promise(Response)
```

### RouteParams

```gleam
pub fn get_param(params, name) -> Option(String)
pub fn get_param_or(params, name, default) -> String
```

### Types

```gleam
pub type Handler {
  Handler(fn(HttpRequest, Env, Context, RouteParams) -> Promise(Response))
}

pub type Middleware {
  Middleware(fn(HttpRequest, Env, Context, Handler) -> Promise(Response))
}

pub type RouteParams {
  RouteParams(params: List(#(String, String)))
}
```

## Related

- [Response Helpers](response.md) — response functions
- [Logging](logging.md) — request/response logging middleware
- [Error Handling](error-handling.md) — error patterns
