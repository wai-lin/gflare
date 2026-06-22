import gflare/kv.{type Kv}
import gflare/request.{type HttpRequest}
import gflare/response
import gflare/router
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub type RateLimitConfig {
  RateLimitConfig(
    window_ms: Int,
    max_requests: Int,
    key_fn: fn(HttpRequest) -> String,
    message: String,
  )
}

pub type RateLimitResult {
  Allowed(remaining: Int)
  Denied(retry_after: Int)
}

// Middleware constructor

pub fn kv_middleware(
  config: RateLimitConfig,
  namespace: Kv,
) -> router.Middleware {
  router.Middleware(fn(req, env, ctx, next) {
    let key = config.key_fn(req)

    use result <- promise.await(check_rate_limit(config, namespace, key))
    case result {
      Allowed(remaining) -> {
        let router.Handler(handler_fn) = next
        use resp <- promise.await(handler_fn(
          req,
          env,
          ctx,
          router.RouteParams([]),
        ))

        // Add rate limit headers
        resp
        |> response.set_header(
          "X-RateLimit-Limit",
          int.to_string(config.max_requests),
        )
        |> response.set_header(
          "X-RateLimit-Remaining",
          int.to_string(remaining),
        )
        |> promise.resolve
      }
      Denied(retry_after) -> {
        response.new(429)
        |> response.set_header("Retry-After", int.to_string(retry_after))
        |> response.set_header("content-type", "application/json")
        |> response.set_body("{\"error\":\"" <> config.message <> "\"}")
        |> promise.resolve
      }
    }
  })
}

// Presets

pub fn permissive(namespace: Kv) -> router.Middleware {
  kv_middleware(
    RateLimitConfig(
      window_ms: 60_000,
      max_requests: 1000,
      key_fn: get_client_ip,
      message: "Too many requests",
    ),
    namespace,
  )
}

pub fn strict(namespace: Kv) -> router.Middleware {
  kv_middleware(
    RateLimitConfig(
      window_ms: 60_000,
      max_requests: 100,
      key_fn: get_client_ip,
      message: "Too many requests",
    ),
    namespace,
  )
}

pub fn custom(config: RateLimitConfig, namespace: Kv) -> router.Middleware {
  kv_middleware(config, namespace)
}

// Helpers

pub fn check_rate_limit(
  config: RateLimitConfig,
  namespace: Kv,
  key: String,
) -> Promise(RateLimitResult) {
  let cache_key = "ratelimit:" <> key

  // Get current count from KV
  use result <- promise.await(kv.get(namespace, cache_key, kv.get_options()))

  let count = case result {
    Ok(data) -> parse_count(data)
    Error(_) -> 0
  }

  // Check if under limit
  case count < config.max_requests {
    True -> {
      // Increment counter
      let new_count = count + 1
      let ttl = config.window_ms / 1000
      let opts =
        kv.put_options_with(expiration: None, expiration_ttl: Some(ttl))
      use _ <- promise.await(kv.put(
        namespace,
        cache_key,
        int.to_string(new_count),
        opts,
      ))
      promise.resolve(Allowed(config.max_requests - new_count))
    }
    False -> {
      let retry_after = config.window_ms / 1000
      promise.resolve(Denied(retry_after))
    }
  }
}

pub fn get_client_ip(request: HttpRequest) -> String {
  let headers = request.headers(request)
  case list.find(headers, fn(h) { h.0 == "cf-connecting-ip" }) {
    Ok(#(_, ip)) -> ip
    Error(_) -> {
      case list.find(headers, fn(h) { h.0 == "x-forwarded-for" }) {
        Ok(#(_, ip)) -> {
          // Take first IP from comma-separated list
          case string.split(ip, ",") {
            [first, ..] -> string.trim(first)
            _ -> ip
          }
        }
        Error(_) -> "unknown"
      }
    }
  }
}

// Internal functions

fn parse_count(data: String) -> Int {
  case int.parse(data) {
    Ok(n) -> n
    Error(_) -> 0
  }
}
