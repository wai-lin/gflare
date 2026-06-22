import gleeunit
import gleeunit/should

import gflare/middleware/rate_limit

pub fn main() {
  gleeunit.main()
}

// RateLimitConfig tests

pub fn rate_limit_config_has_correct_fields_test() {
  let config =
    rate_limit.RateLimitConfig(
      window_ms: 60_000,
      max_requests: 100,
      key_fn: rate_limit.get_client_ip,
      message: "Too many requests",
    )
  config.window_ms |> should.equal(60_000)
  config.max_requests |> should.equal(100)
  config.message |> should.equal("Too many requests")
}

pub fn rate_limit_config_custom_values_test() {
  let config =
    rate_limit.RateLimitConfig(
      window_ms: 30_000,
      max_requests: 50,
      key_fn: rate_limit.get_client_ip,
      message: "Rate limited",
    )
  config.window_ms |> should.equal(30_000)
  config.max_requests |> should.equal(50)
  config.message |> should.equal("Rate limited")
}

// RateLimitResult tests

pub fn allowed_result_test() {
  let result = rate_limit.Allowed(remaining: 50)
  case result {
    rate_limit.Allowed(remaining) -> remaining |> should.equal(50)
  }
}

pub fn denied_result_test() {
  let result = rate_limit.Denied(retry_after: 60)
  case result {
    rate_limit.Denied(retry_after) -> retry_after |> should.equal(60)
  }
}

pub fn allowed_result_with_zero_remaining_test() {
  let result = rate_limit.Allowed(remaining: 0)
  case result {
    rate_limit.Allowed(remaining) -> remaining |> should.equal(0)
  }
}
