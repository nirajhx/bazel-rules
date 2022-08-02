# This is the same as the multi rule but without custom AWS-CLI login
# Login is performed by rules_docker with AWS ECR credentials helper
# Therefore all dependencies like Python, AWS-CLI, createDockerLogin.sh are removed

# Push the container image first, then build the HelmChart
def _docker_helm_push_impl(ctx):
    # Define inputs and manifests for Bazel
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools=[ctx.attr.container])

    # Run Bazel's Docker push rule to push Docker image to AWS ECR and copy container digest to Bazel's output
    ctx.actions.run_shell(
        # ctx.files.container[0] is container_push digest
        # ctx.files.container[1] is container_push executable
        command="./" + ctx.files.container[1].path + " && cat " + ctx.files.container[0].path + " > " + ctx.outputs.container_out.path,
        inputs=ctx.files.container,
        tools=tool_inputs,
        input_manifests=tool_input_mfs,
        outputs=[ctx.outputs.container_out],
        use_default_shell_env=True,
    )

    # Now build the helm chart, i.e. copy previously build HelmChart to final location
    ctx.actions.run_shell(
        command="cp " + ctx.files.chart[0].path + " " + ctx.outputs.chart_out.path,
        inputs=[ctx.files.chart[0]],
        outputs=[ctx.outputs.chart_out],
    )

docker_helm_push = rule(
    attrs = {
        "container": attr.label(mandatory=True),
        "chart": attr.label(mandatory=True),
        "container_out": attr.output(mandatory=True),
        "chart_out": attr.output(mandatory=True),
    },
    implementation = _docker_helm_push_impl
)
