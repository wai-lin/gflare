import gleam/json.{type Json}
import gleam/string

pub type Response

@external(javascript, "../gflare_ffi_worker.mjs", "new_response")
pub fn new(status: Int) -> Response

@external(javascript, "../gflare_ffi_worker.mjs", "set_body")
pub fn set_body(response: Response, body: String) -> Response

@external(javascript, "../gflare_ffi_worker.mjs", "set_header")
pub fn set_header(response: Response, name: String, value: String) -> Response

@external(javascript, "../gflare_ffi_worker.mjs", "response_json")
pub fn json(response: Response, data: Json) -> Response

@external(javascript, "../gflare_ffi_worker.mjs", "response_bytes")
pub fn bytes(response: Response, data: BitArray) -> Response

@external(javascript, "../gflare_ffi_worker.mjs", "response_empty")
pub fn empty(status: Int) -> Response

@external(javascript, "../gflare_ffi_worker.mjs", "redirect")
pub fn redirect(url: String, status: Int) -> Response

// Success responses

pub fn ok(data: Json) -> Response {
  new(200)
  |> json(data)
  |> set_header("content-type", "application/json")
}

pub fn ok_text(body: String) -> Response {
  new(200)
  |> set_body(body)
  |> set_header("content-type", "text/plain")
}

pub fn created(data: Json) -> Response {
  new(201)
  |> json(data)
  |> set_header("content-type", "application/json")
}

pub fn accepted() -> Response {
  new(202)
}

pub fn no_content() -> Response {
  new(204)
}

// Error responses

pub fn bad_request(message: String) -> Response {
  new(400)
  |> json(json.object([#("error", json.string(message))]))
  |> set_header("content-type", "application/json")
}

pub fn bad_request_json(errors: Json) -> Response {
  new(400)
  |> json(json.object([#("errors", errors)]))
  |> set_header("content-type", "application/json")
}

pub fn unauthorized(message: String) -> Response {
  new(401)
  |> json(json.object([#("error", json.string(message))]))
  |> set_header("content-type", "application/json")
}

pub fn forbidden(message: String) -> Response {
  new(403)
  |> json(json.object([#("error", json.string(message))]))
  |> set_header("content-type", "application/json")
}

pub fn not_found() -> Response {
  new(404)
  |> set_body("{\"error\":\"Not Found\"}")
  |> set_header("content-type", "application/json")
}

pub fn method_not_allowed(allow: List(String)) -> Response {
  let allow_header = string.join(allow, ", ")
  new(405)
  |> set_body("{\"error\":\"Method Not Allowed\"}")
  |> set_header("content-type", "application/json")
  |> set_header("Allow", allow_header)
}

pub fn conflict(message: String) -> Response {
  new(409)
  |> json(json.object([#("error", json.string(message))]))
  |> set_header("content-type", "application/json")
}

pub fn internal_error(message: String) -> Response {
  new(500)
  |> json(json.object([#("error", json.string(message))]))
  |> set_header("content-type", "application/json")
}

// Content type helpers

pub fn html(content: String) -> Response {
  new(200)
  |> set_body(content)
  |> set_header("content-type", "text/html")
}

pub fn text(content: String) -> Response {
  new(200)
  |> set_body(content)
  |> set_header("content-type", "text/plain")
}

pub fn xml(content: String) -> Response {
  new(200)
  |> set_body(content)
  |> set_header("content-type", "application/xml")
}
