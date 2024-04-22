import gleam/bytes_builder
import gleam/dynamic
import gleam/erlang
import gleam/erlang/process
import gleam/float
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}

pub type Handler(a) {
  Signal(name: String, initial_value: a, handler: fn(a) -> a)
}

@target(erlang)
pub fn server(handlers: List(Handler(a))) {
  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["server-signal", name, value] ->
          case list.find(handlers, fn(h) { h.name == name }) {
            Error(_) -> not_found
            Ok(handler) -> handle_server_signal(value, handler)
          }
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

fn handle_server_signal(
  request_string: String,
  handler: Handler(a),
) -> Response(ResponseData) {
  {
    use request_value <- result.try(decode_string(request_string, handler))
    let response_value = handler.handler(request_value)
    let response_string = erlang.format(response_value)
    let r =
      response.new(200)
      |> response.set_body(
        mist.Bytes(bytes_builder.from_string(response_string)),
      )
      |> response.set_header("Access-Control-Allow-Origin", "*")
    // TODO remove header
    Ok(r)
  }
  |> result.lazy_unwrap(fn() {
    response.new(400)
    |> response.set_body(
      mist.Bytes(bytes_builder.from_string("Invalid server signal call")),
    )
    |> response.set_header("Access-Control-Allow-Origin", "*")
  }// TODO remove header
  )
}

fn decode_string(request_string: String, handler: Handler(a)) -> Result(a, Nil) {
  case
    dynamic.from(handler.initial_value)
    |> dynamic.classify
  {
    "Bool" ->
      { request_string == "true" }
      |> dynamic.from
      |> Ok
    "Int" ->
      int.parse(request_string)
      |> result.map(dynamic.from)
    "Float" ->
      float.parse(request_string)
      |> result.map(dynamic.from)
    "List" ->
      Ok(dynamic.from(
        request_string
        |> string.drop_left(1)
        |> string.drop_right(1)
        |> string.split(",")
        |> list.map(string.trim)
        |> list.map(decode_string(_, handler)),
      ))
    "String" -> Ok(dynamic.from(request_string))
    _ -> Error(Nil)
  }
  |> result.map(dynamic.unsafe_coerce)
}
