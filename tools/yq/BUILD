sh_binary(
    name = "yq_binary",
    srcs = ["yq.sh"],
    data = select({
        "@bazel_tools//src/conditions:linux_x86_64": ["@yq//:allfiles"],
        "@bazel_tools//src/conditions:darwin": ["@yq_osx//:allfiles"],
    }),
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_library(
    name = "runfiles_bash",
    srcs = ["runfiles.bash"],
    visibility = ["//visibility:public"],
)
