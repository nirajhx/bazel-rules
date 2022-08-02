def _python_whl_tar_impl(ctx):
    # Create empty python_path to add all requirements to it
    python_path = ""
    # Create whl_paths for .tar action
    whl_paths = []

    # Unzip all .whl requirement files
    for requirement in ctx.attr.requirements:
        # Skip exclude packages
        # Full label can accessed with requirement.label
        # Bazel's rules_python 'pip_install' use "@{name}//pypi__{package}" as target name therefore split at "__" and use last part
        # {package} to exclude Python packages
        # Bazel's rules_python 'pip_parse' use "@{name}_{package}//:pkg" as target name therefore use whole exclude string
        # because pip_parse repository rule and Python package names can contain valid underscores
        if requirement.label.package and requirement.label.package.split("__", 1)[1] in ctx.attr.exclude:
          continue
        elif requirement.label.workspace_name in ctx.attr.exclude:
          continue

        # Each requirements must only have one .whl file
        if len(requirement.files.to_list()) > 1:
            fail("Requirement {} has more than one .whl file: {}".format(requirement.label, requirement.files.to_list()))

        # Declare own directory to extract .whl files for every Python package
        if requirement.label.package:
          whl_dir = ctx.actions.declare_directory(requirement.label.package)
        else:
          whl_dir = ctx.actions.declare_directory(requirement.label.workspace_name)

        # Run unzip action
        ctx.actions.run(
            mnemonic = "zipperWhl",
            progress_message = "Unzip to directory: %s" % whl_dir.path,
            inputs = requirement.files,
            executable = ctx.executable.zipper,
            arguments = ["x", requirement.files.to_list()[0].path, "-d", whl_dir.path],
            outputs = [whl_dir],
        )
        # Append declared directory to whl_paths for later use with build_tar
        whl_paths.append(whl_dir)

    # Start building the arguments for PackageTar.
    args = [
        "--root_directory=./",
        "--output=" + ctx.outputs.out.path,
        "--directory=/",
        "--mode=" + ctx.attr.mode,
        "--owner=0.0",
        "--owner_name=.",
        "--mtime=portable",
    ]

    for f in whl_paths:
        args += [
            "--file=%s=%s" % (f.path, f.short_path)
        ]

        # Build PYTHONPATH, add ':' between each path, i.e. only if python_path is not empty
        if len(python_path) > 0:
            python_path += ":"
        python_path += "/" + f.short_path

    # Run tar action
    ctx.actions.run(
        mnemonic = "PackageTarWhl",
        progress_message = "Writing: %s" % ctx.outputs.out.path,
        inputs = whl_paths,
        executable = ctx.executable.build_tar,
        arguments = args,
        outputs = [ctx.outputs.out],
        env = {
            "LANG": "en_US.UTF-8",
            "LC_CTYPE": "UTF-8",
            "PYTHONIOENCODING": "UTF-8",
            "PYTHONUTF8": "1",
        },
        use_default_shell_env = True,
    )

    # Return output file and TemplateVariableInfo for use with toolchains variables in container_image
    return [
        DefaultInfo(
            files = depset([ctx.outputs.out]),
        ),
        # Return python_path as MODULE_PATH for use with container_image rule
        platform_common.TemplateVariableInfo({
            "MODULE_PATH": python_path,
        }),
    ]

python_whl_tar = rule(
    attrs = {
        "requirements": attr.label_list(
            mandatory = True,
            allow_files = [".whl"],
            doc = "A list of rules_python 'whl_requirement' whl files.",
        ),
        "exclude": attr.string_list(
            doc = "Exclude whl files from tar file and module path.",
        ),
        "mode": attr.string(
            default = "0555",
            doc = "Mode of all files inside the tar archive file.",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "Filename of the output tar archive file.",
        ),

        # Implicit dependencies.
        "zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            cfg = "exec",
            executable = True,
            allow_files = True,
            doc = "(UN)ZIP utility used to unzip the .whl files, defaults to '@bazel_tools//tools/zip:zipper'."
        ),
        "build_tar": attr.label(
            default = Label("@rules_pkg//:build_tar"),
            cfg = "exec",
            executable = True,
            allow_files = True,
            doc = "TAR utility used to tar extracted .whl files for use with 'rules_docker', defaults to '@rules_pkg//:build_tar'."
        ),
    },
    implementation = _python_whl_tar_impl,
    doc = """A rule for extracting imported Python Wheels into a TAR archive. The rule further returns a MODULE_PATH variable.

    Designed for use with Bazel's rules_python pip_import/pip_parse or VWNI pip_download rule.

    In WORKSPACE:
    Load rules_python pip_import/pip_parse rule according to official documentation

    OR

    load("@shared_bazel_rules//tools/python:pip.bzl", "pip_download")
    pip_download(
        name = "my_deps",
        requirements = "//services/my_service:requirements.txt",
        # Extra arguments to pass on to pip. Must not contain spaces.
        extra_pip_args = [
            "--platform=manylinux2014_x86_64",
            "--only-binary=:all:",
            # https://pip.pypa.io/en/stable/user_guide/#netrc-support for user authentication
            "--extra-index-url=https://nexus.core.build.vwn.cloud/repository/pywheels/simple/",
        ],
    )

    In BUILD:
    load("@my_deps//:requirements.bzl", "requirement", "whl_requirement", "all_whl_requirements")
    load("@shared_bazel_rules//tools/python:python_whl_tar.bzl", "python_whl_tar")

    python_whl_tar(
        name = "my-service-whl-tar",
        requirements = all_whl_requirements,
        exclude = [
          "pytest",
        ],
        mode = "0o644",
        out = "my-service-whl-tar.tar",
    )

    Please note that the use of 'exclude' based on pip_parse requires not only the package name
    but @{name}_{package} where {name} is the repository name of pip_parse rule, i.e.:
    exclude_packages = ["pytest"]
    python_whl_tar(
        [...]
        exclude = ["{name}_" + n for n in exclude_packages],
    )

    In BUILD for container_image (optional):
    load("@io_bazel_rules_docker//container:container.bzl", "container_image")
    container_image(
        name = "application-image",
        base = "@my_base_image//image",
        env = {
            "PYTHONPATH": "/app:$(MODULE_PATH)",
        },
        tars = [":my-service-tar", ":my-service-whl-tar"],
        # ":my-service-whl-tar" provides $(MODULE_PATH) variable via toolchains
        toolchains = [":my-service-whl-tar"],
    )
    """,
)
