import gleam/io
import shellout

import glade_new.{new}
import glade_build_run.{build, run}

const web_dir = "web"

pub fn main() {
  case shellout.arguments() {
    ["new"] -> new(web_dir)
    ["build"] -> build(web_dir)
    ["run"] -> run(web_dir)
    _ -> Ok(io.println("Usage: gleam run -m glade <command> [base_path]"))
  }
}
