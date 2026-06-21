import gleam/javascript/promise.{type Promise}

pub type Context

@external(javascript, "../gflare_ffi_worker.mjs", "wait_until")
pub fn wait_until(ctx: Context, promise: Promise(a)) -> Nil

@external(javascript, "../gflare_ffi_worker.mjs", "pass_through_on_exception")
pub fn pass_through_on_exception(ctx: Context) -> Nil
