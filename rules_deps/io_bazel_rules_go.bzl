# Go(lang) rules
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

def dependencies(version = None):
    go_rules_dependencies()

    # go_register_toolchains currently supports new version attribute and legacy go_version attribute
    # go_register_toolchains sets version attribute as fallback if go_version attribute is set
    # Therefore use go_version for compatibility between new and old rule versions
    go_register_toolchains(go_version = version)
