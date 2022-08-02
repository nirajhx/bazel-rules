# Package rules
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

def dependencies():
    # Package rules
    rules_pkg_dependencies()
