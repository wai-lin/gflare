import gleam/io
import gleam/result
import gleam/string
import simplifile

pub fn run(project_name: String) -> Nil {
  io.println("\nCreating project: " <> project_name)

  let cf_name = project_name |> string.replace("_", with: "-") |> string.lowercase

  let outcome =
    create_dirs(project_name)
    |> result.try(fn(_) { write_gleam_toml(project_name, cf_name) })
    |> result.try(fn(_) { write_handler(project_name) })
    |> result.try(fn(_) { write_test(project_name) })
    |> result.try(fn(_) { write_dev(project_name) })
    |> result.try(fn(_) { write_gitignore(project_name) })

  case outcome {
    Ok(_) -> {
      io.println("\nProject created!")
      io.println("\n  cd " <> project_name)
      io.println("  gleam add glare")
      io.println("  gleam run -m " <> project_name)
    }
    Error(msg) -> {
      io.println_error("Error creating project: " <> msg)
    }
  }
}

fn create_dirs(name: String) -> Result(Nil, String) {
  use _ <- result.try(
    simplifile.create_directory_all(name <> "/src")
    |> result.map_error(fn(_) { "Failed to create src directory" }),
  )
  use _ <- result.try(
    simplifile.create_directory_all(name <> "/test")
    |> result.map_error(fn(_) { "Failed to create test directory" }),
  )
  use _ <- result.try(
    simplifile.create_directory_all(name <> "/dev")
    |> result.map_error(fn(_) { "Failed to create dev directory" }),
  )
  Ok(Nil)
}

fn write_gleam_toml(name: String, cf_name: String) -> Result(Nil, String) {
  let today = "2025-01-01"
  let content =
    "name = \"" <> name <> "\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"
    <> "\n"
    <> "[dependencies]\n"
    <> "glare = \">= 0.1.0 and < 1.0.0\"\n"
    <> "gleam_stdlib = \">= 0.44.0 and < 2.0.0\"\n"
    <> "gleam_json = \">= 3.0.2 and < 4.0.0\"\n"
    <> "gleam_javascript = \">= 1.0.0 and < 2.0.0\"\n"
    <> "\n"
    <> "[dev_dependencies]\n"
    <> "gleeunit = \">= 1.0.0 and < 2.0.0\"\n"
    <> "\n"
    <> "[cloudflare]\n"
    <> "name = \"" <> cf_name <> "\"\n"
    <> "compatibility_date = \"" <> today <> "\"\n"
    <> "\n"
    <> "[cloudflare.bindings]\n"
  simplifile.write(to: name <> "/gleam.toml", contents: content)
  |> result.map_error(fn(_) { "Failed to write gleam.toml" })
}

fn write_handler(name: String) -> Result(Nil, String) {
  let content =
    "import glare.{type Context, type Env}\n"
    <> "import glare/response\n"
    <> "\n"
    <> "pub fn fetch(request, env: Env, ctx: Context) {\n"
    <> "  response.new(200)\n"
    <> "  |> response.set_body(\"Hello from " <> name <> "!\")\n"
    <> "  |> promise.resolve\n"
    <> "}\n"
  simplifile.write(to: name <> "/src/" <> name <> ".gleam", contents: content)
  |> result.map_error(fn(_) { "Failed to write handler" })
}

fn write_test(name: String) -> Result(Nil, String) {
  let content =
    "import gleeunit\n"
    <> "import gleeunit/should\n"
    <> "\n"
    <> "pub fn main() {\n"
    <> "  gleeunit.main()\n"
    <> "}\n"
    <> "\n"
    <> "pub fn hello_test() {\n"
    <> "  \"Hello\"\n"
    <> "  |> should.equal(\"Hello\")\n"
    <> "}\n"
  simplifile.write(to: name <> "/test/" <> name <> "_test.gleam", contents: content)
  |> result.map_error(fn(_) { "Failed to write test file" })
}

fn write_dev(name: String) -> Result(Nil, String) {
  let content =
    "import gleam/io\n"
    <> "\n"
    <> "pub fn main() {\n"
    <> "  io.println(\"Development mode\")\n"
    <> "}\n"
  simplifile.write(to: name <> "/dev/" <> name <> "_dev.gleam", contents: content)
  |> result.map_error(fn(_) { "Failed to write dev file" })
}

fn write_gitignore(name: String) -> Result(Nil, String) {
  let content =
    "build/\n"
    <> "node_modules/\n"
    <> ".dev.vars\n"
    <> ".wrangler/\n"
  simplifile.write(to: name <> "/.gitignore", contents: content)
  |> result.map_error(fn(_) { "Failed to write .gitignore" })
}
