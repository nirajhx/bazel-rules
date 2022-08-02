load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def helm_repositories():
    http_archive(
        name = "helm",
        sha256 = "07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262",
        urls = ["https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz"],
        build_file = "@shared_bazel_rules//ci/helm:helm.BUILD",
    )

    http_archive(
        name = "helm_osx",
        sha256 = "84a1ff17dd03340652d96e8be5172a921c97825fd278a2113c8233a4e8db5236",
        urls = ["https://get.helm.sh/helm-v3.6.3-darwin-amd64.tar.gz"],
        build_file = "@shared_bazel_rules//ci/helm:helm.BUILD",
    )

def helm_push_repositories():
    http_archive(
        name = "helm_push",
        sha256 = "4e76a3ac694961eb288b45303add120e31e57ae8c406e957ebcf002358f73c3e",
        urls = ["https://github.com/chartmuseum/helm-push/releases/download/v0.9.0/helm-push_0.9.0_linux_amd64.tar.gz"],
        build_file = "@shared_bazel_rules//ci/helm:helm_push.BUILD",
        patches = [ "@shared_bazel_rules//external:helm_push_local_install.patch" ],
    )

    http_archive(
        name = "helm_push_osx",
        sha256 = "a655a296744b40d3bcc0da360318e566ddad6de6996ac38fa1337bdbc0585f72",
        urls = ["https://github.com/chartmuseum/helm-push/releases/download/v0.9.0/helm-push_0.9.0_darwin_amd64.tar.gz"],
        build_file = "@shared_bazel_rules//ci/helm:helm_push.BUILD",
        patches = [ "@shared_bazel_rules//external:helm_push_local_install.patch" ],
    )
