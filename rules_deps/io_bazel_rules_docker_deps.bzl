load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

def dependencies():
    # Load further Docker dependencies after container_repositories call
    # This is NOT needed when going through the language lang_image "repositories" function(s).
    # Needed for repository '@com_github_google_go_containerregistry'
    container_deps()
