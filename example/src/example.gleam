import glade.{start_server}
import web/index

@target(erlang)
pub fn main() {
  start_server([index.server])
}
