import gleam/option.{type Option}

pub type Value {
  Text(String)
  Integer(Int)
  Float(Float)
  Blob(BitArray)
  Null
}

pub type Row {
  Row(columns: List(String), values: List(Value))
}

pub type ExecuteResult {
  ExecuteResult(
    rows: List(Row),
    columns: List(String),
    rows_affected: Int,
    last_insert_rowid: Option(Int),
  )
}

pub type BatchMode {
  Read
  Write
}
