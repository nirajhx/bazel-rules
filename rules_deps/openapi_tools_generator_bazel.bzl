# OpenAPI Generator
load("@openapi_tools_generator_bazel//:defs.bzl", "openapi_tools_generator_bazel_repositories")

def dependencies():
    # OpenAPI Generator
    # You can provide any version of the CLI that has been uploaded to Maven
    openapi_tools_generator_bazel_repositories(
        openapi_generator_cli_version = "5.0.1",
        sha256 = "e4e45d5441283b2f0f4bf988d02186b85425e7b708b4be0b06e3bfd7c7aa52c7"
    )
