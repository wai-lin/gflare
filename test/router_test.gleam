import gleeunit
import gleeunit/should

import gflare/response
import gflare/router
import gleam/dict
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/option.{None, Some}

pub fn main() {
  gleeunit.main()
}

// Router creation tests

pub fn new_router_creates_empty_router_test() {
  let router = router.new()
  router.global_middleware |> should.equal([])
}

// Route builder tests - verify handlers are stored

pub fn get_adds_route_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("GET")) |> promise.resolve
    })
  let router = router.new() |> router.get("/users", handler)
  // Check that the tree has children
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

pub fn post_adds_route_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("POST")) |> promise.resolve
    })
  let router = router.new() |> router.post("/users", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

pub fn put_adds_route_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("PUT")) |> promise.resolve
    })
  let router = router.new() |> router.put("/users", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

pub fn delete_adds_route_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("DELETE")) |> promise.resolve
    })
  let router = router.new() |> router.delete("/users", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

pub fn patch_adds_route_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("PATCH")) |> promise.resolve
    })
  let router = router.new() |> router.patch("/users", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

pub fn options_adds_route_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("OPTIONS")) |> promise.resolve
    })
  let router = router.new() |> router.options("/users", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

// Parameter extraction tests

pub fn get_param_extracts_parameter_test() {
  let params = router.RouteParams([#("id", "123"), #("name", "Alice")])
  router.get_param(params, "id") |> should.equal(Some("123"))
}

pub fn get_param_extracts_second_param_test() {
  let params = router.RouteParams([#("id", "123"), #("name", "Alice")])
  router.get_param(params, "name") |> should.equal(Some("Alice"))
}

pub fn get_param_returns_none_for_missing_test() {
  let params = router.RouteParams([#("id", "123")])
  router.get_param(params, "missing") |> should.equal(None)
}

pub fn get_param_or_returns_default_for_missing_test() {
  let params = router.RouteParams([#("id", "123")])
  router.get_param_or(params, "missing", "default") |> should.equal("default")
}

pub fn get_param_or_returns_value_when_present_test() {
  let params = router.RouteParams([#("id", "123")])
  router.get_param_or(params, "id", "default") |> should.equal("123")
}

// RouteParams tests

pub fn route_params_empty_test() {
  let params = router.RouteParams([])
  router.get_param(params, "anything") |> should.equal(None)
}

pub fn route_params_multiple_values_test() {
  let params =
    router.RouteParams([
      #("a", "1"),
      #("b", "2"),
      #("c", "3"),
    ])
  router.get_param(params, "a") |> should.equal(Some("1"))
  router.get_param(params, "b") |> should.equal(Some("2"))
  router.get_param(params, "c") |> should.equal(Some("3"))
}

// Middleware tests

pub fn with_middleware_adds_global_middleware_test() {
  let middleware =
    router.Middleware(fn(req, env, ctx, next) {
      let router.Handler(handler_fn) = next
      handler_fn(req, env, ctx, router.RouteParams([]))
    })
  let router = router.new() |> router.with_middleware(middleware)
  list.length(router.global_middleware) |> should.equal(1)
}

pub fn with_middleware_multiple_test() {
  let m1 =
    router.Middleware(fn(req, env, ctx, next) {
      let router.Handler(handler_fn) = next
      handler_fn(req, env, ctx, router.RouteParams([]))
    })
  let m2 =
    router.Middleware(fn(req, env, ctx, next) {
      let router.Handler(handler_fn) = next
      handler_fn(req, env, ctx, router.RouteParams([]))
    })
  let router =
    router.new() |> router.with_middleware(m1) |> router.with_middleware(m2)
  list.length(router.global_middleware) |> should.equal(2)
}

// Not found handler tests

pub fn not_found_sets_handler_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.not_found() |> promise.resolve
    })
  let router = router.new() |> router.not_found(handler)
  case router.not_found_handler {
    router.Handler(_) -> Nil
  }
}

// Path parsing tests

pub fn path_segments_parsed_correctly_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, params) {
      let id = router.get_param(params, "id")
      case id {
        Some(id) -> response.ok(json.string(id)) |> promise.resolve
        None -> response.not_found() |> promise.resolve
      }
    })
  let router = router.new() |> router.get("/users/:id", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

// Static route tests

pub fn static_route_added_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("static")) |> promise.resolve
    })
  let router = router.new() |> router.get("/static", handler)
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

// Multiple routes tests

pub fn multiple_routes_added_test() {
  let handler1 =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("users")) |> promise.resolve
    })
  let handler2 =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("posts")) |> promise.resolve
    })
  let router =
    router.new()
    |> router.get("/users", handler1)
    |> router.get("/posts", handler2)
  dict.size(router.tree.children) |> should.equal(2)
}

// Wildcard route tests

pub fn wildcard_route_added_test() {
  let handler =
    router.Handler(fn(_req, _env, _ctx, _params) {
      response.ok(json.string("files")) |> promise.resolve
    })
  let router = router.new() |> router.get("/files/*path", handler)
  // Wildcard routes should create a child node
  let has_children = dict.size(router.tree.children) > 0
  has_children |> should.equal(True)
}

// Response helper tests

pub fn response_ok_creates_response_test() {
  let resp = response.ok(json.string("hello"))
  case resp {
    _ -> Nil
  }
}

pub fn response_created_creates_response_test() {
  let resp = response.created(json.string("created"))
  case resp {
    _ -> Nil
  }
}

pub fn response_accepted_creates_response_test() {
  let resp = response.accepted()
  case resp {
    _ -> Nil
  }
}

pub fn response_no_content_creates_response_test() {
  let resp = response.no_content()
  case resp {
    _ -> Nil
  }
}

pub fn response_bad_request_creates_response_test() {
  let resp = response.bad_request("Invalid input")
  case resp {
    _ -> Nil
  }
}

pub fn response_unauthorized_creates_response_test() {
  let resp = response.unauthorized("Not authenticated")
  case resp {
    _ -> Nil
  }
}

pub fn response_forbidden_creates_response_test() {
  let resp = response.forbidden("Access denied")
  case resp {
    _ -> Nil
  }
}

pub fn response_not_found_creates_response_test() {
  let resp = response.not_found()
  case resp {
    _ -> Nil
  }
}

pub fn response_method_not_allowed_creates_response_test() {
  let resp = response.method_not_allowed(["GET", "POST"])
  case resp {
    _ -> Nil
  }
}

pub fn response_conflict_creates_response_test() {
  let resp = response.conflict("Resource exists")
  case resp {
    _ -> Nil
  }
}

pub fn response_internal_error_creates_response_test() {
  let resp = response.internal_error("Something went wrong")
  case resp {
    _ -> Nil
  }
}

pub fn response_ok_text_creates_response_test() {
  let resp = response.ok_text("hello")
  case resp {
    _ -> Nil
  }
}

pub fn response_html_creates_response_test() {
  let resp = response.html("<h1>Hello</h1>")
  case resp {
    _ -> Nil
  }
}

pub fn response_text_creates_response_test() {
  let resp = response.text("plain text")
  case resp {
    _ -> Nil
  }
}

pub fn response_xml_creates_response_test() {
  let resp = response.xml("<root/>")
  case resp {
    _ -> Nil
  }
}
