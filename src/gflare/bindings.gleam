import gflare/d1.{type Database}
import gflare/durable_object.{type Namespace}
import gflare/error.{type Error}
import gflare/kv.{type Kv}
import gflare/queue.{type Queue}
import gflare/r2.{type Bucket}

pub type Env

@external(javascript, "../gflare_ffi_bindings.mjs", "get_kv")
pub fn kv(env: Env, name: String) -> Result(Kv, Error)

@external(javascript, "../gflare_ffi_bindings.mjs", "get_d1")
pub fn d1(env: Env, name: String) -> Result(Database, Error)

@external(javascript, "../gflare_ffi_bindings.mjs", "get_r2")
pub fn r2(env: Env, name: String) -> Result(Bucket, Error)

@external(javascript, "../gflare_ffi_bindings.mjs", "get_do_namespace")
pub fn durable_object(env: Env, name: String) -> Result(Namespace, Error)

@external(javascript, "../gflare_ffi_bindings.mjs", "get_queue_producer")
pub fn queue_producer(env: Env, name: String) -> Result(Queue, Error)

@external(javascript, "../gflare_ffi_bindings.mjs", "get_var")
pub fn var(env: Env, name: String) -> Result(String, Error)

@external(javascript, "../gflare_ffi_bindings.mjs", "get_secret")
pub fn secret(env: Env, name: String) -> Result(String, Error)
