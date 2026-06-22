# Code Generation

gflare can generate typed Gleam functions from SQL files. Write SQL with type annotations, and gflare generates functions with proper decoders.

## How It Works

1. Write SQL in `*.sql` files with type annotations
2. Run `gleam run -m gflare -- db generate`
3. gflare generates a `.gleam` module with typed functions

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

## Generate Code

```bash
# Generate for D1 (default)
gleam run -m gflare -- db generate

# Generate for Turso
gleam run -m gflare -- db generate --backend turso
```

## Generated Code (D1)

```gleam
// AUTO-GENERATED - src/my_app/sql.gleam
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

## Generated Code (Turso)

```gleam
// AUTO-GENERATED
import gflare/turso
import gflare/turso/error.{type TursoError}

pub fn find_user(
  config: turso.Config,
  user_id: Int,
) -> promise.Promise(Result(FindUserRow, TursoError)) {
  turso.execute(
    config,
    "SELECT id, name, email FROM users WHERE id = ?1",
    [turso.int(user_id)],
  )
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

```gleam
import my_app/sql
import gleam/io

pub fn fetch(request, env, ctx) {
  case bindings.d1(env, "DB") {
    Error(e) -> handle_error(e)
    Ok(db) -> {
      // Call the generated function
      use result <- promise.await(sql.find_user(db, 42))
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

## Strict Tables (Turso)

Turso STRICT tables support additional types. Use the SQL type name:

```sql
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

## Related

- [D1](d1.md) — D1 database usage
- [Turso](turso.md) — Turso database usage
- [Migrations](migrations.md) — database schema management
