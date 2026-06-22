import gleeunit
import gleeunit/should

import gflare/log
import gflare/middleware
import gleam/json
import gleam/list
import gleam/string

pub fn main() {
  gleeunit.main()
}

// Logger creation tests

pub fn console_logger_creates_logger_test() {
  let logger = log.console_logger(log.Info, log.Production)
  logger.level |> should.equal(log.Info)
  logger.env |> should.equal(log.Production)
}

pub fn console_logger_development_test() {
  let logger = log.console_logger(log.Debug, log.Development)
  logger.env |> should.equal(log.Development)
}

pub fn custom_logger_creates_logger_test() {
  let logger =
    log.custom_logger(fn(_level, _message, _context) { Nil }, log.Debug)
  logger.level |> should.equal(log.Debug)
}

// Log level tests

pub fn level_to_string_debug_test() {
  log.level_to_string(log.Debug) |> should.equal("debug")
}

pub fn level_to_string_info_test() {
  log.level_to_string(log.Info) |> should.equal("info")
}

pub fn level_to_string_warning_test() {
  log.level_to_string(log.Warning) |> should.equal("warning")
}

pub fn level_to_string_error_test() {
  log.level_to_string(log.Err) |> should.equal("error")
}

pub fn level_from_string_debug_test() {
  log.level_from_string("debug") |> should.be_ok
}

pub fn level_from_string_info_test() {
  log.level_from_string("info") |> should.be_ok
}

pub fn level_from_string_warning_test() {
  log.level_from_string("warning") |> should.be_ok
}

pub fn level_from_string_error_test() {
  log.level_from_string("error") |> should.be_ok
}

pub fn level_from_string_invalid_test() {
  log.level_from_string("invalid") |> should.be_error
}

// Log functions don't crash tests

pub fn debug_does_not_crash_test() {
  let logger = log.console_logger(log.Debug, log.Production)
  log.debug(logger, "test message", [])
  True |> should.equal(True)
}

pub fn info_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Production)
  log.info(logger, "test message", [])
  True |> should.equal(True)
}

pub fn warning_does_not_crash_test() {
  let logger = log.console_logger(log.Warning, log.Production)
  log.warning(logger, "test message", [])
  True |> should.equal(True)
}

pub fn error_does_not_crash_test() {
  let logger = log.console_logger(log.Err, log.Production)
  log.error(logger, "test message", [])
  True |> should.equal(True)
}

// Context tests

pub fn info_with_context_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Production)
  log.info(logger, "test", [#("key", json.string("value"))])
  True |> should.equal(True)
}

pub fn info_with_empty_context_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Production)
  log.info(logger, "test", [])
  True |> should.equal(True)
}

pub fn info_with_multiple_context_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Production)
  log.info(logger, "test", [
    #("key1", json.string("value1")),
    #("key2", json.int(42)),
    #("key3", json.bool(True)),
  ])
  True |> should.equal(True)
}

// Logger modification tests

pub fn set_level_changes_level_test() {
  let logger = log.console_logger(log.Info, log.Production)
  let logger = log.set_level(logger, log.Debug)
  logger.level |> should.equal(log.Debug)
}

pub fn set_level_to_warning_test() {
  let logger = log.console_logger(log.Info, log.Production)
  let logger = log.set_level(logger, log.Warning)
  logger.level |> should.equal(log.Warning)
}

pub fn with_context_adds_context_test() {
  let logger = log.console_logger(log.Info, log.Production)
  let logger = log.with_context(logger, [#("app", json.string("test"))])
  list.length(logger.default_context) |> should.equal(1)
}

pub fn with_context_multiple_calls_test() {
  let logger = log.console_logger(log.Info, log.Production)
  let logger = log.with_context(logger, [#("app", json.string("test"))])
  let logger = log.with_context(logger, [#("env", json.string("prod"))])
  list.length(logger.default_context) |> should.equal(2)
}

// Lazy evaluation tests

pub fn debug_fn_does_not_crash_test() {
  let logger = log.console_logger(log.Debug, log.Production)
  log.debug_fn(logger, fn() { "computed message" }, [])
  True |> should.equal(True)
}

pub fn info_fn_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Production)
  log.info_fn(logger, fn() { "computed message" }, [])
  True |> should.equal(True)
}

pub fn warning_fn_does_not_crash_test() {
  let logger = log.console_logger(log.Warning, log.Production)
  log.warning_fn(logger, fn() { "computed message" }, [])
  True |> should.equal(True)
}

pub fn error_fn_does_not_crash_test() {
  let logger = log.console_logger(log.Err, log.Production)
  log.error_fn(logger, fn() { "computed message" }, [])
  True |> should.equal(True)
}

// Request ID tests

pub fn generate_request_id_returns_string_test() {
  let id = log.generate_request_id()
  let is_long = string.length(id) > 0
  is_long |> should.equal(True)
}

pub fn generate_request_id_is_not_empty_test() {
  let id = log.generate_request_id()
  id |> should.not_equal("")
}

pub fn generate_request_id_returns_unique_values_test() {
  let id1 = log.generate_request_id()
  let id2 = log.generate_request_id()
  id1 |> should.not_equal(id2)
}

// Middleware config tests

pub fn default_config_has_correct_defaults_test() {
  let config = middleware.default_config()
  config.log_request_body |> should.equal(False)
  config.log_response_body |> should.equal(False)
  config.log_headers |> should.equal(False)
}

pub fn default_config_has_health_paths_test() {
  let config = middleware.default_config()
  list.contains(config.exclude_paths, "/health") |> should.equal(True)
  list.contains(config.exclude_paths, "/healthz") |> should.equal(True)
  list.contains(config.exclude_paths, "/ready") |> should.equal(True)
  list.contains(config.exclude_paths, "/readyz") |> should.equal(True)
}

// Custom middleware config tests

pub fn custom_config_test() {
  let config =
    middleware.MiddlewareConfig(
      log_request_body: True,
      log_response_body: True,
      log_headers: True,
      exclude_paths: ["/api/internal"],
    )
  config.log_request_body |> should.equal(True)
  config.log_response_body |> should.equal(True)
  config.log_headers |> should.equal(True)
  config.exclude_paths |> should.equal(["/api/internal"])
}

// Production format tests (JSON)

pub fn production_logger_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Production)
  log.info(logger, "production test", [#("env", json.string("prod"))])
  True |> should.equal(True)
}

// Development format tests (text)

pub fn development_logger_does_not_crash_test() {
  let logger = log.console_logger(log.Info, log.Development)
  log.info(logger, "development test", [#("env", json.string("dev"))])
  True |> should.equal(True)
}
