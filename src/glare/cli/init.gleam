import gleam/io
import gleam/result
import gleam/string
import simplifile
import glare/cli/toml_utils

pub fn run() -> Nil {
  io.println("\nInitializing Cloudflare Workers in current project...")

  let outcome =
    toml_utils.load_config()
    |> result.map_error(fn(e) { "Failed to load gleam.toml: " <> e })
    |> result.try(fn(config) {
      add_cloudflare_section(config.package_name)
      |> result.map(fn(_) { config })
    })
    |> result.try(fn(config) {
      write_handler(config.package_name)
    })

  case outcome {
    Ok(_) -> {
      io.println("\nDone! Your project is ready for Cloudflare Workers.")
      io.println("\n  1. Edit your handler file to add Cloudflare Workers handlers")
      io.println("  2. Run: gleam run -m glare -- build")
      io.println("  3. Run: gleam run -m glare -- dev")
    }
    Error(msg) -> {
      io.println_error("Error: " <> msg)
    }
  }
}

fn add_cloudflare_section(package_name: String) -> Result(Nil, String) {
  use content <- result.try(
    simplifile.read("gleam.toml")
    |> result.map_error(fn(_) { "Could not read gleam.toml" }),
  )

  case string.contains(content, "[cloudflare]") {
    True -> {
      io.println("  [cloudflare] section already exists in gleam.toml")
      Ok(Nil)
    }
    False -> {
      let cf_name =
        package_name |> string.replace("_", with: "-") |> string.lowercase
      let today = "2025-01-01"
      let section =
        "\n[cloudflare]\n"
        <> "name = \"" <> cf_name <> "\"\n"
        <> "compatibility_date = \"" <> today <> "\"\n"
        <> "\n"
        <> "[cloudflare.bindings]\n"
      use _ <- result.try(
        simplifile.append(to: "gleam.toml", contents: section)
        |> result.map_error(fn(_) { "Failed to update gleam.toml" }),
      )
      io.println("  Added [cloudflare] section to gleam.toml")
      Ok(Nil)
    }
  }
}

fn write_handler(package_name: String) -> Result(Nil, String) {
  let handler_path = "src/" <> package_name <> ".gleam"

  case simplifile.is_file(handler_path) {
    Ok(True) -> {
      io.println("  Handler file already exists: " <> handler_path)
      io.println("  Edit it to add your Cloudflare Workers handlers.")
      Ok(Nil)
    }
    _ -> {
      let content =
        "import glare.{type Context, type Env}\n"
        <> "import glare/response\n"
        <> "\n"
        <> "pub fn fetch(request, env: Env, ctx: Context) {\n"
        <> "  response.new(200)\n"
        <> "  |> response.set_body(\"Hello from " <> package_name <> "!\")\n"
        <> "  |> promise.resolve\n"
        <> "}\n"
      simplifile.write(to: handler_path, contents: content)
      |> result.map_error(fn(_) { "Failed to write handler file" })
    }
  }
}
