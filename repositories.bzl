"""
shared_bazel_rules dependencies that can be imported into other WORKSPACE files
"""

# Load http_archive rule from built-in Bazel rules
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
# Load git_repository rule from built-in Bazel rules
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
# JUnit5 for Bazel
load("@shared_bazel_rules//tools/junit5:junit5.bzl", "junit_jupiter_java_repositories", "junit_platform_java_repositories")
# Load Helm and Helm push binary
load("@shared_bazel_rules//ci/helm:repos.bzl", "helm_repositories", "helm_push_repositories")
# Load yq for Helm to patch build_info into Helm .Values file
load("@shared_bazel_rules//tools/yq:repos.bzl", "yq_repositories")
# Go-Swagger
load("@shared_bazel_rules//tools/swagger:repository.bzl", "swagger_tool_repository")

RULES_JVM_EXTERNAL_TAG = "4.2"
RULES_JVM_EXTERNAL_SHA = "cd1a77b7b02e8e008439ca76fd34f5b07aecb8c752961f9640dea15e9e5ba1ca"

UNNECESSARY_RULES_TEXT = "Bazel rule '{}' is always loaded and can removed from shared_bazel_rules_dependencies()."

AVAILABLE_RULES = [
    "bazel_gazelle",
    "bazel_skylib",
    "bazel_toolchains",
    "build_bazel_rules_nodejs",
    "io_bazel_rules_docker",
    "io_bazel_rules_go",
    "openapi_tools_generator_bazel",
    "openjdk11_linux_archive",
    "rules_jvm_external",
    "rules_pkg",
    "rules_proto",
    "rules_python",
    "rules_spring",
    "vwni_go_swagger",
    "vwni_junit5",
]

def shared_bazel_rules_dependencies(load_rules):
    # Load all existing rules currently instantiated in this thread's package
    excludes = native.existing_rules().keys()

    ### Checks for unknown rules

    unknown_rules = []
    # Starlark doesn't support Sets, i.e. iterate list elements
    for element in load_rules:
        if element not in AVAILABLE_RULES:
            unknown_rules.append(element)

    # Check and fail if a unknown rule should be loaded
    if len(unknown_rules) > 0:
        fail("Some rules are not available:\n{}\n".format(unknown_rules) +
            "Please contact TeamGray to add these rules to the shared Bazel rules or add them manually to your WORKSPACE file. " +
            "Available rules: \n{}".format(AVAILABLE_RULES))

    ### Warnings for redundant rules that are always loaded

    # Pring debug message for io_bazel_rules_docker
    if "io_bazel_rules_docker" in load_rules:
        print(UNNECESSARY_RULES_TEXT.format("io_bazel_rules_docker"))
    # Pring debug message for io_bazel_rules_docker
    if "bazel_skylib" in load_rules:
        print(UNNECESSARY_RULES_TEXT.format("bazel_skylib"))

    ### Permanent rules that are always needed for @shared_bazel_rules

    # Always load Docker rules for container_image() and container_push()
    # General Docker rules
    # Download the rules_docker repository at release v0.21.0
    if "io_bazel_rules_docker" not in excludes:
        http_archive(
            name = "io_bazel_rules_docker",
            sha256 = "27d53c1d646fc9537a70427ad7b034734d08a9c38924cc6357cc973fed300820",
            strip_prefix = "rules_docker-0.24.0",
            urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.24.0/rules_docker-v0.24.0.tar.gz"],
        )

    # Bazel Skylib rules which contain common and useful functions and rules
    # Currently used in OpenAPI Generator for paths.join() and Helm rules
    # Load before Helm rules
    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            ],
            sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
        )

    # Always load binaries helm, helm_push and yq for internal Helm rules
    # Load Helm and Helm push binary
    helm_repositories()
    helm_push_repositories()
    # Load yq to patch Helm .Values file for build_info
    yq_repositories()

    ### Individual rules loaded independently by the project

    # Bazel Toolchains rules for Remote Execution, should match version of Bazel binary
    if "bazel_toolchains" not in excludes and "bazel_toolchains" in load_rules:
        http_archive(
            name = "bazel_toolchains",
            sha256 = "882fecfc88d3dc528f5c5681d95d730e213e39099abff2e637688a91a9619395",
            strip_prefix = "bazel-toolchains-3.4.0",
            urls = [
                "https://github.com/bazelbuild/bazel-toolchains/releases/download/3.4.0/bazel-toolchains-3.4.0.tar.gz",
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/releases/download/3.4.0/bazel-toolchains-3.4.0.tar.gz",
            ],
        )

    if "openjdk11_linux_archive" not in excludes and "openjdk11_linux_archive" in load_rules:
        http_archive(
            name = "openjdk11_linux_archive",
            build_file_content = "java_runtime(name = 'runtime', srcs =  glob(['**']), visibility = ['//visibility:public'])",
            sha256 = "cd807601c93d2e9c0e524b251d277da0add8026c4a7fb9908c72dcc19135edc6",
            strip_prefix = "zulu11.33.15-ca-jdk11.0.4-linux_x64",
            urls = [
                "https://cdn.azul.com/zulu/bin/zulu11.33.15-ca-jdk11.0.4-linux_x64.tar.gz",
            ],
        )

    # Bazel Java rules
    if "rules_jvm_external" not in excludes and "rules_jvm_external" in load_rules:
        http_archive(
            name = "rules_jvm_external",
            sha256 = RULES_JVM_EXTERNAL_SHA,
            strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
            url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
        )

    # Bazel Spring Boot rules
    if "rules_spring" not in excludes and "rules_spring" in load_rules:
        http_archive(
            name = "rules_spring",
            sha256 = "9385652bb92d365675d1ca7c963672a8091dc5940a9e307104d3c92e7a789c8e",
            urls = [
                 "https://github.com/salesforce/rules_spring/releases/download/2.1.4/rules-spring-2.1.4.zip",
            ],
        )

    # Bazel Python rules
    if "rules_python" not in excludes and "rules_python" in load_rules:
        # rules_python 0.4.0 is the latest release compatible with Bazel 3.x
        http_archive(
            name = "rules_python",
            sha256 = "cdf6b84084aad8f10bf20b46b77cb48d83c319ebe6458a18e9d2cebf57807cdd",
            strip_prefix = "rules_python-0.8.1",
            url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.8.1.tar.gz",
        )

    # Bazel OpenAPI Generator rules
    if "openapi_tools_generator_bazel" not in excludes and "openapi_tools_generator_bazel" in load_rules:
        # Load OpenAPI Generator
        git_repository(
            name = "openapi_tools_generator_bazel",
            shallow_since = "1605563603 -0700",
            commit = "337cb050ba164791cf7d158066b5a209c05061c0",
            remote = "https://github.com/OpenAPITools/openapi-generator-bazel.git",
        )

    # Package rules
    if "rules_pkg" not in excludes and "rules_pkg" in load_rules:
        http_archive(
            name = "rules_pkg",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.4.0/rules_pkg-0.4.0.tar.gz",
                "https://github.com/bazelbuild/rules_pkg/releases/download/0.4.0/rules_pkg-0.4.0.tar.gz",
            ],
            sha256 = "038f1caa773a7e35b3663865ffb003169c6a71dc995e39bf4815792f385d837d",
        )

    # Bazel Protobuf rules
    if "rules_proto" not in excludes and "rules_proto" in load_rules:
        http_archive(
            name = "rules_proto",
            sha256 = "9fc210a34f0f9e7cc31598d109b5d069ef44911a82f507d5a88716db171615a8",
            strip_prefix = "rules_proto-f7a30f6f80006b591fa7c437fe5a951eb10bcbcf",
            urls = [
              "https://github.com/bazelbuild/rules_proto/archive/f7a30f6f80006b591fa7c437fe5a951eb10bcbcf.tar.gz",
            ],
        )

    # Note for Go(lang) with Gazelle rules:
    # See https://github.com/bazelbuild/bazel-gazelle#compatibility-with-rules-go for compatibility between rules
    # io_bazel_rules_go >= v0.26.0 requires Bazel >= 3.5.0 and
    # bazel_gazelle isn't compatible with io_bazel_rules_go = v0.25.x
    # therefore use io_bazel_rules_go v0.24.x with bazel_gazelle v0.22.x unless Bazel >= 3.5.0 is supported by VWNI

    # Bazel Go(lang) rules
    if "io_bazel_rules_go" not in excludes and "io_bazel_rules_go" in load_rules:
        http_archive(
            name = "io_bazel_rules_go",
            sha256 = "f2dcd210c7095febe54b804bb1cd3a58fe8435a909db2ec04e31542631cf715c",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.31.0/rules_go-v0.31.0.zip",
                "https://github.com/bazelbuild/rules_go/releases/download/v0.31.0/rules_go-v0.31.0.zip",
            ],
        )

    # Bazel Gazelle rules
    if "bazel_gazelle" not in excludes and "bazel_gazelle" in load_rules:
        http_archive(
            name = "bazel_gazelle",
            sha256 = "5982e5463f171da99e3bdaeff8c0f48283a7a5f396ec5282910b9e8a49c0dd7e",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.25.0/bazel-gazelle-v0.25.0.tar.gz",
                "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.25.0/bazel-gazelle-v0.25.0.tar.gz",
            ],
        )

    # Bazel NodeJS rules
    if "build_bazel_rules_nodejs" not in excludes and "build_bazel_rules_nodejs" in load_rules:
        http_archive(
            name = "build_bazel_rules_nodejs",
            sha256 = "4a5d654a4ccd4a4c24eca5d319d85a88a650edf119601550c95bf400c8cc897e",
            urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/3.5.1/rules_nodejs-3.5.1.tar.gz"],
        )

    # Go-Swagger for Bazel
    if "vwni_go_swagger" in load_rules:
        swagger_tool_repository()

    # JUnit5 for Bazel
    if "vwni_junit5" in load_rules:
        JUNIT_JUPITER_VERSION = "5.7.1"

        JUNIT_PLATFORM_VERSION = "1.7.1"

        junit_jupiter_java_repositories(
            version = JUNIT_JUPITER_VERSION,
        )

        junit_platform_java_repositories(
            version = JUNIT_PLATFORM_VERSION,
        )
