# Glade

A server side for glare, the web framework based on SolidJS, adding server signals and more.

## Installation

Create a new gleam project and install glare and glade.

```sh
gleam new my-project
cd my-project

# Install glare and glade
gleam add glare
gleam add glade
```

## Usage

Create a new file `src/my-project.gleam` and add the following code:

```gleam
import glade.{start_server}
import web/index

@target(erlang)
pub fn main() {
  start_server([index.server])
}
```

Create a new file `src/web/index.gleam` and add the following code:

```gleam
import glade.{html, server_signal}
import glare.{signal, text}
import glare/element.{button, header, p}
import glare/event.{onclick}
import glare/property.{class, font_family, size}
import gleam/io
import gleam/int

const count_signal = glade.Signal(0, "index-count")

@target(javascript)
pub fn client() {
  let #(count, set_count) = server_signal(count_signal)

  html([
    header([
      p([text("Title")])
      |> font_family("Arial")
      |> size("1.5rem")
      |> class("title"),
    ]),
    p([text("count: "), signal(count)]),
    button([text("click me")])
      |> onclick(fn() {
      io.println("clicked")
      set_count(count() + 1)
    }),
  ])
}

@target(erlang)
pub fn server(s) {
  s
  |> server_signal(count_signal, fn(a) {
    io.println("count: " <> int.to_string(a))
    a + 2
  })
}
```

## Running the server

```sh
gleam build -t=js && gleam run
```

This first builds the JavaScript frontend and then runs the Erlang server.
