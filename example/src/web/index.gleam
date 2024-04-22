import glade.{html, server_signal}
import glare.{signal, text}
import glare/element.{button, header, p}
import glare/event.{onclick}
import glare/property.{class, font_family, size}
import gleam/io

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
  |> server_signal(count_signal, fn(a) { a + 10 })
}
