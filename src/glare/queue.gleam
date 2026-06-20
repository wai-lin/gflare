import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import glare/error.{type Error, QueueError}

pub type Queue
pub type Message(a)

@external(erlang, "glare_ffi_queue", "queue_send")
@external(javascript, "glare_ffi_queue.mjs", "queue_send")
fn do_send(queue: Queue, message: Json) -> Promise(Result(Dynamic, String))

pub fn send(
  queue: Queue,
  message: Json,
) -> Promise(Result(Nil, Error)) {
  use result <- promise.await(do_send(queue, message))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(msg) -> promise.resolve(Error(QueueError(msg)))
  }
}

@external(erlang, "glare_ffi_queue", "queue_send_batch")
@external(javascript, "glare_ffi_queue.mjs", "queue_send_batch")
fn do_send_batch(queue: Queue, messages: List(Json)) -> Promise(Result(Dynamic, String))

pub fn send_batch(
  queue: Queue,
  messages: List(Json),
) -> Promise(Result(Nil, Error)) {
  use result <- promise.await(do_send_batch(queue, messages))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(msg) -> promise.resolve(Error(QueueError(msg)))
  }
}

@external(erlang, "glare_ffi_queue", "queue_ack")
@external(javascript, "glare_ffi_queue.mjs", "queue_ack")
fn do_ack(message: Message(a)) -> Promise(Result(Dynamic, String))

pub fn ack(
  message: Message(a),
) -> Promise(Result(Nil, Error)) {
  use result <- promise.await(do_ack(message))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(msg) -> promise.resolve(Error(QueueError(msg)))
  }
}

@external(erlang, "glare_ffi_queue", "queue_retry")
@external(javascript, "glare_ffi_queue.mjs", "queue_retry")
fn do_retry(message: Message(a)) -> Promise(Result(Dynamic, String))

pub fn retry(
  message: Message(a),
) -> Promise(Result(Nil, Error)) {
  use result <- promise.await(do_retry(message))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(msg) -> promise.resolve(Error(QueueError(msg)))
  }
}

@external(erlang, "glare_ffi_queue", "queue_message_id")
@external(javascript, "glare_ffi_queue.mjs", "queue_message_id")
pub fn message_id(message: Message(a)) -> String

@external(erlang, "glare_ffi_queue", "queue_message_timestamp")
@external(javascript, "glare_ffi_queue.mjs", "queue_message_timestamp")
pub fn message_timestamp(message: Message(a)) -> Int

@external(erlang, "glare_ffi_queue", "queue_message_body")
@external(javascript, "glare_ffi_queue.mjs", "queue_message_body")
pub fn message_body(message: Message(a)) -> a

@external(erlang, "glare_ffi_queue", "queue_message_attempts")
@external(javascript, "glare_ffi_queue.mjs", "queue_message_attempts")
pub fn message_attempts(message: Message(a)) -> Int
