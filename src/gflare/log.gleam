import gleam/json.{type Json}
import gleam/list
import gleam/string

pub type LogLevel {
  Debug
  Info
  Warning
  Err
}

pub type Environment {
  Development
  Production
}

pub type Logger {
  Logger(
    handler: fn(LogLevel, String, List(#(String, Json))) -> Nil,
    level: LogLevel,
    env: Environment,
    default_context: List(#(String, Json)),
  )
}

// FFI imports

@external(javascript, "../gflare_ffi_log.mjs", "console_log")
fn console_log(message: String) -> Nil

@external(javascript, "../gflare_ffi_log.mjs", "console_warn")
fn console_warn(message: String) -> Nil

@external(javascript, "../gflare_ffi_log.mjs", "console_error")
fn console_error(message: String) -> Nil

@external(javascript, "../gflare_ffi_log.mjs", "get_timestamp")
fn get_timestamp() -> String

// Logger constructors

pub fn console_logger(level: LogLevel, env: Environment) -> Logger {
  Logger(handler: console_handler(env), level:, env:, default_context: [])
}

pub fn custom_logger(
  handler: fn(LogLevel, String, List(#(String, Json))) -> Nil,
  level: LogLevel,
) -> Logger {
  Logger(handler:, level:, env: Production, default_context: [])
}

// Log functions

pub fn debug(
  logger: Logger,
  message: String,
  context: List(#(String, Json)),
) -> Nil {
  log_at_level(logger, Debug, message, context)
}

pub fn info(
  logger: Logger,
  message: String,
  context: List(#(String, Json)),
) -> Nil {
  log_at_level(logger, Info, message, context)
}

pub fn warning(
  logger: Logger,
  message: String,
  context: List(#(String, Json)),
) -> Nil {
  log_at_level(logger, Warning, message, context)
}

pub fn error(
  logger: Logger,
  message: String,
  context: List(#(String, Json)),
) -> Nil {
  log_at_level(logger, Err, message, context)
}

// Lazy evaluation variants (only build message if level is active)

pub fn debug_fn(
  logger: Logger,
  builder: fn() -> String,
  context: List(#(String, Json)),
) -> Nil {
  case should_log(logger, Debug) {
    True -> log_at_level(logger, Debug, builder(), context)
    False -> Nil
  }
}

pub fn info_fn(
  logger: Logger,
  builder: fn() -> String,
  context: List(#(String, Json)),
) -> Nil {
  case should_log(logger, Info) {
    True -> log_at_level(logger, Info, builder(), context)
    False -> Nil
  }
}

pub fn warning_fn(
  logger: Logger,
  builder: fn() -> String,
  context: List(#(String, Json)),
) -> Nil {
  case should_log(logger, Warning) {
    True -> log_at_level(logger, Warning, builder(), context)
    False -> Nil
  }
}

pub fn error_fn(
  logger: Logger,
  builder: fn() -> String,
  context: List(#(String, Json)),
) -> Nil {
  case should_log(logger, Err) {
    True -> log_at_level(logger, Err, builder(), context)
    False -> Nil
  }
}

// Logger modification

pub fn set_level(logger: Logger, level: LogLevel) -> Logger {
  Logger(..logger, level:)
}

pub fn with_context(logger: Logger, context: List(#(String, Json))) -> Logger {
  Logger(
    ..logger,
    default_context: list.append(logger.default_context, context),
  )
}

// Helpers

pub fn level_to_string(level: LogLevel) -> String {
  case level {
    Debug -> "debug"
    Info -> "info"
    Warning -> "warning"
    Err -> "error"
  }
}

pub fn level_from_string(level: String) -> Result(LogLevel, String) {
  case level {
    "debug" -> Ok(Debug)
    "info" -> Ok(Info)
    "warning" -> Ok(Warning)
    "error" -> Ok(Err)
    other -> Error("Unknown log level: " <> other)
  }
}

pub fn generate_request_id() -> String {
  do_generate_request_id()
}

// Internal functions

fn should_log(logger: Logger, level: LogLevel) -> Bool {
  let level_int = level_to_int(level)
  let min_int = level_to_int(logger.level)
  level_int >= min_int
}

fn log_at_level(
  logger: Logger,
  level: LogLevel,
  message: String,
  context: List(#(String, Json)),
) -> Nil {
  case should_log(logger, level) {
    True -> {
      let all_context = list.append(logger.default_context, context)
      logger.handler(level, message, all_context)
    }
    False -> Nil
  }
}

fn level_to_int(level: LogLevel) -> Int {
  case level {
    Debug -> 0
    Info -> 1
    Warning -> 2
    Err -> 3
  }
}

// Console handler with format switching based on environment

fn console_handler(
  env: Environment,
) -> fn(LogLevel, String, List(#(String, Json))) -> Nil {
  fn(level, message, context) {
    let timestamp = get_timestamp()
    case env {
      Development -> format_text_and_log(level, message, context, timestamp)
      Production -> format_json_and_log(level, message, context, timestamp)
    }
  }
}

fn format_text_and_log(
  level: LogLevel,
  message: String,
  context: List(#(String, Json)),
  timestamp: String,
) -> Nil {
  let level_str = string.uppercase(level_to_string(level))
  let context_str = case context {
    [] -> ""
    _ -> {
      let pairs =
        list.map(context, fn(kv) { kv.0 <> "=" <> json.to_string(kv.1) })
        |> list.intersperse(" ")
      " " <> string.join(pairs, " ")
    }
  }
  let log_line =
    "[" <> timestamp <> "] " <> level_str <> " " <> message <> context_str
  case level {
    Debug | Info -> console_log(log_line)
    Warning -> console_warn(log_line)
    Err -> console_error(log_line)
  }
}

fn format_json_and_log(
  level: LogLevel,
  message: String,
  context: List(#(String, Json)),
  timestamp: String,
) -> Nil {
  let context_json = case context {
    [] -> json.object([])
    _ -> json.object(context)
  }
  let log_entry =
    json.object([
      #("level", json.string(level_to_string(level))),
      #("message", json.string(message)),
      #("timestamp", json.string(timestamp)),
      #("context", context_json),
    ])
  let log_line = json.to_string(log_entry)
  case level {
    Debug | Info -> console_log(log_line)
    Warning -> console_warn(log_line)
    Err -> console_error(log_line)
  }
}

@external(javascript, "../gflare_ffi_log.mjs", "generate_request_id")
fn do_generate_request_id() -> String
