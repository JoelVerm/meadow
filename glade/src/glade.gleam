import glare.{create_render, select}
import glare/element.{type Node, main}
import gleam/io
import gleam/list
import server

pub type Signal(a) {
  Signal(value: a, name: String)
}

@target(javascript)
pub fn html(node: List(Node)) {
  create_render(main(node), select("body"))
}

@target(erlang)
pub fn html(_) {
  Nil
}

@target(javascript)
@external(javascript, "./external.mjs", "server_signal")
pub fn server_signal(signal: Signal(a)) -> #(fn() -> a, fn(a) -> Nil)

@target(erlang)
pub fn server_signal(
  prev: List(server.Handler(a)),
  signal: Signal(a),
  handle: fn(a) -> a,
) -> List(server.Handler(a)) {
  [server.Signal(signal.name, signal.value, handle), ..prev]
}

@target(erlang)
pub fn start_server(
  routes: List(fn(List(server.Handler(Int))) -> List(server.Handler(Int))),
) -> Nil {
  routes
  |> list.fold([], fn(routes, route) { route(routes) })
  |> server.server
}

@target(javascript)
pub fn start_server(_) {
  Nil
}
