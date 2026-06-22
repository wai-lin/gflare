import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub fn sparse(entries: List(#(String, json.Json))) -> json.Json {
  list.filter(entries, fn(entry) {
    let #(_, v) = entry
    v != json.null()
  })
  |> json.object
}

pub fn option_to_json(
  option: Option(a),
  encoder: fn(a) -> json.Json,
) -> json.Json {
  case option {
    Some(value) -> encoder(value)
    None -> json.null()
  }
}

pub fn option_from_dynamic(
  value: Dynamic,
  decoder: decode.Decoder(a),
) -> Option(a) {
  case decode.run(value, decoder) {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}

pub fn decode_string(field_name: String) -> decode.Decoder(String) {
  use value <- decode.field(field_name, decode.string)
  decode.success(value)
}

pub fn decode_int(field_name: String) -> decode.Decoder(Int) {
  use value <- decode.field(field_name, decode.int)
  decode.success(value)
}

pub fn decode_float(field_name: String) -> decode.Decoder(Float) {
  use value <- decode.field(field_name, decode.float)
  decode.success(value)
}

pub fn decode_bool(field_name: String) -> decode.Decoder(Bool) {
  use value <- decode.field(field_name, decode.bool)
  decode.success(value)
}

pub fn parse(json_string: String) -> Result(Dynamic, String) {
  case json.parse(json_string, decode.dynamic) {
    Ok(value) -> Ok(value)
    Error(e) -> Error("JSON decode error: " <> string.inspect(e))
  }
}
