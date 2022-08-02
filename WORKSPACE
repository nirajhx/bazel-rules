# WORKSPACE name is important for Helm sh lookup with rlocation
workspace(name = "shared_bazel_rules")

# --- General Bazel rules for shared tools and ci folder
# Load the HTTP downloader
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# The following external rules are always loaded and can be uses as described by official documentation:
# io_bazel_rules_docker - https://github.com/bazelbuild/rules_docker
# bazel_skylib - https://github.com/bazelbuild/bazel-skylib
# Configuration of needed rules by load_rules
load_rules = [
    # Please add the following lines for bazel_gazelle after initial setup:
    # load("@shared_bazel_rules//rules_deps:bazel_gazelle.bzl", bazel_gazelle_deps = "dependencies")
    # bazel_gazelle_deps()
    #"bazel_gazelle",
    # Please add the following lines for bazel_toolchains after initial setup:
    # load("@shared_bazel_rules//rules_deps:bazel_toolchains.bzl", bazel_toolchains_deps = "dependencies")
    # bazel_toolchains_deps()
    #"bazel_toolchains",
    # No further setup for build_bazel_rules_nodejs required
    #"build_bazel_rules_nodejs",
    # Please add the following lines for io_bazel_rules_go after initial setup:
    # load("@shared_bazel_rules//rules_deps:io_bazel_rules_go.bzl", io_bazel_rules_go_deps = "dependencies")
    # io_bazel_rules_go_deps()
    #"io_bazel_rules_go",
    # Please add the following lines for openapi_tools_generator_bazel after initial setup:
    # load("@shared_bazel_rules//rules_deps:openapi_tools_generator_bazel.bzl", openapi_tools_generator_bazel_deps = "dependencies")
    # openapi_tools_generator_bazel_deps()
    #"openapi_tools_generator_bazel",
    # No further setup for openjdk11_linux_archive required
    #"openjdk11_linux_archive",
    # No further setup for rules_jvm_external required
    #"rules_jvm_external",
    # Please add the following lines for rules_pkg after initial setup:
    # load("@shared_bazel_rules//rules_deps:rules_pkg.bzl", rules_pkg_deps = "dependencies")
    # rules_pkg_deps()
    "rules_pkg",
    # Please add the following lines for rules_proto after initial setup:
    # load("@shared_bazel_rules//rules_deps:rules_proto.bzl", rules_proto_deps = "dependencies")
    # rules_proto_deps()
    #"rules_proto",
    # No further setup for rules_python required
    "rules_python",
    # No further setup for rules_spring required
    #"rules_spring",
    # No further setup for vwni_go_swagger required
    #"vwni_go_swagger",
    # No further setup for vwni_junit5 required
    #"vwni_junit5",
]

# Load Bazel repositories based on load_rules
load("@shared_bazel_rules//:repositories.bzl", "shared_bazel_rules_dependencies")
shared_bazel_rules_dependencies(load_rules)
# Load dependencies of Bazel repositories that are always required
load("@shared_bazel_rules//rules_deps:vwni.bzl", vwni_deps = "dependencies")
vwni_deps(use_client_config = False)
load("@shared_bazel_rules//rules_deps:io_bazel_rules_docker_deps.bzl", io_bazel_rules_docker_deps = "dependencies")
io_bazel_rules_docker_deps()
# End of always required part
# Further dependencies according to comments in load_rules
load("@shared_bazel_rules//rules_deps:rules_pkg.bzl", rules_pkg_deps = "dependencies")
rules_pkg_deps()

# This rule translates the specified requirements.txt into
# @my_deps//:requirements.bzl, which can be used in BUILD file.
load("@rules_python//python:pip.bzl", "pip_install")
pip_install(
    name = "awscli_deps",
    requirements = "//ci/aws:requirements.txt",
)

# Load py_image Docker rule instead of pulling the Python Docker base images
# py_image can be used in BUILD file by loading py_image rule and rewrite py_binary to py_image
# Python2 legacy
load(
    "@io_bazel_rules_docker//python:image.bzl",
    _py_image_repos = "repositories",
)

_py_image_repos()

# Load py3_image for Python3
load(
    "@io_bazel_rules_docker//python3:image.bzl",
    _py3_image_repos = "repositories",
)

_py3_image_repos()

# Load go_image Docker rule instead of pulling the Go Docker base images
# go_image can be used in BUILD file by loading and using go_image rule
# Notice that it is important to explicitly build this target with the --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64
# flag as the binary should be built for Linux since it will run in a Linux container.
load(
    "@io_bazel_rules_docker//go:image.bzl",
    _go_image_repos = "repositories",
)

_go_image_repos()
