pub type Error {
  KvError(message: String)
  D1Error(message: String)
  R2Error(message: String)
  DurableObjectError(message: String)
  QueueError(message: String)
  BindingNotFound(name: String)
  EncodingError(message: String)
  DecodingError(message: String)
}

pub fn to_string(error: Error) -> String {
  case error {
    KvError(msg) -> "KV error: " <> msg
    D1Error(msg) -> "D1 error: " <> msg
    R2Error(msg) -> "R2 error: " <> msg
    DurableObjectError(msg) -> "Durable Object error: " <> msg
    QueueError(msg) -> "Queue error: " <> msg
    BindingNotFound(name) -> "Binding not found: " <> name
    EncodingError(msg) -> "Encoding error: " <> msg
    DecodingError(msg) -> "Decoding error: " <> msg
  }
}
