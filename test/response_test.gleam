import gleeunit

import gleam/json
import glare/response

pub fn main() {
  gleeunit.main()
}

// Response construction - just verify they don't crash

pub fn new_response_test() {
  let _ = response.new(200)
  Nil
}

pub fn new_response_various_status_codes_test() {
  let _ = response.new(200)
  let _ = response.new(201)
  let _ = response.new(204)
  let _ = response.new(301)
  let _ = response.new(302)
  let _ = response.new(400)
  let _ = response.new(404)
  let _ = response.new(500)
  Nil
}

// Response body - verify chaining works

pub fn set_body_test() {
  response.new(200)
  |> response.set_body("Hello, World!")
  |> fn(_) { Nil }
}

pub fn set_body_empty_string_test() {
  response.new(200)
  |> response.set_body("")
  |> fn(_) { Nil }
}

pub fn set_body_multiline_test() {
  response.new(200)
  |> response.set_body("line1\nline2\nline3")
  |> fn(_) { Nil }
}

// Response headers - verify chaining works

pub fn set_header_test() {
  response.new(200)
  |> response.set_header("Content-Type", "text/plain")
  |> fn(_) { Nil }
}

pub fn set_multiple_headers_test() {
  response.new(200)
  |> response.set_header("Content-Type", "application/json")
  |> response.set_header("X-Custom", "value")
  |> fn(_) { Nil }
}

pub fn set_header_overwrites_test() {
  response.new(200)
  |> response.set_header("X-Count", "1")
  |> response.set_header("X-Count", "2")
  |> fn(_) { Nil }
}

// JSON response - verify chaining works

pub fn json_response_test() {
  let data = json.object([#("status", json.string("ok"))])
  response.new(200)
  |> response.json(data)
  |> fn(_) { Nil }
}

pub fn json_response_empty_object_test() {
  let data = json.object([])
  response.new(200)
  |> response.json(data)
  |> fn(_) { Nil }
}

// Empty response - verify it doesn't crash

pub fn empty_response_test() {
  let _ = response.empty(204)
  Nil
}

pub fn empty_response_with_different_status_test() {
  let _ = response.empty(204)
  let _ = response.empty(200)
  Nil
}

// Redirect - verify it doesn't crash

pub fn redirect_test() {
  let _ = response.redirect("https://example.com", 302)
  Nil
}

pub fn redirect_permanent_test() {
  let _ = response.redirect("https://example.com/new", 301)
  Nil
}

pub fn redirect_to_different_urls_test() {
  let _ = response.redirect("https://a.com", 302)
  let _ = response.redirect("https://b.com", 302)
  Nil
}

// Chaining - verify all functions chain correctly

pub fn response_chaining_test() {
  response.new(200)
  |> response.set_header("X-Request-Id", "123")
  |> response.set_header("Content-Type", "text/html")
  |> response.set_body("<h1>Hello</h1>")
  |> fn(_) { Nil }
}

pub fn json_with_headers_chaining_test() {
  json.object([#("message", json.string("hello"))])
  |> fn(data) { response.new(200) |> response.json(data) }
  |> response.set_header("X-Version", "1.0")
  |> fn(_) { Nil }
}
