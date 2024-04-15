import simplifile.{delete, verify_is_directory, verify_is_file}
import gleam/io
import gleam/list
import gleam/result

pub fn try_msg(result: Result(a, b), msg: String, fun: fn() -> Result(c, Nil)) {
  case result {
    Ok(_) -> fun()
    Error(_) -> {
      io.println_error(msg)
      Error(Nil)
    }
  }
}

pub fn try_delete_dir(path, msg, fun) {
  try_msg(case verify_is_directory(path) {
      Ok(True) -> delete(path)
      Ok(False) -> Ok(Nil)
      Error(e) -> Error(e)
    }, msg, fun)
}

pub fn try_delete_file(path, msg, fun) {
  try_msg(case verify_is_file(path) {
      Ok(True) -> delete(path)
      Ok(False) -> Ok(Nil)
      Error(e) -> Error(e)
    }, msg, fun)
}

pub fn map_results(result: Result(List(a), b), fun: fn(a) -> Result(c, d)) { // -> Result(List(c), Nil) {
  case result {
    Ok(e) -> e |> list.map(fun) |> result.all |> result.nil_error
    Error(_) -> Error(Nil)
  }
}

pub fn check(bool, default, fun) {
  case bool {
    True -> fun()
    False -> default
  }
}
