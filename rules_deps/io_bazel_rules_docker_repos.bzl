# Load statement to configure optional client_config for authorized
# container_pull and container_push
load("@io_bazel_rules_docker//toolchains/docker:toolchain.bzl",
    docker_toolchain_configure="toolchain_configure"
)
load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

def repositories(use_client_config):
    # Only use custom client config if set to True by project
    # To use this client config a Bazel image with amazon-ecr-credential-helper is needed
    if use_client_config:
        # Configure the optional docker toolchain for authorized
        # container_pull and container_push rules
        docker_toolchain_configure(
            name = "docker_config",
            # Label to custom docker client config.json
            # See https://docs.docker.com/engine/reference/commandline/cli/#configuration-files and
            # https://github.com/awslabs/amazon-ecr-credential-helper for more details
            client_config="@shared_bazel_rules//ci/docker:config.json",
        )
    # Load further Docker repositories
    # Load container repositories for language rules, e.g. py_image, py3_image, java_image, go_image rules
    container_repositories()
