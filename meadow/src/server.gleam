@target(erlang)
import gleam/bytes_builder
@target(erlang)
import gleam/dynamic
@target(erlang)
import gleam/erlang
@target(erlang)
import gleam/erlang/process
@target(erlang)
import gleam/float
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{None}
@target(erlang)
import gleam/result
@target(erlang)
import gleam/string
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import simplifile

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
        ["meadow", ..segments] -> serve_file(req, segments)
        segments -> serve_page(req, segments)
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

@target(erlang)
fn serve_page(
  _req: Request(Connection),
  path: List(String),
) -> Response(ResponseData) {
  let project_name =
    simplifile.current_directory()
    |> result.nil_error
    |> result.then(fn(dir) {
      dir
      |> string.split("/build")
      |> list.first
    })
    |> result.then(fn(dir) {
      dir
      |> string.split("/")
      |> list.last
    })
    |> result.nil_error
    |> result.unwrap("PROJECT_NAME_ERROR")
  let file_path = string.join(["meadow", project_name, "web", ..path], "/")
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.from_string("<!DOCTYPE html>
<html lang=\"en\">
    <head>
        <meta charset=\"UTF-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
        <title>Index</title>
        <script type=\"module\">
            import { client } from '/" <> file_path <> ".mjs'
            client()
        </script>
    </head>
    <body></body>
</html>
")))
  |> response.set_header("content-type", "text/html")
}

@target(erlang)
fn serve_file(
  _req: Request(Connection),
  path: List(String),
) -> Response(ResponseData) {
  let file_path = string.join(["build", "dev", "javascript", ..path], "/")
  simplifile.verify_is_file(file_path)
  |> result.nil_error
  |> result.then(fn(_) {
    mist.send_file(file_path, offset: 0, limit: None)
    |> result.nil_error
  })
  |> result.map(fn(file) {
    let content_type = get_content_type(file_path)
    response.new(200)
    |> response.prepend_header("content-type", content_type)
    |> response.set_body(file)
  })
  |> result.lazy_unwrap(fn() {
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
  })
}

@target(erlang)
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

@target(erlang)
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

@target(erlang)
fn get_content_type(file_path: String) -> String {
  case string.split(file_path, ".") {
    [_, ..extension] ->
      case
        extension
        |> list.last
      {
        Ok(extension) ->
          case
            extension
            |> string.lowercase
          {
            "aac" -> "audio/aac"
            "abw" -> "application/x-abiword"
            "apng" -> "image/apng"
            "arc" -> "application/x-freearc"
            "avif" -> "image/avif"
            "avi" -> "video/x-msvideo"
            "azw" -> "application/vnd.amazon.ebook"
            "bin" -> "application/octet-stream"
            "bmp" -> "image/bmp"
            "bz" -> "application/x-bzip"
            "bz2" -> "application/x-bzip2"
            "cda" -> "application/x-cdf"
            "csh" -> "application/x-csh"
            "css" -> "text/css"
            "csv" -> "text/csv"
            "doc" -> "application/msword"
            "docx" ->
              "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "eot" -> "application/vnd.ms-fontobject"
            "epub" -> "application/epub+zip"
            "gz" -> "application/gzip"
            "gif" -> "image/gif"
            "htm" -> "text/html"
            "html" -> "text/html"
            "ico" -> "image/vnd.microsoft.icon"
            "ics" -> "text/calendar"
            "jar" -> "application/java-archive"
            "jpeg" -> "image/jpeg"
            "jpg" -> "image/jpeg"
            "js" -> "text/javascript"
            "json" -> "application/json"
            "jsonld" -> "application/ld+json"
            "mid" -> "audio/midi"
            "midi" -> "audio/midi"
            "mjs" -> "text/javascript"
            "mp3" -> "audio/mpeg"
            "mp4" -> "video/mp4"
            "mpeg" -> "video/mpeg"
            "mpkg" -> "application/vnd.apple.installer+xml"
            "odp" -> "application/vnd.oasis.opendocument.presentation"
            "ods" -> "application/vnd.oasis.opendocument.spreadsheet"
            "odt" -> "application/vnd.oasis.opendocument.text"
            "oga" -> "audio/ogg"
            "ogv" -> "video/ogg"
            "ogx" -> "application/ogg"
            "opus" -> "audio/opus"
            "otf" -> "font/otf"
            "png" -> "image/png"
            "pdf" -> "application/pdf"
            "php" -> "application/x-httpd-php"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" ->
              "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "rar" -> "application/vnd.rar"
            "rtf" -> "application/rtf"
            "sh" -> "application/x-sh"
            "svg" -> "image/svg+xml"
            "tar" -> "application/x-tar"
            "tif" -> "image/tiff"
            "tiff" -> "image/tiff"
            "ts" -> "video/mp2t"
            "ttf" -> "font/ttf"
            "txt" -> "text/plain"
            "vsd" -> "application/vnd.visio"
            "wav" -> "audio/wav"
            "weba" -> "audio/webm"
            "webm" -> "video/webm"
            "webp" -> "image/webp"
            "woff" -> "font/woff"
            "woff2" -> "font/woff2"
            "xhtml" -> "application/xhtml+xml"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" ->
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "xml" -> "application/xml"
            "xul" -> "application/vnd.mozilla.xul+xml"
            "zip" -> "application/zip"
            ".3gp" -> "video/3gpp"
            ".3g2" -> "video/3gpp2"
            ".7z" -> "application/x-7z-compressed"
            _ -> "text/plain"
          }
        Error(_) -> "text/plain"
      }
    _ -> "text/plain"
  }
}
