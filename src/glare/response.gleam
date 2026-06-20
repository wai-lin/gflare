import gleam/json.{type Json}

pub type Response

@external(erlang, "glare_ffi_worker", "new_response")
@external(javascript, "glare_ffi_worker.mjs", "new_response")
pub fn new(status: Int) -> Response

@external(erlang, "glare_ffi_worker", "set_body")
@external(javascript, "glare_ffi_worker.mjs", "set_body")
pub fn set_body(response: Response, body: String) -> Response

@external(erlang, "glare_ffi_worker", "set_header")
@external(javascript, "glare_ffi_worker.mjs", "set_header")
pub fn set_header(response: Response, name: String, value: String) -> Response

@external(erlang, "glare_ffi_worker", "response_json")
@external(javascript, "glare_ffi_worker.mjs", "response_json")
pub fn json(response: Response, data: Json) -> Response

@external(erlang, "glare_ffi_worker", "response_bytes")
@external(javascript, "glare_ffi_worker.mjs", "response_bytes")
pub fn bytes(response: Response, data: BitArray) -> Response

@external(erlang, "glare_ffi_worker", "response_empty")
@external(javascript, "glare_ffi_worker.mjs", "response_empty")
pub fn empty(status: Int) -> Response

@external(erlang, "glare_ffi_worker", "redirect")
@external(javascript, "glare_ffi_worker.mjs", "redirect")
pub fn redirect(url: String, status: Int) -> Response
