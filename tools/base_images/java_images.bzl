# Load the function which pulls images from docker registries
load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
)

# Docker rules for own container creation
# Load container_run_and_commit Bazel rule
load("@io_bazel_rules_docker//docker/util:run.bzl", "container_run_and_commit")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")

# load pkg_tar rule
load("@rules_pkg//:pkg.bzl", "pkg_tar")

# load Docker download_pkgs and install_pkgs rule for distroless package install
load("@io_bazel_rules_docker//docker/package_managers:install_pkgs.bzl", "install_pkgs")
load("@io_bazel_rules_docker//docker/package_managers:download_pkgs.bzl", "download_pkgs")

# Please use load_java11_bazel instead. This is only needed for distroless package install
# and therefore load_java11_bazel with Bazel rule container_run_and_commit is recommended.
def load_java11_distroless():
    download_pkgs(
        name = "additional_pkgs",
        image_tar = "@openjdk_11_jre_official//image",
        packages = ["vim", "nano", "curl", "gzip", "awscli"],
    )

    install_pkgs(
        name = "openjdk_11_jre_distroless_vwni",
        image_tar = "@openjdk_11_jre_official//image",
        installables_tar = ":additional_pkgs.tar",
        # use installation_cleanup_commands for sed file manipulation and deletion of apt cache
        installation_cleanup_commands = "rm -rf /var/lib/apt/lists/*; sed -i 's/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/g' /usr/local/openjdk-11/conf/security/java.security",
        output_image_name = "openjdk_11_jre_distroless_vwni",
    )

# Get/Pull the Java Docker base images modified by our Dockerfile and pushed to our ECR
# Java 8
def java8_vwni():
    container_pull(
        name = "java8_vwni",
        registry = "420770559716.dkr.ecr.eu-central-1.amazonaws.com",
        repository = "vwn-infrastructure/docker-image-java-8",
        tag = "v2.0",
    )

# Java 11
def java11_vwni():
    container_pull(
        name = "java11_vwni",
        registry = "420770559716.dkr.ecr.eu-central-1.amazonaws.com",
        repository = "vwn-infrastructure/docker-image-java11",
        digest = "sha256:45e6e2cc17d1c7da22e7e2c612cf274e1218e8c2bd7b12952e996b76bbfeeced",
    )

# Robot Framework
def robot_framework_vwni():
    container_pull(
        name = "robot_framework_vwni",
        registry = "420770559716.dkr.ecr.eu-central-1.amazonaws.com",
        repository = "vwn-infrastructure/docker-image-robot-framework",
        tag = "ccfdaf950ae7ec5f09712b5d8f0a62aaaceea6f1",
    )

# Get/Pull the Java Docker official images going to modified by Bazel
# Java 8 Docker official image
def java8():
    container_pull(
        name = "java8",
        registry = "index.docker.io",
        repository = "openjdk:8-jre",
        digest = "sha256:dccc4cc9e816e069236c14ec24146add51d67d28b0e642e5dab8d7a04b08868a",
    )

# Java 11 Docker official image
def java11():
    container_pull(
        name = "java11",
        registry = "index.docker.io",
        repository = "openjdk:11-jre",
        digest = "sha256:9ae294fb6d88187c742e57f6e57ad018426304b02dc61f1f184341eeb4f46151",
    )

# Same .tar file for Java8 and Java11 base image
def vwni_pkg_tar():
    pkg_tar(
        name = "image_copy_files",
        # The file are located under /external/shared_bazel_rules/tools/base_images/scripts/
        # if strip_prefix is incorrectly used. Therefore strip directory from files.
        strip_prefix = "/external/shared_bazel_rules/tools/base_images/scripts/",
        # Do NOT use package_dir in this rule because already used by container_image rule below
        srcs = [
            "@shared_bazel_rules//tools/base_images/scripts/bin:dumpToS3.sh",
            "@shared_bazel_rules//tools/base_images/scripts/bin:entrypoint.sh",
            "@shared_bazel_rules//tools/base_images/scripts/bin:java",
            "@shared_bazel_rules//tools/base_images/scripts/bin/debug:java",
            "@shared_bazel_rules//tools/base_images/scripts/debug/etc:jmx_prometheus_config.yaml",
        ],
    )

# Get/Pull Java Docker base image for VWNI Docker Bazel rules
# Java8 Docker base image
def load_java8_bazel():
    # Use Bazel container_run_and_commit rule equivalent to Dockfile RUN command
    # Updated Java8 container image
    container_run_and_commit(
        name = "openjdk_8_jre_updated",
        commands = [
            "sed -i 's/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/g' /usr/local/openjdk-8/lib/security/java.security",
            "apt-get update",
            "apt-get install --yes vim nano curl gzip awscli",
            # Install jmx prometheus exporter on separate port 8040:
            # Add JAVA_OPTS="-javaagent:/opt/debug/lib/jmx_prometheus_javaagent-0.12.0.jar=8040:/opt/debug/etc/jmx_prometheus_config.yaml $JAVA_OPTS"
            "mkdir -p /opt/debug/lib /opt/debug/etc",
            "curl https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.12.0/jmx_prometheus_javaagent-0.12.0.jar -o /opt/debug/lib/jmx_prometheus_javaagent-0.12.0.jar",
        ],
        image = "@openjdk_8_jre_official//image",
    )

    vwni_pkg_tar()

    #Java8 VWNI image
    container_image(
        name = "openjdk_8_jre_vwni",
        base = ":openjdk_8_jre_updated",
        directory = "/opt/",
        tars = [
            ":image_copy_files",
        ],
        # The behavior between using "" and [] may differ.
        # Please see [#1448](https://github.com/bazelbuild/rules_docker/issues/1448) for more details.
        entrypoint = ["/opt/bin/entrypoint.sh"],
        visibility = ["//visibility:public"],
    )

# Java11 Docker base image
def load_java11_bazel():
    # Use Bazel container_run_and_commit rule equivalent to Dockfile RUN command
    # Updated Java11 container image
    container_run_and_commit(
        name = "openjdk_11_jre_updated",
        commands = [
            # For Java 11 the file is located in:
            # /usr/local/openjdk-11/conf/security/java.security
            "sed -i 's/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/g' /usr/local/openjdk-11/conf/security/java.security",
            "apt-get update",
            "apt-get install --yes vim nano curl gzip awscli",
            # Install jmx prometheus exporter on separate port 8040:
            # Add JAVA_OPTS="-javaagent:/opt/debug/lib/jmx_prometheus_javaagent-0.12.0.jar=8040:/opt/debug/etc/jmx_prometheus_config.yaml $JAVA_OPTS"
            "mkdir -p /opt/debug/lib /opt/debug/etc",
            "curl https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.12.0/jmx_prometheus_javaagent-0.12.0.jar -o /opt/debug/lib/jmx_prometheus_javaagent-0.12.0.jar",
        ],
        image = "@openjdk_11_jre_official//image",
    )

    vwni_pkg_tar()

    #Java11 VWNI image
    container_image(
        name = "openjdk_11_jre_vwni",
        base = ":openjdk_11_jre_updated",
        directory = "/opt",
        tars = [
            ":image_copy_files",
        ],
        # The behavior between using "" and [] may differ.
        # Please see [#1448](https://github.com/bazelbuild/rules_docker/issues/1448) for more details.
        entrypoint = ["/opt/bin/entrypoint.sh"],
        visibility = ["//visibility:public"],
    )
