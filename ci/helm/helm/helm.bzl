load("@bazel_skylib//lib:paths.bzl", "paths")

HELM_CMD_PREFIX = """
echo "#!/usr/bin/env bash" > $@
cat $(location @shared_bazel_rules//ci/helm:runfiles_bash) >> $@
echo "export NAMESPACE=$$(grep NAMESPACE bazel-out/stable-status.txt | cut -d ' ' -f 2)" >> $@
echo "export BUILD_USER=$$(grep BUILD_USER bazel-out/stable-status.txt | cut -d ' ' -f 2)" >> $@
cat <<EOF >> $@

platform=\\$$(uname)
if [ "\\$$platform" == "Darwin" ]; then
    BINARY=\\$$(rlocation helm_osx/darwin-amd64/helm)
elif [ "\\$$platform" == "Linux" ]; then
    BINARY=\\$$(rlocation helm/linux-amd64/helm)
else
    echo "Helm does not have a binary for \\$$platform"
    exit 1
fi

HELM_HOME="\\$$(pwd)/.helm"
PATH="\\$$(dirname \\$$BINARY):\\$$PATH"

# Remove local repo to increase reproducibility and remove errors
\\$$BINARY repo list | grep -qc local && \\$$BINARY repo remove local >/dev/null

cd "\\$${BUILD_WORKING_DIRECTORY:-}"
"""

STAMP_ATTRIBUTE_FAIL_TEXT = "The %s attribute of the helm_chart rule only support stamp variables and must start and end with '{' and '}'"

def check_no_stamp_attribute(attribute_value):
    if attribute_value and (not attribute_value.startswith("{") or not attribute_value.endswith("}")):
        return True
    return False

def _helm_chart_impl(ctx):
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools=[ctx.attr.helm_package])
    app_version = ctx.attr.app_version
    commit_id = ctx.attr.commit_id
    branch_name = ctx.attr.branch_name

    # Check if commit_id and branch_name contain proper stamp variables if set
    if check_no_stamp_attribute(commit_id):
        fail(STAMP_ATTRIBUTE_FAIL_TEXT % ("commit_id"))
    if check_no_stamp_attribute(branch_name):
        fail(STAMP_ATTRIBUTE_FAIL_TEXT % ("branch_name"))

    stamp = "{" in app_version or "{" in commit_id or "{" in branch_name
    # ctx.info_file contains all keys with STABLE_
    # ctx.version_file contains all volatile keys, i.e. rest of the keys
    stamp_inputs = [ctx.info_file] if stamp else []

    inputs = [] + ctx.attr.helm_package.files.to_list()
    for src in ctx.attr.srcs:
        inputs += src.files.to_list()

    for dep in ctx.files.deps:
        inputs += [dep]

    versions = ""

    if stamp:
        inputs += stamp_inputs
        version_parts = []
        for f in stamp_inputs:
            version_parts += [f.path]

        versions += ",".join(version_parts)

    package_flags = ""
    if ctx.attr.update_deps:
        package_flags += "--dependency-update"

    chart = "missing"
    dep_charts = []

    for f in ctx.files.deps:
        if ".tar.gz" in f.path:
            dep_charts += [f.path]

    for f in ctx.attr.srcs:
        if "Chart.yaml" in f.files.to_list()[0].path:
            chart = f.files.to_list()[0].path

    if app_version.startswith("{") and app_version.endswith("}"):
        app_version_stamped = "true"
        app_version = app_version[1:-1]
    else:
        app_version_stamped = "false"

    ctx.actions.run_shell(
        inputs = inputs,
        tools=tool_inputs,
        input_manifests=tool_input_mfs,
        outputs = [ctx.outputs.chart_out],
        command = "CHART=" + chart +
                  " DEPS=" + ",".join(dep_charts) +
                  " OUTPUT=" + ctx.outputs.chart_out.path +
                  " FLAGS=" + package_flags +
                  " VERSION_FILES=" + versions +
                  " APP_VERSION=" + app_version + # Normal value or stamped variable
                  " APP_VERSION_STAMPED=" + app_version_stamped +
                  # Pass stamp variable names without { and } to bash script
                  " COMMIT_ID_VAR_NAME=" + commit_id[1:-1] + # Only stamp variables
                  " BRANCH_NAME_VAR_NAME=" + branch_name[1:-1] + # Only stamp variables
                  " ./" + ctx.files.helm_package[1].path,
        #env = {
        #    "CHART": chart,
        #    "DEPS": ",".join(dep_charts),
        #    "OUTPUT": ctx.outputs.chart_out.path,
        #    "FLAGS": package_flags,
        #    "VERSION_FILES": versions,
        #},
        # Use default shell env due to pass of --action_env from Jenkins Pipeline
        # --action_env is only working with use_default_shell_env=True
        # env attribute is only working with default use_default_shell_env=False
        # Therefore pass env variables as command to shell
        use_default_shell_env = True,
    )

def _helm_push_impl(ctx):
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools=[ctx.attr.helm_push])

    inputs = [] + ctx.attr.helm_push.files.to_list() + [ctx.files.chart[0]]

    ctx.actions.run_shell(
        inputs = inputs,
        tools=tool_inputs,
        input_manifests=tool_input_mfs,
        outputs = [ctx.outputs.push_result],
        command = "./" + ctx.files.helm_push[1].path + " " + ctx.files.chart[0].path + " " + ctx.outputs.push_result.path,
        #env = {
        #    "CHART": ctx.files.chart[0].path,
        #    "REPOSITORY_URL": ctx.attr.repository_url,
        #},
        # Use default shell env due to pass of --action_env from Jenkins Pipeline
        use_default_shell_env = True,
    )

def _helm_fetch_impl(ctx):
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools=[ctx.attr.helm_fetch])

    stamp = "{" in ctx.attr.version
    stamp_inputs = [ctx.version_file] if stamp else []

    inputs = [] + ctx.attr.helm_fetch.files.to_list()
    versions = ""

    if stamp:
        inputs += stamp_inputs
        version_parts = []
        for f in stamp_inputs:
            version_parts += [f.path]

        versions += ",".join(version_parts)

    ctx.actions.run_shell(
        inputs = inputs,
        tools=tool_inputs,
        input_manifests=tool_input_mfs,
        outputs = [ctx.outputs.chart_out],
        command = "./" + ctx.files.helm_fetch[1].path,
        env = {
            "CHART": ctx.attr.chart,
            "REPOSITORY": ctx.attr.repository,
            "VERSION": ctx.attr.version,
            "OUTPUT": ctx.outputs.chart_out.path,
            "VERSION_FILES": versions,
        }
    )

_rule_helm_chart = rule(
    attrs = {
        "srcs": attr.label_list(allow_files=True, mandatory=True),
        "update_deps": attr.bool(default=False),
        "deps": attr.label_list(allow_files=True),
        "app_version": attr.string(default="1"),
        "chart_out": attr.output(mandatory=True),
        "helm_package": attr.label(mandatory=True, allow_files=True),
        "commit_id": attr.string(),
        "branch_name": attr.string(),
    },
    implementation = _helm_chart_impl
)

_rule_helm_push = rule(
    attrs = {
      "chart": attr.label(allow_single_file = True, mandatory = True),
      "push_result": attr.output(mandatory = True),
      "helm_push": attr.label(mandatory=True, allow_files=True),
    },
    implementation = _helm_push_impl,
    doc = "Push helm chart to a helm repository",
)

_rule_helm_fetch = rule(
    attrs = {
        "repository": attr.string(mandatory=True),
        "chart": attr.string(mandatory=True),
        "version": attr.string(default="^0.0"),
        "chart_out": attr.output(mandatory=True),
        "helm_fetch": attr.label(mandatory=True, allow_files=True),
    },
    implementation = _helm_fetch_impl
)

def helm_chart(name, srcs, update_deps = False, deps = [], app_version = "1", commit_id = "", branch_name = ""):
    _helm_cmd("package", [], name, "@shared_bazel_rules//ci/helm/helm:helm_package.sh")

    _rule_helm_chart(
        name = name,
        srcs = srcs,
        deps = deps,
        update_deps = update_deps,
        app_version = app_version,
        chart_out = "%s_chart.tar.gz" % name,
        helm_package = "%s.package" % name,
        commit_id = commit_id,
        branch_name = branch_name,
    )

def helm_push(name, chart, push_result):
    _helm_cmd("push", [], name, "@shared_bazel_rules//ci/helm/helm:helm_push.sh")

    _rule_helm_push(
        name = name,
        chart = chart,
        push_result = push_result,
        helm_push = "%s.push" % name,
    )

def helm_fetch(name, repository, chart, version = "~0.0"):
    _helm_cmd("fetch", [], name, "@shared_bazel_rules//ci/helm/helm:helm_fetch.sh")

    _rule_helm_fetch(
        name = name,
        repository = repository,
        chart = chart,
        version = version,
        chart_out = "%s_chart.tar.gz" % name,
        helm_fetch = "%s.fetch" % name,
    )

def _build_helm_set_args(values):
    set_args = ["--set=%s=%s" % (key, values[key]) for key in sorted((values or {}).keys())]
    return " ".join(set_args)

def _helm_cmd(cmd, args, name, helm_cmd_name, values_yaml = None, values = None):
    binary_data = ["@shared_bazel_rules//ci/helm:helm_binary", "@shared_bazel_rules//tools/yq:yq_binary"]
    if values_yaml:
        binary_data.append(values_yaml)
    if values:
        args.append(_build_helm_set_args(values))

    native.sh_binary(
        name = name + "." + cmd,
        srcs = [helm_cmd_name],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = binary_data,
        args = args,
    )

def helm_release(name, release_name, chart, values_yaml = None, values = None, namespace = ""):
    """Defines a helm release.

    A given target has the following executable targets generated:

    `(target_name).install`
    `(target_name).install.wait`
    `(target_name).status`
    `(target_name).delete`
    `(target_name).test`
    `(target_name).test.noclean`

    Args:
        name: A unique name for this rule.
        release_name: name of the release.
        chart: The chart defined by helm_chart.
        values_yaml: The values.yaml file to supply for the release.
        values: A map of additional values to supply for the release.
        namespace: The namespace to install the release into. If empty will default the NAMESPACE environment variable and will fall back the the current username (via BUILD_USER).
    """
    helm_cmd_name = name + "_run_helm_cmd.sh"
    genrule_srcs = ["@shared_bazel_rules//ci/helm:runfiles_bash", chart]

    # build --set params
    set_params = _build_helm_set_args(values)

    # build --values param
    values_param = ""
    if values_yaml:
        values_param = "--values=$(location %s)" % values_yaml
        genrule_srcs.append(values_yaml)

    native.genrule(
        name = name,
        stamp = True,
        srcs = genrule_srcs,
        outs = [helm_cmd_name],
        cmd = HELM_CMD_PREFIX + """
export CHARTLOC=$(location """ + chart + """)
EXPLICIT_NAMESPACE=""" + namespace + """
NAMESPACE=\\$${EXPLICIT_NAMESPACE:-\\$$NAMESPACE}
export NS=\\$${NAMESPACE:-\\$${BUILD_USER}}

echo \\$$1

if [ "\\$$1" == "upgrade" ]; then
    helm \\$$@ --namespace \\$$NS """ + release_name + " " + set_params + " " + values_param + """ \\$$CHARTLOC
elif [ "\\$$1" == "test" ]; then
    helm test --cleanup """ + release_name + """
else
    helm \\$$@ """ + release_name + """
fi

EOF""",
    )
    _helm_cmd("install", ["upgrade", "--install"], name, helm_cmd_name, values_yaml, values)
    _helm_cmd("install.wait", ["upgrade", "--install", "--wait"], name, helm_cmd_name, values_yaml, values)
    _helm_cmd("status", ["status"], name, helm_cmd_name)
    _helm_cmd("delete", ["delete", "--purge"], name, helm_cmd_name)
    _helm_cmd("test", ["test", "--cleanup"], name, helm_cmd_name)
    _helm_cmd("test.noclean", ["test"], name, helm_cmd_name)
