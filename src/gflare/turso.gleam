import gflare/turso/config
import gflare/turso/error.{type TursoError, DecodeError, NetworkError}
import gflare/turso/types.{
  type BatchMode, type ExecuteResult, type Value, Blob, Date, Float, Integer,
  JsonString, Null, Read, Text, Time, Timestamp, Uuid, Write,
}
import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

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

pub fn date(value: String) -> Value {
  Date(value)
}

pub fn time(value: String) -> Value {
  Time(value)
}

pub fn timestamp(value: String) -> Value {
  Timestamp(value)
}

pub fn uuid(value: String) -> Value {
  Uuid(value)
}

pub fn json_string(value: String) -> Value {
  JsonString(value)
}

pub fn execute(
  config: Config,
  sql: String,
  args: List(Value),
) -> Promise(Result(ExecuteResult, TursoError)) {
  let url = config.url <> "/v2/pipeline"
  let body = encode_pipeline(sql, args)
  make_request(config, url, body, decode_pipeline_response)
}

pub fn batch(
  config: Config,
  statements: List(#(String, List(Value))),
  mode: BatchMode,
) -> Promise(Result(List(ExecuteResult), TursoError)) {
  let url = config.url <> "/v2/pipeline"
  let body = encode_batch_pipeline(statements, Some(mode))
  make_request(config, url, body, decode_batch_response)
}

pub fn transaction(
  config: Config,
  statements: List(#(String, List(Value))),
) -> Promise(Result(List(ExecuteResult), TursoError)) {
  let url = config.url <> "/v2/pipeline"
  let body = encode_batch_pipeline(statements, None)
  make_request(config, url, body, decode_batch_response)
}

fn make_request(
  config: Config,
  url: String,
  body: String,
  parser: fn(String) -> Result(a, String),
) -> Promise(Result(a, TursoError)) {
  case request.to(url) {
    Error(_) ->
      promise.resolve(Error(NetworkError("Invalid URL: " <> url)))
    Ok(req) -> {
      let req =
        req
        |> request.set_header("Authorization", "Bearer " <> config.auth_token)
        |> request.set_header("Content-Type", "application/json")
      let req = request.set_body(req, body)
      use fetch_result <- promise.await(fetch.send(req))
      case fetch_result {
        Ok(resp) -> {
          use text_result <- promise.await(fetch.read_text_body(resp))
          case text_result {
            Ok(text_resp) -> {
              case parser(text_resp.body) {
                Ok(value) -> promise.resolve(Ok(value))
                Error(msg) -> promise.resolve(Error(DecodeError(msg)))
              }
            }
            Error(_) ->
              promise.resolve(Error(NetworkError("Failed to read response")))
          }
        }
        Error(_) ->
          promise.resolve(Error(NetworkError("Failed to send request")))
      }
    }
  }
}

fn encode_value(value: Value) -> json.Json {
  case value {
    Text(s) ->
      json.object([#("type", json.string("text")), #("value", json.string(s))])
    Integer(i) ->
      json.object([#("type", json.string("integer")), #("value", json.int(i))])
    Float(f) ->
      json.object([#("type", json.string("float")), #("value", json.float(f))])
    Blob(bits) ->
      json.object([
        #("type", json.string("blob")),
        #("base64", json.string(bit_array.base64_encode(bits, True))),
      ])
    Null -> json.object([#("type", json.string("null"))])
    Date(s) ->
      json.object([#("type", json.string("text")), #("value", json.string(s))])
    Time(s) ->
      json.object([#("type", json.string("text")), #("value", json.string(s))])
    Timestamp(s) ->
      json.object([#("type", json.string("text")), #("value", json.string(s))])
    Uuid(s) ->
      json.object([#("type", json.string("text")), #("value", json.string(s))])
    JsonString(s) ->
      json.object([#("type", json.string("text")), #("value", json.string(s))])
  }
}

fn encode_pipeline(sql: String, args: List(Value)) -> String {
  let args_json = json.array(args, encode_value)
  let stmt = json.object([#("sql", json.string(sql)), #("args", args_json)])
  let execute =
    json.object([#("type", json.string("execute")), #("stmt", stmt)])
  let close = json.object([#("type", json.string("close"))])
  json.to_string(
    json.object([#("requests", json.array([execute, close], fn(x) { x }))]),
  )
}

fn encode_batch_pipeline(
  statements: List(#(String, List(Value))),
  mode: Option(BatchMode),
) -> String {
  let requests =
    list.map(statements, fn(stmt) {
      let #(sql, args) = stmt
      let args_json = json.array(args, encode_value)
      json.object([
        #("type", json.string("execute")),
        #(
          "stmt",
          json.object([#("sql", json.string(sql)), #("args", args_json)]),
        ),
      ])
    })
  let close = json.object([#("type", json.string("close"))])
  let requests_json = json.array(list.append(requests, [close]), fn(x) { x })
  case mode {
    Some(batch_mode) ->
      json.to_string(
        json.object([
          #("requests", requests_json),
          #(
            "batch",
            json.object([
              #("type", json.string(batch_mode_to_string(batch_mode))),
            ]),
          ),
        ]),
      )
    None -> json.to_string(json.object([#("requests", requests_json)]))
  }
}

fn batch_mode_to_string(mode: BatchMode) -> String {
  case mode {
    Read -> "read"
    Write -> "write"
  }
}

fn decode_pipeline_response(body: String) -> Result(ExecuteResult, String) {
  use data <- result.try(parse_json(body))
  use results <- result.try(get_field(data, "results"))
  use items <- result.try(get_list(results))
  case items {
    [] -> Error("No results in response")
    [first, ..] -> decode_single_result(first)
  }
}

fn decode_batch_response(body: String) -> Result(List(ExecuteResult), String) {
  use data <- result.try(parse_json(body))
  use results <- result.try(get_field(data, "results"))
  use items <- result.try(get_list(results))
  let decoded =
    list.filter_map(items, fn(item) {
      case get_field(item, "type") {
        Ok(type_val) -> {
          case decode.run(type_val, decode.string) {
            Ok("execute") -> decode_single_result(item)
            _ -> Error("Not an execute result")
          }
        }
        Error(_) -> Error("No type field")
      }
    })
  Ok(decoded)
}

fn decode_single_result(data: Dynamic) -> Result(ExecuteResult, String) {
  use response <- result.try(get_field(data, "response"))
  use result_data <- result.try(get_field(response, "result"))
  use cols_data <- result.try(get_field(result_data, "cols"))
  use cols_items <- result.try(get_list(cols_data))
  let cols =
    list.map(cols_items, fn(col) {
      case get_string(col, "name") {
        Ok(name) -> name
        Error(_) -> ""
      }
    })
  use rows_data <- result.try(get_field(result_data, "rows"))
  use rows_items <- result.try(get_list_of_lists(rows_data))
  let rows = list.map(rows_items, fn(row) { decode_row(cols, row) })
  use affected <- result.try(get_int(result_data, "affected_row_count"))
  let last_id = case get_int(result_data, "last_insert_rowid") {
    Ok(id) -> Some(id)
    Error(_) -> None
  }
  Ok(types.ExecuteResult(
    rows:,
    columns: cols,
    rows_affected: affected,
    last_insert_rowid: last_id,
  ))
}

fn decode_row(columns: List(String), values: List(Dynamic)) -> types.Row {
  let decoded_values = list.map(values, decode_value_from_dynamic)
  types.Row(columns:, values: decoded_values)
}

fn decode_value_from_dynamic(value: Dynamic) -> Value {
  case decode.run(value, decode.string) {
    Ok(s) -> Text(s)
    Error(_) ->
      case decode.run(value, decode.int) {
        Ok(i) -> Integer(i)
        Error(_) ->
          case decode.run(value, decode.float) {
            Ok(f) -> Float(f)
            Error(_) ->
              case
                decode.run(
                  value,
                  decode.field("type", decode.string, decode.success),
                )
              {
                Ok("blob") ->
                  case
                    decode.run(
                      value,
                      decode.field("base64", decode.string, decode.success),
                    )
                  {
                    Ok(encoded) ->
                      case bit_array.base64_decode(encoded) {
                        Ok(bits) -> Blob(bits)
                        Error(_) -> Null
                      }
                    Error(_) -> Null
                  }
                _ -> Null
              }
          }
      }
  }
}

fn parse_json(body: String) -> Result(Dynamic, String) {
  json.parse(body, decode.dynamic)
  |> result.map_error(fn(_) { "Failed to parse JSON" })
}

fn get_field(data: Dynamic, field_name: String) -> Result(Dynamic, String) {
  decode.run(
    data,
    decode.field(field_name, decode.dynamic, fn(v) { decode.success(v) }),
  )
  |> result.map_error(fn(_) { "Field '" <> field_name <> "' not found" })
}

fn get_string(data: Dynamic, field_name: String) -> Result(String, String) {
  decode.run(data, decode.field(field_name, decode.string, decode.success))
  |> result.map_error(fn(_) { "String field '" <> field_name <> "' not found" })
}

fn get_int(data: Dynamic, field_name: String) -> Result(Int, String) {
  decode.run(data, decode.field(field_name, decode.int, decode.success))
  |> result.map_error(fn(_) { "Int field '" <> field_name <> "' not found" })
}

fn get_list(data: Dynamic) -> Result(List(Dynamic), String) {
  decode.run(data, decode.list(decode.dynamic))
  |> result.map_error(fn(_) { "Not a list" })
}

fn get_list_of_lists(data: Dynamic) -> Result(List(List(Dynamic)), String) {
  decode.run(data, decode.list(decode.list(decode.dynamic)))
  |> result.map_error(fn(_) { "Not a list of lists" })
}
