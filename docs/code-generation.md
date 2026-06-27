# Code Generation

gflare can generate typed Gleam functions from SQL files. Write SQL with type annotations, and gflare generates functions with proper decoders.

## How It Works

1. Write SQL in `*.sql` files with type annotations
2. Run `gleam run -m gflare -- db generate`
3. gflare generates `.gleam` modules in `src/gen/`

## SQL File Format

Create SQL files in your `src/` directory:

```sql
-- src/my_app/sql/find_user.sql
-- params: user_id: Int
-- returns: id: Int, name: String, email: Option(String)
SELECT id, name, email FROM users WHERE id = ?1
```

```sql
-- src/my_app/sql/create_user.sql
-- params: name: String, email: String
INSERT INTO users (name, email) VALUES (?1, ?2)
```

### Single vs Multiple Rows

Use `-- returns:` for queries that return a single row (uses `d1.first()`):

```sql
-- returns: id: Int, name: String
SELECT id, name FROM users WHERE id = ?1
```

Use `-- returns-many:` for queries that return multiple rows (uses `d1.all()`):

```sql
-- returns-many: id: Int, name: String
SELECT id, name FROM users ORDER BY name
```

Queries with no `-- returns:` or `-- returns-many:` annotation use `d1.run()` and return the raw result.

### Backend Selection

You can specify which backend to generate for each SQL file using the `-- backend:` comment:

```sql
-- backend: d1
-- params: user_id: Int
SELECT * FROM users WHERE id = ?1
```

```sql
-- backend: turso
-- params: event_id: String
SELECT * FROM events WHERE id = ?1
```

```sql
-- backend: d1, turso
-- params: user_id: Int
SELECT * FROM users WHERE id = ?1
```

If no `-- backend:` comment is present, the CLI `--backend` flag is used as default.

## Generate Code

```bash
# Generate for D1 (default)
gleam run -m gflare -- db generate

# Generate for Turso
gleam run -m gflare -- db generate --backend turso

# Generate for both D1 and Turso
gleam run -m gflare -- db generate --backend both
```

## Output Structure

### Single Backend

When using `--backend d1` or `--backend turso`:

```
src/gen/
└── d1_sql.gleam    # or turso_sql.gleam (types inlined)
```

### Both Backends

When using `--backend both`:

```
src/gen/
├── sql_shared.gleam    # Shared row types
├── d1_sql.gleam        # D1 functions (imports sql_shared)
└── turso_sql.gleam     # Turso functions (imports sql_shared)
```

## Generated Code Examples

### D1 — Single Row (src/gen/d1_sql.gleam)

```gleam
// AUTO-GENERATED - D1 SQL functions
// Do not edit manually
import gleam/dynamic/decode
import gleam/javascript/promise
import gleam/option.{type Option, None, Some}
import gflare/d1
import gflare/error.{type Error}

pub type FindUserRow {
  FindUserRow(id: Int, name: String, email: Option(String))
}

pub fn find_user(
  db: d1.Database,
  user_id: Int,
) -> promise.Promise(Result(FindUserRow, Error)) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use email <- decode.optional_field(2, "", decode.string)
    decode.success(FindUserRow(id:, name:, email:))
  }
  use result <- promise.await(
    d1.prepare(db, "SELECT id, name, email FROM users WHERE id = ?1")
    |> d1.bind([d1.int(user_id)])
    |> d1.first(),
  )
  case result {
    Ok(Some(row)) -> decode.run(row, decoder)
    Ok(None) -> promise.resolve(Error(error.D1Error("No row found")))
    Error(e) -> promise.resolve(Error(e))
  }
}
```

### D1 — Multiple Rows (src/gen/d1_sql.gleam)

```gleam
pub type ListUsersRow {
  ListUsersRow(id: Int, name: String)
}

pub fn list_users(
  db: d1.Database,
) -> promise.Promise(Result(List(ListUsersRow), Error)) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    decode.success(ListUsersRow(id:, name:))
  }
  use result <- promise.await(
    d1.prepare(db, "SELECT id, name FROM users ORDER BY name")
    |> d1.bind([])
    |> d1.all(),
  )
  case result {
    Ok(d1_result) -> {
      let decoded = list.filter_map(d1_result.results, fn(row) {
        case decode.run(row, decoder) {
          Ok(row) -> Ok(row)
          Error(_) -> Error(Nil)
        }
      })
      promise.resolve(Ok(decoded))
    }
    Error(e) -> promise.resolve(Error(e))
  }
}
```

### Turso — Single Row (src/gen/turso_sql.gleam)

```gleam
// AUTO-GENERATED - Turso SQL functions
// Do not edit manually
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gflare/turso
import gflare/turso/error.{type TursoError}
import gflare/turso/types.{type Value}

pub type FindUserRow {
  FindUserRow(id: Int, name: String, email: Option(String))
}

pub fn find_user(
  config: turso.Config,
  user_id: Int,
) -> promise.Promise(Result(FindUserRow, TursoError)) {
  use result <- promise.await(turso.execute(
    config,
    "SELECT id, name, email FROM users WHERE id = ?1",
    [turso.int(user_id)],
  ))
  case result {
    Ok(execute_result) -> {
      use row <- result.try(execute_result.rows |> list.first |> result.replace_error(error.DecodeError("No row found")))
      id <- extract_turso_value(row.values, 0, fn(v) { case v { turso.types.Integer(i) -> i, _ -> 0 } })
      name <- extract_turso_value(row.values, 1, fn(v) { case v { turso.types.Text(s) -> s, _ -> "" } })
      email <- extract_turso_value(row.values, 2, fn(v) { case v { turso.types.Null -> None, turso.types.Text(s) -> Some(s), _ -> None } })
      promise.resolve(Ok(FindUserRow(id:, name:, email:)))
    }
    Error(e) -> promise.resolve(Error(e))
  }
}
```

### Turso — Multiple Rows (src/gen/turso_sql.gleam)

```gleam
pub type ListUsersRow {
  ListUsersRow(id: Int, name: String)
}

pub fn list_users(
  config: turso.Config,
) -> promise.Promise(Result(List(ListUsersRow), TursoError)) {
  use result <- promise.await(turso.execute(
    config,
    "SELECT id, name FROM users ORDER BY name",
    [],
  ))
  case result {
    Ok(execute_result) -> {
      let decoded = list.filter_map(execute_result.rows, fn(row) {
        use id <- extract_turso_value(row.values, 0, fn(v) { case v { turso.types.Integer(i) -> i, _ -> 0 } })
        use name <- extract_turso_value(row.values, 1, fn(v) { case v { turso.types.Text(s) -> s, _ -> "" } })
        Ok(ListUsersRow(id:, name:))
      })
      promise.resolve(Ok(decoded))
    }
    Error(e) -> promise.resolve(Error(e))
  }
}
```

### Shared Types (src/gen/sql_shared.gleam)

```gleam
// AUTO-GENERATED - shared types for SQL queries
// Do not edit manually
import gleam/option.{type Option}

pub type FindUserRow {
  FindUserRow(id: Int, name: String, email: Option(String))
}
```

## Supported Types

| SQL Annotation | Gleam Type | Description |
|----------------|------------|-------------|
| `Int` | `Int` | Integer |
| `Float` | `Float` | Floating point |
| `String` | `String` | Text |
| `Bool` | `Bool` | Boolean (0/1) |
| `BitArray` | `BitArray` | Binary data |
| `Date` | `String` | ISO 8601 date (YYYY-MM-DD) |
| `Time` | `String` | ISO 8601 time (HH:MM:SS) |
| `Timestamp` | `String` | ISO 8601 datetime |
| `Uuid` | `String` | UUID string |
| `Json` | `String` | JSON text |
| `Option(T)` | `Option(T)` | Nullable type |

## Using Generated Functions

### D1 — Single Row

```gleam
import my_app/gen/d1_sql
import gleam/io

pub fn fetch(request, env, ctx) {
  case bindings.d1(env, "DB") {
    Error(e) -> handle_error(e)
    Ok(db) -> {
      use result <- promise.await(d1_sql.find_user(db, 42))
      case result {
        Ok(user) -> {
          io.println("Found: " <> user.name)
          respond_with_user(user)
        }
        Error(e) -> handle_error(e)
      }
    }
  }
}
```

### D1 — Multiple Rows

```gleam
import my_app/gen/d1_sql
import gleam/io
import gleam/list

pub fn fetch(request, env, ctx) {
  case bindings.d1(env, "DB") {
    Error(e) -> handle_error(e)
    Ok(db) -> {
      use result <- promise.await(d1_sql.list_users(db))
      case result {
        Ok(users) -> {
          io.println("Found " <> int.to_string(list.length(users)) <> " users")
          respond_with_users(users)
        }
        Error(e) -> handle_error(e)
      }
    }
  }
}
```

### Turso

```gleam
import my_app/gen/turso_sql
import gleam/io

pub fn fetch(request, env, ctx) {
  let config = turso.connect(url, token)
  use result <- promise.await(turso_sql.find_user(config, 42))
  case result {
    Ok(user) -> {
      io.println("Found: " <> user.name)
      respond_with_user(user)
    }
    Error(e) -> handle_error(e)
  }
}
```

## Strict Tables (Turso)

Turso STRICT tables support additional types. Use the SQL type name:

```sql
-- backend: turso
-- src/my_app/sql/find_event.sql
-- params: event_id: Uuid
-- returns: id: Uuid, name: String, event_date: Date, metadata: Json
SELECT id, name, event_date, metadata FROM events WHERE id = ?1
```

Generated code uses typed constructors:

```gleam
turso.execute(config, sql, [turso.uuid(event_id)])
turso.date("2025-03-15")
turso.timestamp("2025-03-15T10:30:00Z")
turso.json_string("{\"key\": \"value\"}")
```

## Backend Resolution

| SQL Comment | CLI Flag | Result |
|-------------|----------|--------|
| `-- backend: d1` | `--backend both` | Generate D1 only |
| `-- backend: turso` | `--backend both` | Generate Turso only |
| `-- backend: d1, turso` | `--backend both` | Generate both |
| `-- backend: d1` | `--backend d1` | Generate D1 only |
| `-- backend: turso` | `--backend turso` | Generate Turso only |
| *(no comment)* | `--backend d1` | Generate D1 only |
| *(no comment)* | `--backend turso` | Generate Turso only |
| *(no comment)* | `--backend both` | Generate both |

## Related

- [D1](d1.md) — D1 database usage
- [Turso](turso.md) — Turso database usage
- [Migrations](migrations.md) — database schema management
