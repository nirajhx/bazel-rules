# Gazelle rules
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

def dependencies():
    gazelle_dependencies()
