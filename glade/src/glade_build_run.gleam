import shellout
import simplifile.{copy_directory, read, write, current_directory, get_files}
import gleam/result.{try, nil_error}
import gleam/io
import gleam/string
import gleam/list
import gleam/dict.{type Dict}

import glade_helpers.{try_msg, try_delete_dir, map_results, check}

const web_build_dir = "web_build"

pub fn build(web_dir) {
  // Build the web project
  io.println("Building gleam web project at " <> web_dir)
  use <- try_msg(
    shellout.command("gleam", ["build"], web_dir, []),
    "Couldn't build gleam web project",
  )
  use <- try_delete_dir(web_build_dir, "Couldn't delete old web build")
  use <- try_msg(
    copy_directory(web_dir <> "/build/dev/javascript", web_build_dir),
    "Coudln't copy web build to server",
  )
  use <- try_msg(
    shellout.command("gleam", ["clean"], web_dir, []),
    "Couldn't clean gleam web project",
  )
  use <- try_msg(
    bundle_pages(),
    "Couldn't bundle pages",
  )
  io.println("Web project built!")

  // Build the server project
  io.println("Building gleam server project")
  use <- try_msg(
    shellout.command("gleam", ["build"], ".", []),
    "Couldn't build gleam server project",
  )
  io.println("Server project built!")
  Ok(Nil)
}

pub fn run(web_dir) {
  use _ <- try(build(web_dir))
  Ok(Nil)
}

fn bundle_pages() {
  use current_dir <- try(current_directory() |> nil_error)
  use name <- try(current_dir |> string.split("/") |> list.last |> nil_error)

  let web_build_root_dir = web_build_dir <> "/" <> name <> "_web"

  use file <- map_results(get_files(web_build_root_dir))
  
  use filename <- try(file |> string.split("/") |> list.last |> nil_error)
  use ext <- try(filename |> string.split(".") |> list.last |> nil_error)
  use no_ext <- try(filename |> string.split(".") |> list.first |> nil_error)
  use <- check(no_ext != "gleam", Ok(Nil))
  use <- check(ext == "mjs", Ok(Nil))
  
  io.println("- Bundling " <> filename)

  use content <- result.try(read(file) |> nil_error)
  let props = content |> string.split("\n") |> list.filter_map(fn(line) {
    let parts = line |> string.split("=")
    use key <- try(list.first(parts))
    use value <- try(list.last(parts))
    case key {
      "export const " <> rest -> Ok(#(rest |> string.trim, value |> string.trim |> string.drop_left(1) |> string.drop_right(2)))
      _ -> Error(Nil)
    }
  }) |> dict.from_list

  io.println("  Writing html: " <> web_build_dir <> "/" <> no_ext <> ".html")
  write(web_build_dir <> "/" <> no_ext <> ".html", gen_html(props, name <> "_web/" <> filename)) |> nil_error
}

fn gen_html(props: Dict(String, String), js_filename: String) {
  "
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='UTF-8'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <title>" <> props |> dict.get("title") |> result.unwrap("No title") <> "</title>
  <script type='module'>
        import { run } from './" <> js_filename <> "';
        run()
    </script>
</head>
<body>
</body>
</html>
"
}
