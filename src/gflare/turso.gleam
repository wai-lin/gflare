import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/result
import gflare/error.{type Error, EncodingError}
import gflare/turso/config
import gflare/turso/types.{type BatchMode, type ExecuteResult, type Value, Blob, Float, Integer, Null, Text}

pub type Config =
  config.Config

pub fn connect(url: String, auth_token: String) -> Config {
  config.connect(url, auth_token)
}

pub fn text(value: String) -> Value {
  Text(value)
}

pub fn int(value: Int) -> Value {
  Integer(value)
}

pub fn float(value: Float) -> Value {
  Float(value)
}

pub fn blob(value: BitArray) -> Value {
  Blob(value)
}

pub fn null_value() -> Value {
  Null
}

@external(javascript, "../gflare_ffi_turso.mjs", "turso_execute")
fn do_execute(
  config: Config,
  sql: String,
  args: List(Value),
) -> Promise(Dynamic)

@external(javascript, "../gflare_ffi_turso.mjs", "turso_batch")
fn do_batch(
  config: Config,
  statements: List(#(String, List(Value))),
  mode: BatchMode,
) -> Promise(Dynamic)

@external(javascript, "../gflare_ffi_turso.mjs", "turso_transaction")
fn do_transaction(
  config: Config,
  statements: List(#(String, List(Value))),
) -> Promise(Dynamic)

pub fn execute(
  config: Config,
  sql: String,
  args: List(Value),
) -> Promise(Result(ExecuteResult, Error)) {
  use dynamic_result <- promise.await(do_execute(config, sql, args))
  case decode_execute_result(dynamic_result) {
    Ok(r) -> promise.resolve(Ok(r))
    Error(msg) -> promise.resolve(Error(EncodingError(msg)))
  }
}

pub fn batch(
  config: Config,
  statements: List(#(String, List(Value))),
  mode: BatchMode,
) -> Promise(Result(List(ExecuteResult), Error)) {
  use dynamic_result <- promise.await(do_batch(config, statements, mode))
  case decode_list_of_execute_results(dynamic_result) {
    Ok(r) -> promise.resolve(Ok(r))
    Error(msg) -> promise.resolve(Error(EncodingError(msg)))
  }
}

pub fn transaction(
  config: Config,
  statements: List(#(String, List(Value))),
) -> Promise(Result(List(ExecuteResult), Error)) {
  use dynamic_result <- promise.await(do_transaction(config, statements))
  case decode_list_of_execute_results(dynamic_result) {
    Ok(r) -> promise.resolve(Ok(r))
    Error(msg) -> promise.resolve(Error(EncodingError(msg)))
  }
}

fn decode_execute_result(data: Dynamic) -> Result(ExecuteResult, String) {
  let decoder = {
    use rows <- decode.field("0", decode.list(decode_row_decoder()))
    use columns <- decode.field("1", decode.list(decode.string))
    use rows_affected <- decode.field("2", decode.int)
    use last_insert_rowid <- decode.field("3", decode.optional(decode.int))
    decode.success(types.ExecuteResult(rows:, columns:, rows_affected:, last_insert_rowid:))
  }
  decode.run(data, decoder)
  |> result.map_error(fn(_) { "Failed to decode ExecuteResult" })
}

fn decode_list_of_execute_results(
  data: Dynamic,
) -> Result(List(ExecuteResult), String) {
  decode.run(data, decode.list(decode_execute_result_decoder()))
  |> result.map_error(fn(_) { "Failed to decode list of ExecuteResults" })
}

fn decode_execute_result_decoder() {
  use rows <- decode.field("0", decode.list(decode_row_decoder()))
  use columns <- decode.field("1", decode.list(decode.string))
  use rows_affected <- decode.field("2", decode.int)
  use last_insert_rowid <- decode.field("3", decode.optional(decode.int))
  decode.success(types.ExecuteResult(rows:, columns:, rows_affected:, last_insert_rowid:))
}

fn decode_row_decoder() {
  use columns <- decode.field("0", decode.list(decode.string))
  use values <- decode.field("1", decode.list(decode_value_decoder()))
  decode.success(types.Row(columns:, values:))
}

fn decode_value_decoder() {
  use constructor <- decode.field("constructor", decode.dynamic)
  let tag =
    decode.run(
      constructor,
      decode.field("name", decode.string, fn(name) { decode.success(name) }),
    )
    |> result.unwrap("Null")
  case tag {
    "Text" -> {
      use v <- decode.field("0", decode.string)
      decode.success(Text(v))
    }
    "Integer" -> {
      use v <- decode.field("0", decode.int)
      decode.success(Integer(v))
    }
    "Float" -> {
      use v <- decode.field("0", decode.float)
      decode.success(Float(v))
    }
    "Blob" -> decode.success(Blob(<<>>))
    _ -> decode.success(Null)
  }
}
