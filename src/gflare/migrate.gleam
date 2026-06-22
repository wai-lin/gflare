import gflare/d1
import gflare/error
import gflare/migrate/parse.{type Migration}
import gflare/turso
import gflare/turso/error as turso_err
import gflare/turso/types as turso_types
import gleam/dynamic/decode
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list

const tracking_table = "_gflare_migrations"

pub fn run_turso(
  config: turso.Config,
  migrations_dir: String,
) -> Promise(Result(Nil, String)) {
  use _ <- promise.await(ensure_tracking_table_turso(config))
  use applied <- promise.await(list_applied_turso(config))
  case applied {
    Error(e) -> promise.resolve(Error(e))
    Ok(applied) -> {
      case parse.list_pending(migrations_dir, applied) {
        Error(e) -> promise.resolve(Error(e))
        Ok(pending) -> execute_pending_turso(config, pending)
      }
    }
  }
}

pub fn run_d1(
  db: d1.Database,
  migrations_dir: String,
) -> Promise(Result(Nil, String)) {
  use _ <- promise.await(ensure_tracking_table_d1(db))
  use applied <- promise.await(list_applied_d1(db))
  case applied {
    Error(e) -> promise.resolve(Error(e))
    Ok(applied) -> {
      case parse.list_pending(migrations_dir, applied) {
        Error(e) -> promise.resolve(Error(e))
        Ok(pending) -> execute_pending_d1(db, pending)
      }
    }
  }
}

fn ensure_tracking_table_turso(
  config: turso.Config,
) -> Promise(Result(Nil, String)) {
  let sql =
    "CREATE TABLE IF NOT EXISTS "
    <> tracking_table
    <> " (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, applied_at TEXT DEFAULT (datetime('now')))"
  use result <- promise.await(turso.execute(config, sql, []))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(e) ->
      promise.resolve(Error(
        "Failed to create tracking table: " <> turso_err.to_string(e),
      ))
  }
}

fn ensure_tracking_table_d1(db: d1.Database) -> Promise(Result(Nil, String)) {
  let sql =
    "CREATE TABLE IF NOT EXISTS "
    <> tracking_table
    <> " (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, applied_at TEXT DEFAULT (datetime('now')))"
  use result <- promise.await(d1.exec(db, sql))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(e) ->
      promise.resolve(Error(
        "Failed to create tracking table: " <> error.to_string(e),
      ))
  }
}

fn list_applied_turso(
  config: turso.Config,
) -> Promise(Result(List(String), String)) {
  let sql = "SELECT name FROM " <> tracking_table <> " ORDER BY id"
  use result <- promise.await(turso.execute(config, sql, []))
  case result {
    Ok(execute_result) -> {
      let names =
        list.filter_map(execute_result.rows, fn(row) {
          case row.values {
            [turso_types.Text(name), ..] -> Ok(name)
            _ -> Error(Nil)
          }
        })
      promise.resolve(Ok(names))
    }
    Error(e) ->
      promise.resolve(Error(
        "Failed to list applied migrations: " <> turso_err.to_string(e),
      ))
  }
}

fn list_applied_d1(db: d1.Database) -> Promise(Result(List(String), String)) {
  let stmt =
    d1.prepare(db, "SELECT name FROM " <> tracking_table <> " ORDER BY id")
  use result <- promise.await(d1.all(stmt))
  case result {
    Ok(d1_result) -> {
      let decoder = {
        use name <- decode.field("name", decode.string)
        decode.success(name)
      }
      let names =
        list.filter_map(d1_result.results, fn(row) {
          case decode.run(row, decoder) {
            Ok(name) -> Ok(name)
            Error(_) -> Error(Nil)
          }
        })
      promise.resolve(Ok(names))
    }
    Error(e) ->
      promise.resolve(Error(
        "Failed to list applied migrations: " <> error.to_string(e),
      ))
  }
}

fn execute_pending_turso(
  config: turso.Config,
  pending: List(Migration),
) -> Promise(Result(Nil, String)) {
  case pending {
    [] -> {
      io.println("No pending migrations.")
      promise.resolve(Ok(Nil))
    }
    _ -> {
      io.println(
        "Applying "
        <> parse.int_to_string(list.length(pending))
        <> " migration(s)...",
      )
      execute_migrations_turso(config, pending)
    }
  }
}

fn execute_migrations_turso(
  config: turso.Config,
  migrations: List(Migration),
) -> Promise(Result(Nil, String)) {
  case migrations {
    [] -> promise.resolve(Ok(Nil))
    [migration, ..rest] -> {
      io.println("  Applying: " <> migration.name)
      use result <- promise.await(turso.execute(config, migration.sql, []))
      case result {
        Ok(_) -> {
          use _ <- promise.await(record_migration_turso(config, migration.name))
          execute_migrations_turso(config, rest)
        }
        Error(e) ->
          promise.resolve(Error(
            "Failed to apply migration "
            <> migration.name
            <> ": "
            <> turso_err.to_string(e),
          ))
      }
    }
  }
}

fn record_migration_turso(
  config: turso.Config,
  name: String,
) -> Promise(Result(Nil, String)) {
  let sql = "INSERT INTO " <> tracking_table <> " (name) VALUES (?)"
  use result <- promise.await(turso.execute(config, sql, [turso.text(name)]))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(e) ->
      promise.resolve(Error(
        "Failed to record migration " <> name <> ": " <> turso_err.to_string(e),
      ))
  }
}

fn execute_pending_d1(
  db: d1.Database,
  pending: List(Migration),
) -> Promise(Result(Nil, String)) {
  case pending {
    [] -> {
      io.println("No pending migrations.")
      promise.resolve(Ok(Nil))
    }
    _ -> {
      io.println(
        "Applying "
        <> parse.int_to_string(list.length(pending))
        <> " migration(s)...",
      )
      execute_migrations_d1(db, pending)
    }
  }
}

fn execute_migrations_d1(
  db: d1.Database,
  migrations: List(Migration),
) -> Promise(Result(Nil, String)) {
  case migrations {
    [] -> promise.resolve(Ok(Nil))
    [migration, ..rest] -> {
      io.println("  Applying: " <> migration.name)
      use result <- promise.await(d1.exec(db, migration.sql))
      case result {
        Ok(_) -> {
          use _ <- promise.await(record_migration_d1(db, migration.name))
          execute_migrations_d1(db, rest)
        }
        Error(e) ->
          promise.resolve(Error(
            "Failed to apply migration "
            <> migration.name
            <> ": "
            <> error.to_string(e),
          ))
      }
    }
  }
}

fn record_migration_d1(
  db: d1.Database,
  name: String,
) -> Promise(Result(Nil, String)) {
  let stmt =
    d1.prepare(db, "INSERT INTO " <> tracking_table <> " (name) VALUES (?)")
  let stmt = d1.bind(stmt, [d1.text(name)])
  use result <- promise.await(d1.run(stmt))
  case result {
    Ok(_) -> promise.resolve(Ok(Nil))
    Error(e) ->
      promise.resolve(Error(
        "Failed to record migration " <> name <> ": " <> error.to_string(e),
      ))
  }
}
