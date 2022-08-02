# Push the container image first, then build the HelmChart
def _multi_impl(ctx):
    # Define inputs and manifests for Bazel
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools=[ctx.attr.container])
    tool_inputs_aws, tool_input_mfs_aws = ctx.resolve_tools(tools=[ctx.attr.aws_cli])

    # Declare temporary config.json file for Docker AWS ECR login
    docker_login_config = ctx.actions.declare_file("config.json")
    # Declare file for AWS CLI --debug used with '2>' for stderr
    aws_ecr_debug = ctx.actions.declare_file("aws_ecr_debug.txt")

    # Create custom Docker login and store result in config.json
    # Export directory of config.json file and run Bazel's Docker push rule to push Docker image to AWS ECR
    ctx.actions.run_shell(
        # ctx.files.aws_cli[0] is ci/aws/aws.py
        # ctx.files.aws_cli[1] is AWS CLI executable
        # ctx.files.container[0] is container_push digest
        # ctx.files.container[1] is container_push executable
        command="./" + ctx.file.docker_login.path + " " + ctx.files.aws_cli[1].path + " " + ctx.attr.aws_ecr_id + " > " + docker_login_config.path + " 2> " + aws_ecr_debug.path + " && export DOCKER_CONFIG=" + docker_login_config.dirname + " && ./" + ctx.files.container[1].path + " && cat " + ctx.files.container[0].path + " > \"" + ctx.outputs.container_out.path + "\"",
        inputs=ctx.files.container + ctx.files.aws_cli + ctx.files.docker_login,
        tools=depset(transitive=[tool_inputs, tool_inputs_aws]),
        input_manifests=tool_input_mfs + tool_input_mfs_aws,
        outputs=[ctx.outputs.container_out] + [aws_ecr_debug] + [docker_login_config],
        use_default_shell_env=True,
    )

    # Now build the helm chart, i.e. copy previously build HelmChart to final location
    ctx.actions.run_shell(
        command="cp " + ctx.files.chart[0].path + " " + ctx.outputs.chart_out.path,
        inputs=[ctx.files.chart[0]],
        outputs=[ctx.outputs.chart_out],
    )

multi = rule(
    attrs = {
        "container": attr.label(mandatory=True),
        "chart": attr.label(mandatory=True),
        "container_out": attr.output(mandatory=True),
        "chart_out": attr.output(mandatory=True),
        # aws_cli attr will create two files: source file 'aws.py' and binary file 'aws'
        "aws_cli": attr.label(default="@shared_bazel_rules//ci/aws:aws", allow_files=True),
        "docker_login": attr.label(default="@shared_bazel_rules//ci/aws:createDockerLogin.sh", allow_single_file=True),
        "aws_ecr_id": attr.string(default="420770559716")
    },
    implementation = _multi_impl
)
