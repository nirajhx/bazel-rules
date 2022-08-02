load("@bazel_skylib//lib:paths.bzl", "paths")

def _srcjar_from_dir(ctx):
    zipper_args_file = ctx.actions.declare_file("zipper_args_file.txt")

    # Each src must only have one file, i.e. the directory
    if len(ctx.attr.src.files.to_list()) > 1:
        fail("Attribute 'src' for Label {} has more than one file: {}".format(ctx.attr.src.label, ctx.attr.src.files.to_list()))
    # Each src must be a directory
    if not ctx.attr.src.files.to_list()[0].is_directory:
        fail("Attribute 'srcs' for Label {} is not a directory.".format(ctx.attr.src.label))

    search_path = paths.join(ctx.attr.src.files.to_list()[0].path, ctx.attr.subpath)

    # Run find Java files inside directory action and write result in temporary declared file
    ctx.actions.run_shell(
        inputs = ctx.attr.src.files,
        command = "find {} -name '*.java' > {}".format(search_path, zipper_args_file.path),
        outputs = [zipper_args_file],
    )

    # Usage: external/bazel_tools/tools/zip/zipper/zipper [vxc[fC]] x.zip [-d exdir] [[zip_path1=]file1 ... [zip_pathn=]filen]
    #    v verbose - list all file in x.zip
    #    x extract - extract files in x.zip to current directory, or     an optional directory relative to the current directory     specified through -d option
    #    c create  - add files to x.zip
    #    f flatten - flatten files to use with create or extract operation
    #    C compress - compress files when using the create operation
    #  x and c cannot be used in the same command-line.

    #  For every file, a path in the zip can be specified. Examples:
    #    zipper c x.zip a/b/__init__.py= # Add an empty file at a/b/__init__.py
    #    zipper c x.zip a/b/main.py=foo/bar/bin.py # Add file foo/bar/bin.py at a/b/main.py

    #  If the zip path is not specified, it is assumed to be the file path.

    # Run Zipper action for scrjar file
    ctx.actions.run(
        mnemonic = "zipper",
        progress_message = "Zip Java files in directory %s to file %s" % (search_path, ctx.outputs.out.path),
        inputs = [zipper_args_file] + ctx.attr.src.files.to_list(),
        executable = ctx.executable.zipper,
        # Use file content from java_file as Zipper input
        arguments = ["c", ctx.outputs.out.path, "@" + zipper_args_file.path],
        outputs = [ctx.outputs.out],
    )


srcjar_from_dir = rule(
    attrs = {
        "src": attr.label(
            mandatory = True,
            doc = "A directory from OpenAPI generator containing Java files.",
        ),
        "subpath": attr.string(
            default = "src/main/java/",
            doc = "Subpath directory inside the attribute src.",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "Filename of the output file. Should end with .srcjar for further consumption.",
        ),

        # Implicit dependencies.
        "zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            cfg = "exec",
            executable = True,
            allow_files = True,
            doc = "(UN)ZIP utility used to zip the .java files, defaults to '@bazel_tools//tools/zip:zipper'."
        ),
    },
    implementation = _srcjar_from_dir,
    doc = """A rule searching for Java files inside a directory for creating a .srcjar file for Bazel's java_library rule.

    Designed for use with OpenAPITools openapi-generator-bazel.

    In WORKSPACE:
    Load shared_bazel_rules

    In BUILD:
    load("@openapi_tools_generator_bazel//:defs.bzl", "openapi_generator")
    load("@shared_bazel_rules//tools/openapi-generator:srcjar_from_dir.bzl", "srcjar_from_dir")

    # Build openapi
    openapi_generator(
        name = "service_openapi",
        generator = "java",
        spec = "service_api.yaml",
        [...]
    )

    srcjar_from_dir(
        name = "service_openapi_srcjar",
        src = ":service_openapi",
        out = "service_openapi_srcjar.srcjar",
    )

    java_library(
        name = "service_openapi_library",
        deps = [
            [...]
        ],
        srcs = [
            ":service_openapi_srcjar",
        ],
    )
    """,
)
