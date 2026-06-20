import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn hello_test() {
  "Hello"
  |> should.equal("Hello")
}
