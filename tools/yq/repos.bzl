load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def yq_repositories():
    http_archive(
        name = "yq",
        sha256 = "a03f74637632f533205161f7bf7ec719c8743b46e2a2caa91c66a030d74a6b6a",
        urls = ["https://github.com/mikefarah/yq/releases/download/v4.9.8/yq_linux_amd64.tar.gz"],
        build_file = "@shared_bazel_rules//tools/yq:yq.BUILD",
    )

    http_archive(
        name = "yq_osx",
        sha256 = "db247bbf206f3a671beeb09577360a54c7aa7d669b57ff2cfcd1ea3663c94874",
        urls = ["https://github.com/mikefarah/yq/releases/download/v4.9.8/yq_darwin_amd64.tar.gz"],
        build_file = "@shared_bazel_rules//tools/yq:yq.BUILD",
    )
