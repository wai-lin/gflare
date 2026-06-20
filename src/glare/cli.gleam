import argv
import glint
import glare/cli/build
import glare/cli/init

pub fn main() {
  let app =
    glint.new()
    |> glint.with_name("glare")
    |> glint.as_module
    |> glint.global_help("Zero-glue Gleam framework for Cloudflare Workers")
    |> glint.add(at: [], do: build_command())
    |> glint.add(at: ["init"], do: init_command())
    |> glint.add(at: ["build"], do: build_command())
    |> glint.add(at: ["dev"], do: dev_command())
    |> glint.add(at: ["deploy"], do: deploy_command())

  let args = argv.load().arguments
  glint.run(app, args)
}

fn init_command() {
  use <- glint.command_help("Create a new Cloudflare Workers project")
  use name <- glint.named_arg("project name")
  use named, _, _ <- glint.command()
  let project_name = name(named)
  init.run(project_name)
}

fn build_command() {
  use <- glint.command_help("Build for Cloudflare Workers")
  use _, _, _ <- glint.command()
  build.run(deploy: False, dev: False)
}

fn dev_command() {
  use <- glint.command_help("Build and start local dev server")
  use _, _, _ <- glint.command()
  build.run(deploy: False, dev: True)
}

fn deploy_command() {
  use <- glint.command_help("Build and deploy to Cloudflare")
  use _, _, _ <- glint.command()
  build.run(deploy: True, dev: False)
}
