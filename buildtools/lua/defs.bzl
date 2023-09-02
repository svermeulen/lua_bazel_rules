
LuaLibraryInfo = provider(
    doc = "Contains information about a Lua library",
    fields = {
        "deps": "A depset of info structs for this library's dependencies",
        "srcs": "",
        "skip_meta_generation": "",
        "original_srcs": "",
        "import_path": "",
    },
)

def _convert_to_runfile_path(ctx, short_path):
    if short_path.startswith("../"):
        return short_path[3:]

    return ctx.workspace_name + "/" + short_path

def _create_lua_exec_script(ctx, script_name, import_paths, lua_file, lua_script, args = None):
    if not script_name.endswith(".sh"):
        fail("Unexpected script extension")

    lua_path = ";".join(["$RUNFILES_DIR/{0}/?.lua;$RUNFILES_DIR/{0}/?/init.lua".format(_convert_to_runfile_path(ctx, x)) for x in import_paths])

    # TODO - change to use toolchains etc properly instead of this hack
    if ctx.configuration.host_path_separator == "\\":
        shared_lib_extension = "dll"
    else:
        shared_lib_extension = "so"

    lua_cpath = ";".join(["$RUNFILES_DIR/{0}/?.{1}".format(_convert_to_runfile_path(ctx, x), shared_lib_extension) for x in import_paths])

    # We need to set LD_LIBRARY_PATH so that we can load the `.so` files via ffi instead of directly through cpath
    # This is necessary because ffi does not use lua cpath at all
    lib_paths = ":".join(["$RUNFILES_DIR/{0}".format(_convert_to_runfile_path(ctx, x)) for x in import_paths])

    # Figuring out how to reliably find the correct path to runfiles took a long time
    # The github issue that eventually led me to use $0.runfiles is here:
    # https://github.com/bazelbuild/rules_go/issues/2359
    # I tried many other things, including reading through the runtime runfiles libraries (eg. runfiles.bash, runfiles.py)
    # and experimenting with short_path, path, root.path, etc.
    # This was the only one that both works when used as part of `bazel run` and also `bazel build`
    # I am also checking for $RUNFILES_DIR and using that if it exists, since this is needed when running underneath
    # `bazel test` contexts
    script_str = "#!/bin/bash\n" + \
                 "set -e\n" + \
                 "if [[ ! -d \"${RUNFILES_DIR:-/dev/null}\" ]]; then\n" + \
                 "  export RUNFILES_DIR=\"$0.runfiles\"\n" + \
                 "fi\n\n" + \
                 "export LD_LIBRARY_PATH=\"{}\"\n".format(lib_paths) + \
                 "export LUA_PATH=\"{}\"\n".format(lua_path) + \
                 "export LUA_CPATH=\"{}\"\n".format(lua_cpath) + \
                 "\"$RUNFILES_DIR/{0}\" \"$RUNFILES_DIR/{1}\"".format(
                     _convert_to_runfile_path(ctx, lua_file.short_path),
                     _convert_to_runfile_path(ctx, lua_script.short_path),
                 )

    if args != None:
        script_str += " " + args

    exec_script = ctx.actions.declare_file(script_name)
    ctx.actions.write(exec_script, script_str, is_executable = True)
    return exec_script

def _lua_binary(ctx):
    if len(ctx.files.srcs) != 0 and ctx.file.import_path == None:
        fail("When providing values for srcs you must also provide a value for import_path")

    bootstrap_lua_file = _declare_file_with_contents(
        ctx,
        "_bootstrap.lua",
        "require(\"{}\")".format(ctx.attr.main),
    )

    all_deps = _expand_transitive_lua_deps(ctx.attr.deps)

    import_paths = [d.import_path for d in all_deps]

    if ctx.file.import_path != None:
        import_paths += [ctx.file.import_path.short_path]

    exec_script = _create_lua_exec_script(
        ctx,
        ctx.label.name + ".sh",
        import_paths,
        ctx.file.lua,
        bootstrap_lua_file,
        "\"$@\"",
    )

    run_files = [ctx.file.lua, bootstrap_lua_file] + ctx.files.srcs

    for dep in all_deps:
        run_files += dep.srcs

    return [
        DefaultInfo(
            executable = exec_script,
            runfiles = ctx.runfiles(run_files),
        ),
    ]

lua_binary = rule(
    implementation = _lua_binary,
    attrs = {
        "main": attr.string(
            mandatory = True,
            doc = "Module path to load as entry point. Should be in the same format passed to require() (eg. foo.bar instead of foo/bar.lua)",
        ),
        "srcs": attr.label_list(
            allow_files = [".lua", ".so"],
            doc = "Source files for the binary",
        ),
        "deps": attr.label_list(
            doc = "Direct dependencies of the binary",
        ),
        "import_path": attr.label(
            allow_single_file = True,
            doc = "Import path where the require path for the source files should start.  Usually this should be set to '.', or sometiems 'src' if lua files/directories are placed inside a directory named 'src'",
        ),
        "lua": attr.label(
            allow_single_file = True,

            # Either of these should work
            # default = "@//buildtools/lua:lua",
            default = "@//third_party/luajit:luajit",
            cfg = "exec",
            executable = True,
        ),
    },
    executable = True,
)

def _expand_transitive_lua_deps(direct_deps):
    return [d[LuaLibraryInfo] for d in depset(
        direct = direct_deps,
        transitive = [d[LuaLibraryInfo].deps for d in direct_deps],
    ).to_list()]

def _declare_file_with_contents(ctx, file_name, contents):
    file = ctx.actions.declare_file(file_name)
    ctx.actions.write(file, contents)
    return file

def _lua_library(ctx):
    return [
        LuaLibraryInfo(
            import_path = ctx.file.import_path.short_path,
            srcs = ctx.files.srcs,
            skip_meta_generation = ctx.attr.skip_meta_generation,
            original_srcs = [x.path for x in ctx.files.srcs],
            deps = depset(
                direct = ctx.attr.deps,
                transitive = [dep[LuaLibraryInfo].deps for dep in ctx.attr.deps if LuaLibraryInfo in dep],
            ),
        ),
    ]

lua_library = rule(
    implementation = _lua_library,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua", ".so", ".dll"],
        ),
        "skip_meta_generation": attr.bool(default = False),
        "import_path": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "deps": attr.label_list(
            providers = [LuaLibraryInfo],
            doc = "Direct dependencies of the library",
        ),
    },
)
