_GO_SWAGGER_REPOSITORY_TOOLS_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "swagger",
    srcs = ["bin/swagger"],
)
"""

def _swagger_repository_tools_impl(ctx):
    if ctx.os.name == 'linux':
        swagger_url = "https://github.com/go-swagger/go-swagger/releases/download/v0.23.0/swagger_linux_amd64"
        swagger_sha256 = "a5426295a292bee85faa141ea8b76279fdf0a32817aeb5a0d0b51a16eeb3918d"
    elif ctx.os.name == 'mac os x':
        swagger_url = "https://github.com/go-swagger/go-swagger/releases/download/v0.23.0/swagger_darwin_amd64"
        swagger_sha256 = "33ba534fe16ae4084f25326954e296dd2d7fabd110d7b68c1be0a849a365b140"
    else:
        fail("Unsupported operating system: " + ctx.os.name)

    ctx.download(swagger_url, 'bin/swagger', swagger_sha256, executable=True)
    ctx.file('BUILD', _GO_SWAGGER_REPOSITORY_TOOLS_BUILD_FILE, False)

swagger_repository_tools = repository_rule(_swagger_repository_tools_impl)

def swagger_tool_repository():
    swagger_repository_tools(name = "swagger_repository_tools")
