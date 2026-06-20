import gleeunit
import gleeunit/should

import gleam/int
import gleam/list
import gleam/string
import simplifile
import glare/cli/handlers
import glare/cli/toml_utils

pub fn main() {
  gleeunit.main()
}

fn test_dir_name(n: Int) -> String {
  "./test_tmp_build_" <> int.to_string(n)
}

pub fn detect_handlers_from_compiled_gleam_test() {
  let mjs =
    "import { fetch } from \"./gleam.mjs\";\n"
    <> "\n"
    <> "export function fetch(request, env, ctx) {\n"
    <> "  return new Response(\"Hello!\");\n"
    <> "}\n"
  handlers.detect_handlers(mjs)
  |> should.equal(["fetch"])
}

pub fn detect_handlers_from_multiple_exports_test() {
  let mjs =
    "export function fetch(request, env, ctx) {\n"
    <> "  return new Response(\"ok\");\n"
    <> "}\n"
    <> "\n"
    <> "export function queue(batch, env, ctx) {\n"
    <> "  batch.messages.forEach(m => m.ack());\n"
    <> "}\n"
    <> "\n"
    <> "export async function scheduled(event, env, ctx) {\n"
    <> "  console.log(\"tick\");\n"
    <> "}\n"
  let result = handlers.detect_handlers(mjs)
  list.length(result)
  |> should.equal(3)
  list.contains(result, "fetch")
  |> should.be_true
  list.contains(result, "queue")
  |> should.be_true
  list.contains(result, "scheduled")
  |> should.be_true
}

pub fn detect_handlers_from_complex_mjs_test() {
  let mjs =
    "import * as $option from \"../../gleam_stdlib/gleam/option.mjs\";\n"
    <> "import { Some, None } from \"../../gleam_stdlib/gleam/option.mjs\";\n"
    <> "import { KvError } from \"../glare/error.mjs\";\n"
    <> "import { Ok, Error } from \"../gleam.mjs\";\n"
    <> "\n"
    <> "export function fetch(request, env, ctx) {\n"
    <> "  const cache = env[\"CACHE\"];\n"
    <> "  return cache.get(\"greeting\").then(value => {\n"
    <> "    if (value !== null) {\n"
    <> "      return new Response(value, { status: 200 });\n"
    <> "    }\n"
    <> "    return new Response(\"Hello!\", { status: 200 });\n"
    <> "  });\n"
    <> "}\n"
  handlers.detect_handlers(mjs)
  |> should.equal(["fetch"])
}

pub fn detect_handlers_no_false_positive_from_variable_names_test() {
  let mjs =
    "const fetchHandler = (req) => new Response(\"ok\");\n"
    <> "export default { fetch: fetchHandler };\n"
  handlers.detect_handlers(mjs)
  |> should.equal([])
}

pub fn detect_handlers_no_false_positive_from_object_keys_test() {
  let mjs =
    "export default {\n"
    <> "  fetch(request, env, ctx) {\n"
    <> "    return new Response(\"ok\");\n"
    <> "  },\n"
    <> "};\n"
  handlers.detect_handlers(mjs)
  |> should.equal([])
}

pub fn parse_realistic_gleam_toml_test() {
  let toml =
    "name = \"my_worker\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"
    <> "\n"
    <> "[dependencies]\n"
    <> "gleam_stdlib = \">= 1.0.0 and < 2.0.0\"\n"
    <> "glare = \">= 0.1.0 and < 1.0.0\"\n"
    <> "\n"
    <> "[cloudflare]\n"
    <> "name = \"my-worker\"\n"
    <> "compatibility_date = \"2025-01-01\"\n"
    <> "\n"
    <> "[cloudflare.bindings]\n"
    <> "kv = [\"CACHE\", \"SESSIONS\"]\n"
    <> "d1 = [\"DB\"]\n"
    <> "r2 = [\"ASSETS\"]\n"
    <> "queues_producers = [\"EVENTS\"]\n"
    <> "queues_consumers = [\"events\"]\n"
    <> "\n"
    <> "[cloudflare.vars]\n"
    <> "ENVIRONMENT = \"production\"\n"

  case toml_utils.parse_config(toml) {
    Ok(config) -> {
      config.package_name |> should.equal("my_worker")
      config.cloudflare.name |> should.equal("my-worker")
      config.cloudflare.compatibility_date |> should.equal("2025-01-01")
      config.cloudflare.bindings.kv |> should.equal(["CACHE", "SESSIONS"])
      config.cloudflare.bindings.d1 |> should.equal(["DB"])
      config.cloudflare.bindings.r2 |> should.equal(["ASSETS"])
      config.cloudflare.bindings.queues_producers
      |> should.equal(["EVENTS"])
      config.cloudflare.bindings.queues_consumers
      |> should.equal(["events"])
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_toml_with_durable_objects_test() {
  let toml =
    "name = \"my_worker\"\n"
    <> "\n"
    <> "[cloudflare]\n"
    <> "name = \"my-worker\"\n"
    <> "\n"
    <> "[[cloudflare.durable_objects.classes]]\n"
    <> "name = \"Counter\"\n"
    <> "module = \"my_worker/durable_objects/counter\"\n"
    <> "\n"
    <> "[[cloudflare.durable_objects.classes]]\n"
    <> "name = \"ChatRoom\"\n"
    <> "module = \"my_worker/durable_objects/chat_room\"\n"

  case toml_utils.parse_config(toml) {
    Ok(config) -> {
      config.cloudflare.durable_objects.classes
      |> list.length
      |> should.equal(2)
      let classes = config.cloudflare.durable_objects.classes
      case classes {
        [first, ..] -> {
          first.name |> should.equal("Counter")
          first.module |> should.equal("my_worker/durable_objects/counter")
        }
        [] -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn write_and_read_generated_entrypoint_test() {
  let dir = test_dir_name(1)
  let _ = simplifile.create_directory_all(dir)

  let entrypoint =
    "import * as handler from \"./my_worker.mjs\";\n"
    <> "\n"
    <> "const exports = {};\n"
    <> "\n"
    <> "  async fetch(...args) {\n"
    <> "    return handler.fetch(...args);\n"
    <> "  },\n"
    <> "\n"
    <> "export default exports;\n"

  let assert Ok(_) =
    simplifile.write(to: dir <> "/index.js", contents: entrypoint)

  let assert Ok(content) = simplifile.read(dir <> "/index.js")
  content
  |> string.contains("import * as handler from \"./my_worker.mjs\"")
  |> should.be_true
  content
  |> string.contains("export default exports")
  |> should.be_true

  let _ = simplifile.delete(dir)
}

pub fn write_and_read_generated_wrangler_test() {
  let dir = test_dir_name(2)
  let _ = simplifile.create_directory_all(dir)

  let wrangler =
    "name = \"my-worker\"\n"
    <> "main = \"./build/dist/bundle.js\"\n"
    <> "compatibility_date = \"2025-01-01\"\n"
    <> "\n"
    <> "[[kv_namespaces]]\n"
    <> "binding = \"CACHE\"\n"
    <> "id = \"abc-123\"\n"
    <> "\n"
    <> "[[d1_databases]]\n"
    <> "binding = \"DB\"\n"
    <> "database_name = \"my-worker-db\"\n"
    <> "database_id = \"xyz-789\"\n"

  let assert Ok(_) =
    simplifile.write(to: dir <> "/wrangler.toml", contents: wrangler)

  let assert Ok(content) = simplifile.read(dir <> "/wrangler.toml")
  content
  |> string.contains("name = \"my-worker\"")
  |> should.be_true
  content
  |> string.contains("[[kv_namespaces]]")
  |> should.be_true
  content
  |> string.contains("[[d1_databases]]")
  |> should.be_true

  let _ = simplifile.delete(dir)
}

pub fn full_pipeline_test() {
  let dir = test_dir_name(3)
  let _ = simplifile.create_directory_all(dir <> "/src")

  let gleam_toml =
    "name = \"pipeline_test\"\n"
    <> "version = \"1.0.0\"\n"
    <> "target = \"javascript\"\n"
    <> "\n"
    <> "[cloudflare]\n"
    <> "name = \"pipeline-test\"\n"
    <> "compatibility_date = \"2025-01-01\"\n"
    <> "\n"
    <> "[cloudflare.bindings]\n"
    <> "kv = [\"CACHE\"]\n"
    <> "d1 = [\"DB\"]\n"
  let assert Ok(_) =
    simplifile.write(to: dir <> "/gleam.toml", contents: gleam_toml)

  let assert Ok(content) = simplifile.read(dir <> "/gleam.toml")
  let assert Ok(config) = toml_utils.parse_config(content)

  config.package_name |> should.equal("pipeline_test")
  config.cloudflare.name |> should.equal("pipeline-test")
  config.cloudflare.bindings.kv |> should.equal(["CACHE"])
  config.cloudflare.bindings.d1 |> should.equal(["DB"])

  let mjs =
    "export function fetch(request, env, ctx) {\n"
    <> "  return new Response(\"ok\");\n"
    <> "}\n"
    <> "\n"
    <> "export function queue(batch, env, ctx) {\n"
    <> "  batch.messages.forEach(m => m.ack());\n"
    <> "}\n"
  let detected = handlers.detect_handlers(mjs)
  list.contains(detected, "fetch")
  |> should.be_true
  list.contains(detected, "queue")
  |> should.be_true

  let entrypoint =
    "import * as handler from \"./" <> config.package_name <> ".mjs\";\n"
    <> "export default { fetch: handler.fetch, queue: handler.queue };\n"
  let assert Ok(_) =
    simplifile.write(to: dir <> "/index.js", contents: entrypoint)

  let wrangler =
    "name = \"" <> config.cloudflare.name <> "\"\n"
    <> "main = \"./build/dist/bundle.js\"\n"
    <> "compatibility_date = \"" <> config.cloudflare.compatibility_date <> "\"\n"
  let assert Ok(_) =
    simplifile.write(to: dir <> "/wrangler.toml", contents: wrangler)

  let assert Ok(entrypoint_content) = simplifile.read(dir <> "/index.js")
  entrypoint_content
  |> string.contains("import * as handler from \"./pipeline_test.mjs\"")
  |> should.be_true

  let assert Ok(wrangler_content) = simplifile.read(dir <> "/wrangler.toml")
  wrangler_content
  |> string.contains("name = \"pipeline-test\"")
  |> should.be_true

  let _ = simplifile.delete(dir)
}
