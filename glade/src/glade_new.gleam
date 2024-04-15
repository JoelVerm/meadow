import simplifile.{write, current_directory}
import shellout
import gleam/io
import gleam/string
import gleam/list
import gleam/result.{try, nil_error}

import glade_helpers.{try_msg, try_delete_dir, try_delete_file}

pub fn new(web_dir) {
  io.println("Scaffolding glade project...")
  use current_dir <- try(current_directory() |> nil_error)
  use name <- try(current_dir |> string.split("/") |> list.last |> nil_error)
  io.println("Project name: " <> name)

  // Core project
  use <- try_msg(
    shellout.command("gleam", ["add", "glade_server"], ".", []),
    "Couldn't add server dependencies",
  )
  use <- try_msg(
    server_gleam()
      |> write(to: "src/" <> name <> ".gleam"),
    "Couldn't write server gleam file",
  )
  use <- try_delete_dir("test", "Couldn't delete test directory")
  use <- try_delete_dir(".github", "Couldn't delete github directory")

  // Web project
  use <- try_msg(
    shellout.command("gleam", ["new", web_dir], ".", []),
    "Couldn't create web project",
  )
  use <- try_msg(
    web_toml(name)
      |> write(to: web_dir <> "/gleam.toml"),
    "Couldn't write web gleam.toml file",
  )
  use <- try_msg(
    shellout.command("gleam", ["add", "gleam_stdlib", "glare", "glade_web"], web_dir, []),
    "Couldn't add web dependencies",
  )
  use <- try_msg(
    web_gleam()
      |> write(to: web_dir <> "/src/index.gleam"),
    "Couldn't write index page gleam file",
  )
  use <- try_delete_file(web_dir <> "/src/web.gleam", "Couldn't delete default gleam file")
  use <- try_delete_dir(web_dir <> "/test", "Couldn't delete test directory")
  use <- try_delete_dir(web_dir <> "/.github", "Couldn't delete github directory")
  io.println("Web project created!")
  Ok(Nil)
}

fn web_toml(name) {
  "name = \"" <> name <> "_web\"
version = \"1.0.0\"

target = \"javascript\"

[dependencies]"
}

fn web_gleam() {
  "// title: Index - Example

import glare/element.{type Node, button, div, header, main, p}
import glare/property.{attr, class, font_family, size, style}
import glare/event.{onclick}
import glare.{create_render, select, signal, text}
import glare/hooks.{create_signal}
import gleam/io

pub fn body() -> Node {
  let #(count, set_count) = create_signal(0)

  main([
    header([
      p([text(\"Title\")])
      |> font_family(\"Arial\")
      |> size(\"1.5rem\")
      |> class(\"title\"),
      p([text(\"A Subtitle with text\")])
      |> font_family(\"Roboto\")
      |> size(\"1.1rem\"),
    ]),
    p([
      text(
        \"Facilis vel quia atque voluptatem voluptas ipsum deserunt sunt. Est veritatis facilis et sit. Necessitatibus rerum eveniet impedit dolores velit magni autem qui\",
      ),
    ])
    |> style(\"border-radius\", \"16px\")
    // add custom styling
    |> attr(\"data-summary\", \"this is a random paragraph\"),
    // custom attributes
    p([text(\"count: \"), signal(count)]),
    // state using solid-js signals
    button([text(\"click me\")])
    |> onclick(fn() {
      io.println(\"clicked\")
      set_count(count() + 1)
    }),
    div([text(\"some content\")]),
  ])
}

pub fn run() {
  create_render(body(), select(\"body\"))
}"
}

fn server_gleam() {
  "import glade_server.{start}

pub fn main() {
  start()
}"
}
