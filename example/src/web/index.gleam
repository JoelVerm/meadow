import glare.{signal, text}
import glare/element.{button, header, p}
import glare/event.{onclick}
import glare/property.{class, font_family, size}
import gleam/int
import gleam/io
import meadow.{html, server_signal}

const count_signal = meadow.Signal(0, "index-count")

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
