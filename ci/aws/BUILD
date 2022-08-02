exports_files(["createDockerLogin.sh"])

package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_binary")
load("@awscli_deps//:requirements.bzl", "requirement")

# load Python pip rule to create/update requirements_lock.txt file for pip_parse rule
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

# This rule adds a convenient way to update the requirements file.
# To update, run: bazel run //ci/aws:requirements.update
compile_pip_requirements(
    name = "requirements",
    extra_args = ["--allow-unsafe"],
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
)

py_binary(
    name = "aws",
    srcs = ["aws.py"],
    main = "aws.py",
    python_version = "PY3",
    deps = [
        requirement("awscli"),
        requirement("six"),
        requirement("pyasn1"),
    ],
    legacy_create_init = False,
)
