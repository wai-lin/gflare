import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}

pub type HttpRequest

@external(erlang, "glare_ffi_worker", "request_url")
@external(javascript, "glare_ffi_worker.mjs", "request_url")
pub fn url(request: HttpRequest) -> String

@external(erlang, "glare_ffi_worker", "request_method")
@external(javascript, "glare_ffi_worker.mjs", "request_method")
pub fn method(request: HttpRequest) -> String

@external(erlang, "glare_ffi_worker", "request_headers")
@external(javascript, "glare_ffi_worker.mjs", "request_headers")
pub fn headers(request: HttpRequest) -> List(#(String, String))

@external(erlang, "glare_ffi_worker", "request_body")
@external(javascript, "glare_ffi_worker.mjs", "request_body")
pub fn body(request: HttpRequest) -> Dynamic

@external(erlang, "glare_ffi_worker", "request_text")
@external(javascript, "glare_ffi_worker.mjs", "request_text")
pub fn text(request: HttpRequest) -> Promise(Result(String, String))

@external(erlang, "glare_ffi_worker", "request_json")
@external(javascript, "glare_ffi_worker.mjs", "request_json")
pub fn json(request: HttpRequest) -> Promise(Result(Dynamic, String))

@external(erlang, "glare_ffi_worker", "request_array_buffer")
@external(javascript, "glare_ffi_worker.mjs", "request_array_buffer")
pub fn array_buffer(request: HttpRequest) -> Promise(Result(BitArray, String))
