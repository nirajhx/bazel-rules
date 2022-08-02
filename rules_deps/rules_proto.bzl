# Protobuf rules
load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")

def dependencies():
    # Protobuf rules
    rules_proto_dependencies()
    rules_proto_toolchains()
