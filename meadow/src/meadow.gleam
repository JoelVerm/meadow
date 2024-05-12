import glare.{create_render, select}
import glare/element.{type Node, main}
import gleam/io
import gleam/list
import server

/// This type is used to have the signal available both on the client and the server.
/// Just provide an initial value and a fun name.
/// The name should start with the path to the page you are working on.
/// The name can only contain alphanumeric characters and dashes.
pub type Signal(a) {
  Signal(value: a, name: String)
}

/// ### JavaScript:
/// Render the Glare code to the body of the page.
/// ### Erlang:
/// Does nothing, but is provided for ease of use.
/// This makes sure you don't need the `@target(javascript)` annotation.
@target(javascript)
pub fn html(node: List(Node)) {
  create_render(main(node), select("body"))
}

@target(erlang)
pub fn html(_) {
  Nil
}

/// ### Erlang:
/// Initialize the signal on the server side.
/// This function is called by piping the argument of the `server` method to it.
/// It also takes a handler function that should return the new value of the signal.
/// 
/// Call it like this: `s |> server_signal(count_signal, fn(a) { a + 1 })`
/// 
/// ### JavaScript:
/// `pub fn server_signal(signal: Signal(a)) -> #(fn() -> a, fn(a) -> Nil)`
/// Initialize the signal on the client side.
/// Returns a get and set function in that order.
/// 
/// Call it like this: `let #(count, set_count) = server_signal(count_signal)`
@target(erlang)
pub fn server_signal(
  prev: List(server.Handler(a)),
  signal: Signal(a),
  handle: fn(a) -> a,
) -> List(server.Handler(a)) {
  [server.Signal(signal.name, signal.value, handle), ..prev]
}

@target(javascript)
@external(javascript, "./external.mjs", "server_signal")
pub fn server_signal(signal: Signal(a)) -> #(fn() -> a, fn(a) -> Nil)

/// ### Erlang:
/// Start the server.
/// This should be the only function called from the main function.
/// Its argument should be a list of all the `server` functions in your project.
/// ### JavaScript:
/// Does nothing, but is provided for ease of use.
/// This makes sure you don't need the `@target(erlang)` annotation.
@target(javascript)
pub fn start_server(_) {
  Nil
}

@target(erlang)
pub fn start_server(
  routes: List(fn(List(server.Handler(Int))) -> List(server.Handler(Int))),
) -> Nil {
  routes
  |> list.fold([], fn(routes, route) { route(routes) })
  |> server.server
}
