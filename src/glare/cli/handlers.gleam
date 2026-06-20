import gleam/list
import gleam/string

pub fn detect_handlers(mjs_content: String) -> List(String) {
  let handlers = ["fetch", "scheduled", "queue", "email", "tail", "alarm"]
  list.filter(handlers, fn(h) {
    string.contains(mjs_content, "export function " <> h <> "(")
    || string.contains(mjs_content, "export async function " <> h <> "(")
  })
}
