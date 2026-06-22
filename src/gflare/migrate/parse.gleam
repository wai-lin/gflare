import gleam/io
import gleam/list
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/string
import simplifile

pub type Migration {
  Migration(version: Int, name: String, path: String, sql: String)
}

pub fn parse_migration_file(path: String) -> Result(Migration, String) {
  let filename = path |> string.split("/") |> list.last |> result.unwrap("")
  let name = filename |> string.replace(".sql", "")

  case parse_version_from_name(name) {
    Ok(version) -> {
      use content <- result.try(
        simplifile.read(path)
        |> result.map_error(fn(_) { "Failed to read " <> path }),
      )

      let sql =
        content
        |> string.split("\n")
        |> list.filter(fn(line) {
          let trimmed = string.trim(line)
          trimmed != "" && !string.starts_with(trimmed, "--")
        })
        |> string.join("\n")

      case sql {
        "" -> Error("Empty SQL in " <> path)
        _ -> Ok(Migration(version:, name:, path:, sql:))
      }
    }
    Error(_) -> Error("Invalid migration filename: " <> filename)
  }
}

pub fn parse_version_from_name(name: String) -> Result(Int, Nil) {
  case string.split(name, "_") {
    [version_str, ..] -> parse_version(version_str)
    _ -> Error(Nil)
  }
}

pub fn parse_version(s: String) -> Result(Int, Nil) {
  let digits = string.to_graphemes(s)
  list.try_fold(digits, 0, fn(acc, c) {
    case c {
      "0" -> Ok(acc * 10)
      "1" -> Ok(acc * 10 + 1)
      "2" -> Ok(acc * 10 + 2)
      "3" -> Ok(acc * 10 + 3)
      "4" -> Ok(acc * 10 + 4)
      "5" -> Ok(acc * 10 + 5)
      "6" -> Ok(acc * 10 + 6)
      "7" -> Ok(acc * 10 + 7)
      "8" -> Ok(acc * 10 + 8)
      "9" -> Ok(acc * 10 + 9)
      _ -> Error(Nil)
    }
  })
}

pub fn list_pending(
  migrations_dir: String,
  applied: List(String),
) -> Result(List(Migration), String) {
  use files <- result.try(
    simplifile.get_files(migrations_dir)
    |> result.map_error(fn(_) { "Failed to read migrations directory" }),
  )

  let migrations =
    files
    |> list.filter(fn(f) { string.ends_with(f, ".sql") })
    |> list.filter_map(fn(f) {
      case parse_migration_file(f) {
        Ok(migration) -> {
          let is_applied = list.any(applied, fn(a) { a == migration.name })
          case is_applied {
            True -> Error(Nil)
            False -> Ok(migration)
          }
        }
        Error(_) -> Error(Nil)
      }
    })
    |> list.sort(fn(a, b) { int_compare(a.version, b.version) })

  Ok(migrations)
}

pub fn int_compare(a: Int, b: Int) -> Order {
  case a < b {
    True -> Lt
    False ->
      case a > b {
        True -> Gt
        False -> Eq
      }
  }
}

pub fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> {
      let digit = n % 10
      let rest = n / 10
      case rest {
        0 -> digit_char(digit)
        _ -> int_to_string(rest) <> digit_char(digit)
      }
    }
  }
}

fn digit_char(d: Int) -> String {
  case d {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> "0"
  }
}
