# Load Bazel Docker rules repositories
load("@shared_bazel_rules//rules_deps:io_bazel_rules_docker_repos.bzl", io_bazel_rules_docker_repos = "repositories")

def dependencies(use_client_config = False):
    # Load Docker repositories
    # Only load container_repositories because container_repositories and container_deps must be loaded in separate files,
    # i.e. container_repositories must be executed first in repository context
    io_bazel_rules_docker_repos(use_client_config)
