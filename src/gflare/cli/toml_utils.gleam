import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import simplifile
import tom.{type Toml}

pub type CfConfig {
  CfConfig(
    name: String,
    compatibility_date: String,
    bindings: CfBindings,
    durable_objects: CfDoConfig,
    vars: dict.Dict(String, String),
  )
}

pub type CfBindings {
  CfBindings(
    kv: List(String),
    d1: List(String),
    r2: List(String),
    queues_producers: List(String),
    queues_consumers: List(String),
  )
}

pub type CfDoConfig {
  CfDoConfig(classes: List(DoClass))
}

pub type DoClass {
  DoClass(name: String, module: String)
}

pub type Config {
  Config(package_name: String, cloudflare: CfConfig)
}

pub fn load_config() -> Result(Config, String) {
  use content <- result.try(
    simplifile.read("gleam.toml")
    |> result.map_error(fn(_) { "Could not read gleam.toml" }),
  )
  parse_config(content)
}

pub fn parse_config(content: String) -> Result(Config, String) {
  use parsed <- result.try(
    tom.parse(content)
    |> result.map_error(fn(err) { "TOML parse error: " <> string.inspect(err) }),
  )

  use package_name <- result.try(
    tom.get_string(parsed, ["name"])
    |> result.map_error(fn(_) { "Missing 'name' in gleam.toml" }),
  )

  use cf_table <- result.try(
    tom.get_table(parsed, ["cloudflare"])
    |> result.map_error(fn(_) { "Missing [cloudflare] section in gleam.toml" }),
  )

  use cf_name <- result.try(
    get_string(cf_table, ["name"])
    |> result.replace_error("Missing [cloudflare].name"),
  )

  let compat_date = case get_string(cf_table, ["compatibility_date"]) {
    Ok(d) -> d
    Error(_) -> ""
  }

  let bindings = parse_bindings(cf_table)
  let do_config = parse_do_config(cf_table)
  let vars = parse_vars(cf_table)

  Ok(Config(
    package_name:,
    cloudflare: CfConfig(
      name: cf_name,
      compatibility_date: compat_date,
      bindings:,
      durable_objects: do_config,
      vars:,
    ),
  ))
}

fn parse_bindings(cf_table: dict.Dict(String, Toml)) -> CfBindings {
  CfBindings(
    kv: get_string_list(cf_table, ["bindings", "kv"]),
    d1: get_string_list(cf_table, ["bindings", "d1"]),
    r2: get_string_list(cf_table, ["bindings", "r2"]),
    queues_producers: get_string_list(cf_table, ["bindings", "queues_producers"]),
    queues_consumers: get_string_list(cf_table, ["bindings", "queues_consumers"]),
  )
}

fn parse_do_config(cf_table: dict.Dict(String, Toml)) -> CfDoConfig {
  case get_table(cf_table, ["durable_objects"]) {
    Ok(do_table) -> {
      case get_array_of_tables(do_table, ["classes"]) {
        Ok(classes) ->
          CfDoConfig(classes: list.filter_map(classes, parse_do_class))
        Error(_) -> CfDoConfig(classes: [])
      }
    }
    Error(_) -> CfDoConfig(classes: [])
  }
}

fn parse_do_class(
  class_table: dict.Dict(String, Toml),
) -> Result(DoClass, String) {
  use name <- result.try(
    get_string(class_table, ["name"])
    |> result.replace_error("Missing DO class name"),
  )
  use module <- result.try(
    get_string(class_table, ["module"])
    |> result.replace_error("Missing DO class module"),
  )
  Ok(DoClass(name:, module:))
}

fn parse_vars(cf_table: dict.Dict(String, Toml)) -> dict.Dict(String, String) {
  case get_table(cf_table, ["vars"]) {
    Ok(vars_table) ->
      dict.fold(vars_table, dict.new(), fn(acc, key, value) {
        case tom.as_string(value) {
          Ok(s) -> dict.insert(acc, key, s)
          Error(_) -> acc
        }
      })
    Error(_) -> dict.new()
  }
}

fn get_string(
  table: dict.Dict(String, Toml),
  path: List(String),
) -> Result(String, String) {
  tom.get_string(table, path)
  |> result.map_error(fn(_) { "Key not found: " <> string.join(path, ".") })
}

fn get_table(
  table: dict.Dict(String, Toml),
  path: List(String),
) -> Result(dict.Dict(String, Toml), String) {
  tom.get_table(table, path)
  |> result.map_error(fn(_) { "Key not found: " <> string.join(path, ".") })
}

fn get_string_list(
  table: dict.Dict(String, Toml),
  path: List(String),
) -> List(String) {
  case tom.get(table, path) {
    Ok(tom.Array(items)) ->
      list.filter_map(items, fn(item) { tom.as_string(item) })
    Ok(tom.ArrayOfTables(_)) -> []
    _ -> []
  }
}

fn get_array_of_tables(
  table: dict.Dict(String, Toml),
  path: List(String),
) -> Result(List(dict.Dict(String, Toml)), String) {
  case tom.get(table, path) {
    Ok(tom.ArrayOfTables(tables)) -> Ok(tables)
    Ok(tom.Array(items)) ->
      Ok(list.filter_map(items, fn(item) { tom.as_table(item) }))
    _ -> Error("Not an array of tables")
  }
}
