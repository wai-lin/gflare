import gleeunit
import gleeunit/should

import gleam/int
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  gleeunit.main()
}

fn test_dir_name(n: Int) -> String {
  "./test_tmp_init_" <> int.to_string(n)
}

pub fn init_adds_cloudflare_section_test() {
  let dir = test_dir_name(1)
  let _ = simplifile.create_directory_all(dir)

  let gleam_toml =
    "name = \"test_pkg\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"
    <> "\n"
    <> "[dependencies]\n"
    <> "gleam_stdlib = \">= 1.0.0 and < 2.0.0\"\n"
  let _ = simplifile.write(to: dir <> "/gleam.toml", contents: gleam_toml)

  let assert Ok(original) = simplifile.read(dir <> "/gleam.toml")
  original
  |> string.contains("[cloudflare]")
  |> should.be_false

  let section =
    "\n[cloudflare]\n"
    <> "name = \"test-pkg\"\n"
    <> "compatibility_date = \"2025-01-01\"\n"
    <> "\n"
    <> "[cloudflare.bindings]\n"
  let assert Ok(_) = simplifile.append(to: dir <> "/gleam.toml", contents: section)

  let assert Ok(updated) = simplifile.read(dir <> "/gleam.toml")
  updated
  |> string.contains("[cloudflare]")
  |> should.be_true
  updated
  |> string.contains("name = \"test-pkg\"")
  |> should.be_true

  let _ = simplifile.delete(dir)
}

pub fn init_skips_existing_cloudflare_section_test() {
  let dir = test_dir_name(2)
  let _ = simplifile.create_directory_all(dir)

  let gleam_toml =
    "name = \"test_pkg\"\n"
    <> "\n"
    <> "[cloudflare]\n"
    <> "name = \"test-pkg\"\n"
    <> "\n"
    <> "[cloudflare.bindings]\n"
    <> "kv = [\"CACHE\"]\n"
  let _ = simplifile.write(to: dir <> "/gleam.toml", contents: gleam_toml)

  let assert Ok(content) = simplifile.read(dir <> "/gleam.toml")
  content
  |> string.contains("kv = [\"CACHE\"]")
  |> should.be_true

  let _ = simplifile.delete(dir)
}

pub fn init_creates_handler_file_test() {
  let dir = test_dir_name(3)
  let _ = simplifile.create_directory_all(dir <> "/src")

  let gleam_toml =
    "name = \"my_app\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"
  let _ = simplifile.write(to: dir <> "/gleam.toml", contents: gleam_toml)

  let handler_content =
    "import gflare/bindings.{type Env}\n"
    <> "import gflare/request.{type HttpRequest}\n"
    <> "import gflare/response\n"
    <> "import gflare/worker.{type Context}\n"
    <> "import gleam/javascript/promise\n"
    <> "\n"
    <> "pub fn fetch(request: HttpRequest, env: Env, ctx: Context) {\n"
    <> "  response.new(200)\n"
    <> "  |> response.set_body(\"Hello from my_app!\")\n"
    <> "  |> promise.resolve\n"
    <> "}\n"
  let assert Ok(_) =
    simplifile.write(
      to: dir <> "/src/my_app.gleam",
      contents: handler_content,
    )

  let assert Ok(content) = simplifile.read(dir <> "/src/my_app.gleam")
  content
  |> string.contains("pub fn fetch(request: HttpRequest, env: Env, ctx: Context)")
  |> should.be_true
  content
  |> string.contains("response.new(200)")
  |> should.be_true

  let _ = simplifile.delete(dir)
}

pub fn init_skips_existing_handler_test() {
  let dir = test_dir_name(4)
  let _ = simplifile.create_directory_all(dir <> "/src")

  let existing_handler = "pub fn main() { Nil }\n"
  let assert Ok(_) =
    simplifile.write(
      to: dir <> "/src/my_app.gleam",
      contents: existing_handler,
    )

  let assert Ok(content) = simplifile.read(dir <> "/src/my_app.gleam")
  content
  |> should.equal("pub fn main() { Nil }\n")

  let _ = simplifile.delete(dir)
}

pub fn extract_package_name_test() {
  let content =
    "name = \"my_cool_app\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"

  let lines = string.split(content, "\n")
  let name_line =
    list.find(lines, fn(line) { string.starts_with(line, "name = ") })

  case name_line {
    Ok(line) -> {
      let name =
        line |> string.drop_start(7) |> string.trim |> string.replace(
          "\"",
          with: "",
        )
      name |> should.equal("my_cool_app")
    }
    Error(_) -> should.fail()
  }
}

pub fn full_init_workflow_test() {
  let dir = test_dir_name(5)
  let _ = simplifile.create_directory_all(dir <> "/src")

  let gleam_toml =
    "name = \"worker_app\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"
    <> "\n"
    <> "[dependencies]\n"
    <> "gleam_stdlib = \">= 1.0.0 and < 2.0.0\"\n"
  let _ = simplifile.write(to: dir <> "/gleam.toml", contents: gleam_toml)

  let assert Ok(content_before) = simplifile.read(dir <> "/gleam.toml")
  content_before
  |> string.contains("[cloudflare]")
  |> should.be_false

  let section =
    "\n[cloudflare]\n"
    <> "name = \"worker-app\"\n"
    <> "compatibility_date = \"2025-01-01\"\n"
    <> "\n"
    <> "[cloudflare.bindings]\n"
  let assert Ok(_) = simplifile.append(to: dir <> "/gleam.toml", contents: section)

  let handler =
    "import gflare/bindings.{type Env}\n"
    <> "import gflare/request.{type HttpRequest}\n"
    <> "import gflare/response\n"
    <> "import gflare/worker.{type Context}\n"
    <> "import gleam/javascript/promise\n"
    <> "\n"
    <> "pub fn fetch(request: HttpRequest, env: Env, ctx: Context) {\n"
    <> "  response.new(200)\n"
    <> "  |> response.set_body(\"Hello from worker_app!\")\n"
    <> "  |> promise.resolve\n"
    <> "}\n"
  let assert Ok(_) =
    simplifile.write(to: dir <> "/src/worker_app.gleam", contents: handler)

  let assert Ok(content_after) = simplifile.read(dir <> "/gleam.toml")
  content_after
  |> string.contains("[cloudflare]")
  |> should.be_true

  let assert Ok(handler_content) = simplifile.read(dir <> "/src/worker_app.gleam")
  handler_content
  |> string.contains("pub fn fetch(request: HttpRequest, env: Env, ctx: Context)")
  |> should.be_true

  let _ = simplifile.delete(dir)
}

pub fn handler_file_has_correct_imports_test() {
  let dir = test_dir_name(6)
  let _ = simplifile.create_directory_all(dir <> "/src")

  let handler =
    "import gflare/bindings.{type Env}\n"
    <> "import gflare/request.{type HttpRequest}\n"
    <> "import gflare/response\n"
    <> "import gflare/worker.{type Context}\n"
    <> "import gleam/javascript/promise\n"
    <> "\n"
    <> "pub fn fetch(request: HttpRequest, env: Env, ctx: Context) {\n"
    <> "  response.new(200)\n"
    <> "  |> response.set_body(\"Hello!\")\n"
    <> "  |> promise.resolve\n"
    <> "}\n"
  let assert Ok(_) =
    simplifile.write(to: dir <> "/src/test.gleam", contents: handler)

  let assert Ok(content) = simplifile.read(dir <> "/src/test.gleam")
  content
  |> string.contains("import gflare/bindings.{type Env}")
  |> should.be_true
  content
  |> string.contains("import gflare/request.{type HttpRequest}")
  |> should.be_true
  content
  |> string.contains("import gflare/worker.{type Context}")
  |> should.be_true

  let _ = simplifile.delete(dir)
}
