def _ecr_push(ctx):
    # Push the container image first
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools=[ctx.attr.container])
    tool_inputs_aws, tool_input_mfs_aws = ctx.resolve_tools(tools=[ctx.attr.aws_cli])

    ctx.actions.run_shell(
        command="mkdir -p $(pwd)/docker && ./" + ctx.files.docker_login[0].path + " " + ctx.files.aws_cli[1].path + " " + ctx.attr.aws_ecr_id + " >> $(pwd)/docker/config.json && export DOCKER_CONFIG=$(pwd)/docker/ && ./" + ctx.files.container[1].path + " && cat " + ctx.files.container[0].path + " > \"" + ctx.outputs.container_out.path + "\"",
        inputs=[ctx.files.container[1]] + ctx.files.aws_cli + ctx.files.docker_login,
        tools=depset(transitive=[tool_inputs, tool_inputs_aws]),
        input_manifests=tool_input_mfs + tool_input_mfs_aws,
        outputs=[ctx.outputs.container_out],
        use_default_shell_env=True)

ecr_push = rule(
    attrs = {
        "container": attr.label(mandatory=True),
        "container_out": attr.output(mandatory=True),
        "aws_cli": attr.label(default="//ci/aws:aws", allow_files=True),
        "docker_login": attr.label(default="//ci/aws:createDockerLogin.sh", allow_single_file=True),
        "aws_ecr_id": attr.string(default="420770559716")
    },
    implementation = _ecr_push
)
