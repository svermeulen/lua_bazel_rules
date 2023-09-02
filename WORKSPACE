
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# ------------------------------ Lua rules ------------------------------

maybe(
    name = "remote_lua51_repository",
    build_file = "@//buildtools/lua:lua.BUILD",
    repo_rule = http_archive,
    sha256 = "2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333",
    strip_prefix = "lua-5.1.5",
    urls = [
        "https://www.lua.org/ftp/lua-5.1.5.tar.gz",
    ],
)

# ------------------------------  ------------------------------

http_archive(
    name = "rules_foreign_cc",
    sha256 = "076b8217296ca25d5b2167a832c8703cc51cbf8d980f00d6c71e9691876f6b08",
    strip_prefix = "rules_foreign_cc-2c6262f8f487cd3481db27e2c509d9e6d30bfe53",
    url = "https://github.com/bazelbuild/rules_foreign_cc/archive/2c6262f8f487cd3481db27e2c509d9e6d30bfe53.tar.gz",
)

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()

# ------------------------------  ------------------------------

# This setup was partially taken from the envoy project
http_archive(
    name = "com_github_luajit_luajit",
    build_file_content = """filegroup(name = "all", srcs = glob(["**"]), visibility = ["//visibility:public"])""",
    patches = ["@//third_party/luajit:luajit.patch"],
    patch_args = ["-p1"],
    patch_cmds = ["chmod u+x build.py"],
    url = "https://github.com/LuaJIT/LuaJIT/archive/1d8b747c161db457e032a023ebbff511f5de5ec2.tar.gz",
    strip_prefix = "LuaJIT-1d8b747c161db457e032a023ebbff511f5de5ec2",
    sha256 = "20a159c38a98ecdb6368e8d655343b6036622a29a1621da9dc303f7ed9bf37f3"
)

