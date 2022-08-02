sh_binary(
    name = "helm_binary",
    srcs = ["helm.sh"],
    data = select({
        "@bazel_tools//src/conditions:linux_x86_64": ["@helm//:allfiles", "@helm_push//:allfiles_push"],
        "@bazel_tools//src/conditions:darwin": ["@helm_osx//:allfiles", "@helm_push_osx//:allfiles_push"],
    }),
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_library(
    name = "runfiles_bash",
    srcs = ["runfiles.bash"],
    visibility = ["//visibility:public"],
)
