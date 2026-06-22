import gleeunit
import gleeunit/should

import gflare/middleware/cors
import gleam/list

pub fn main() {
  gleeunit.main()
}

// CorsConfig record tests

pub fn cors_config_has_correct_fields_test() {
  let config =
    cors.CorsConfig(
      allow_origins: ["*"],
      allow_methods: ["GET", "POST"],
      allow_headers: ["Content-Type"],
      expose_headers: [],
      allow_credentials: False,
      max_age: 86_400,
    )
  config.allow_origins |> should.equal(["*"])
  config.allow_methods |> should.equal(["GET", "POST"])
  config.allow_headers |> should.equal(["Content-Type"])
  config.expose_headers |> should.equal([])
  config.allow_credentials |> should.equal(False)
  config.max_age |> should.equal(86_400)
}

pub fn cors_config_with_credentials_test() {
  let config =
    cors.CorsConfig(
      allow_origins: ["https://example.com"],
      allow_methods: ["GET", "POST", "PUT", "DELETE"],
      allow_headers: ["Content-Type", "Authorization"],
      expose_headers: ["X-Request-Id"],
      allow_credentials: True,
      max_age: 3600,
    )
  config.allow_credentials |> should.equal(True)
  config.expose_headers |> should.equal(["X-Request-Id"])
}

pub fn permissive_config_test() {
  let config =
    cors.CorsConfig(
      allow_origins: ["*"],
      allow_methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
      allow_headers: ["Content-Type", "Authorization", "X-Requested-With"],
      expose_headers: [],
      allow_credentials: False,
      max_age: 86_400,
    )
  config.allow_origins |> should.equal(["*"])
  list.length(config.allow_methods) |> should.equal(6)
}

pub fn restrictive_config_test() {
  let config =
    cors.CorsConfig(
      allow_origins: ["https://example.com"],
      allow_methods: ["GET", "POST", "PUT", "DELETE"],
      allow_headers: ["Content-Type", "Authorization"],
      expose_headers: [],
      allow_credentials: False,
      max_age: 3600,
    )
  config.allow_origins |> should.equal(["https://example.com"])
  list.length(config.allow_methods) |> should.equal(4)
}
