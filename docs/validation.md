# Request Validation

Schema-based input validation with type-safe error messages.

## Quick Start

```gleam
import gflare/validate
import gflare/response

let user_schema = validate.object([
  #("name", validate.required(validate.string("name") |> validate.min_length(1))),
  #("email", validate.required(validate.email("email"))),
])

case validate.validate_body(user_schema, request) {
  Ok(user) -> create_user(user)
  Error(errors) -> response.bad_request_json(validate.format_errors(errors))
}
```

## Schema Builders

### Basic Types

```gleam
validate.string("name")     // String
validate.int("age")         // Int
validate.float("score")     // Float
validate.bool("active")     // Bool
```

### Containers

```gleam
validate.required("name", validate.string("name"))  // Required field
validate.optional("email", validate.string("email"))  // Optional field
```

### Composition

```gleam
// Chain validators
validate.string("name") |> validate.min_length(1) |> validate.max_length(100)

// Custom validator
validate.int("age") |> validate.custom(fn(age) {
  case age >= 18 {
    True -> Ok(age)
    False -> Error("Must be at least 18")
  }
})
```

## Common Validators

### String Validators

```gleam
validate.min_length(schema, 1)      // Minimum length
validate.max_length(schema, 100)    // Maximum length
validate.pattern(schema, "^[A-Z]+$")  // Regex pattern
validate.one_of(schema, ["a", "b"])  // One of values
```

### Number Validators

```gleam
validate.min(schema, 0)         // Minimum value
validate.max(schema, 100)       // Maximum value
validate.between(schema, 0, 100)  // Between min and max
validate.positive(schema)       // Must be positive (> 0)
validate.negative(schema)       // Must be negative (< 0)
```

### Common Patterns

```gleam
validate.email("email")      // Email format
validate.url("website")      // URL format
validate.uuid("id")          // UUID format
validate.ulid("id")          // ULID format
validate.date("created_at")  // YYYY-MM-DD
validate.time("start_time")  // HH:MM:SS
validate.datetime("ts")      // ISO 8601 datetime
```

## Validation Functions

### Validate Data

```gleam
case validate.validate(schema, data) {
  Ok(value) -> handle_value(value)
  Error(errors) -> handle_errors(errors)
}
```

### Validate Request Body

```gleam
use result <- promise.await(validate.validate_body(schema, request))
case result {
  Ok(value) -> handle_value(value)
  Error(errors) -> handle_errors(errors)
}
```

## Error Handling

### Format Errors as JSON

```gleam
let errors = [
  validate.ValidationError(field: "name", message: "Required"),
  validate.ValidationError(field: "email", message: "Invalid format"),
]

response.bad_request_json(validate.format_errors(errors))
// Returns: {"errors": [{"field": "name", "message": "Required"}, ...]}
```

### Format Errors as String

```gleam
let error_string = validate.errors_to_string(errors)
// Returns: "name: Required; email: Invalid format"
```

## Complete Example

```gleam
import gflare/router
import gflare/validate
import gflare/response
import gflare/request

// Define schemas
let user_schema = validate.object([
  #("name", validate.required(validate.string("name") |> validate.min_length(1) |> validate.max_length(100))),
  #("email", validate.required(validate.email("email"))),
  #("age", validate.optional(validate.int("age") |> validate.between(0, 150))),
  #("website", validate.optional(validate.url("website"))),
])

// Handler
fn create_user_handler(req, env, ctx, params) {
  use result <- promise.await(validate.validate_body(user_schema, req))
  case result {
    Ok(user) -> {
      // user.name is String
      // user.email is String
      // user.age is Option(Int)
      // user.website is Option(String)
      response.created(json.object([#("message", json.string("Created"))]))
      |> promise.resolve
    }
    Error(errors) -> {
      response.bad_request_json(validate.format_errors(errors))
      |> promise.resolve
    }
  }
}

// Routes
let routes = router.new()
|> router.post("/users", create_user_handler)
```

## Validation Error Type

```gleam
pub type ValidationError {
  ValidationError(field: String, message: String)
}
```

## Related

- [Router](router.md) — handler integration
- [Response Helpers](router.md#response-helpers) — error responses
