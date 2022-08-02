_GO_MOD="""
module %s

go 1.14

require (
  github.com/go-openapi/errors v0.19.9
  github.com/go-openapi/loads v0.19.7
  github.com/go-openapi/runtime v0.19.24
  github.com/go-openapi/spec v0.19.15
  github.com/go-openapi/strfmt v0.19.11
  github.com/go-openapi/swag v0.19.12
  github.com/go-openapi/validate v0.19.15
  github.com/jessevdk/go-flags v1.5.0
  golang.org/x/net v0.0.0-20201008222804-59f7323070c5
)
"""

_WORKSPACE_FILE="""
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "e0015762cdeb5a2a9c48f96fb079c6a98e001d44ec23ad4fa2ca27208c5be4fb",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.24.14/rules_go-v0.24.14.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.24.14/rules_go-v0.24.14.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()
go_register_toolchains(go_version = "1.15")

http_archive(
    name = "bazel_gazelle",
    sha256 = "222e49f034ca7a1d1231422cdb67066b885819885c356673cb1f72f748a3c9d4",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.3/bazel-gazelle-v0.22.3.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.3/bazel-gazelle-v0.22.3.tar.gz",
    ],
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")
gazelle_dependencies()
"""

def _swagger_generate_impl(ctx):
    _GO_ENV={
      "HOME": ctx.path(''),
      "PATH": "%s:%s" % (ctx.path(ctx.attr._go).dirname, ctx.path(ctx.which('bash')).dirname),
    }

    swagger = ctx.path(ctx.attr._swagger)
    input = ctx.path(ctx.attr.server_src)
    importpath = ctx.attr.importpath

    ctx.file("go.mod", content=_GO_MOD % importpath, executable=False)
    ctx.file("WORKSPACE", content=_WORKSPACE_FILE, executable=False)

    cmd = "%s generate server -P models.Principal -f %s -t %s --exclude-main" % (swagger, input, ".")
    cmds = ["bash", "-c", cmd]
    result = env_execute(ctx, cmds, environment={"GOPATH": ctx.path('')})
    if result.return_code:
        fail("failed to generate server go files for %s: %s" % (ctx.attr.importpath, result.stderr))

    for client_src in ctx.attr.client_srcs:
        input = ctx.path(client_src)
        cmd = "%s generate client -f %s -t %s " % (swagger, input, ".")
        cmds = ["bash", "-c", cmd]
        result = env_execute(ctx, cmds, environment={"GOPATH": ctx.path('')})
        if result.return_code:
            fail("failed to generate client go files for %s: %s" % (input, result.stderr))
        else:
            print("generated client go files for %s" % input)

    gazelle = ctx.path(ctx.attr._gazelle)
    cmd = "%s -go_prefix %s" % (gazelle, ctx.attr.importpath)
    cmds = ["bash", "-c", cmd]
    result = env_execute(ctx, cmds, environment=_GO_ENV)

    if result.stderr != "":
        print(" ".join(cmds))
        print(result.stderr)

    if result.return_code:
        fail("failed to generate BUILD files for %s: %s" % (ctx.attr.importpath, result.stderr))

    cmd = "%s update-repos --from_file=go.mod" % (gazelle)
    cmds = ["bash", "-c", cmd]
    result = env_execute(ctx, cmds, environment=_GO_ENV)

    if result.stderr != "":
        print(" ".join(cmds))
        print(result.stderr)

    if result.return_code:
        fail("failed to update deps for %s: %s" % (ctx.attr.importpath, result.stderr))

swagger_generated_repository = repository_rule(
    implementation = _swagger_generate_impl,
    attrs = {
        "server_src": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "client_srcs": attr.label_list(
            allow_empty = True,
            mandatory = True,
        ),
        "importpath": attr.string(
            mandatory = True
        ),
        "_swagger": attr.label(
            default = Label("@swagger_repository_tools//:bin/swagger"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
        "_gazelle": attr.label(
            default = Label("@bazel_gazelle_go_repository_tools//:bin/gazelle"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
        "_go": attr.label(
            default = Label("@go_sdk//:bin/go"),
            allow_single_file = True,
            executable = True,
            cfg = "host"
        )
    }
)

def env_execute(ctx, arguments, environment = None, **kwargs):
  """env_execute prepends "env -i" to "arguments" before passing it to
  ctx.execute.
  Variables that aren't explicitly mentioned in "environment"
  are removed from the environment. This should be preferred to "ctx.execute"
  in most situations.
  """
  env_args = ["env", "-i"]
  if environment:
    for k, v in environment.items():
      env_args += ["%s=%s" % (k, v)]

  return ctx.execute(env_args + arguments, **kwargs)
