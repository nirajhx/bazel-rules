# Load Bazel RBE toolchains
load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")

def dependencies():
    # Creates a default toolchain config for RBE.
    # Use this as is if you are using the rbe_ubuntu16_04 container,
    # otherwise refer to RBE docs.
    rbe_autoconfig(
        name = "rbe_default",
    )
