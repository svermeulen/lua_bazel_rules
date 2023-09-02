"""
"""

load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

# Some libraries, like luafilesystem, need lua headers, but we
# don't want to depend on lua_cc_library because then the entire
# lua library seems to get linked for unknown reasons
# There is probably a better way to do this but I am not sure how yet
# so just going with a separate target here
cc_library(
    name = "lua_headers",
    hdrs = glob([
        "src/*.h",
        "src/*.hpp",
    ]),
    strip_include_prefix = "src",
    visibility = ["//visibility:public"],
)

cc_library(
    name = "lua_cc_library",
    srcs = glob(
        [
            "src/*.c",
            "src/*.h",
            "src/*.hpp",
        ],
        exclude = [
            "src/lua.c",
            "src/luac.c",
        ],
    ),
    hdrs = glob([
        "src/*.h",
        "src/*.hpp",
    ]),
    linkstatic = True,
    local_defines = select({
        "@platforms//os:linux": [
            "LUA_USE_LINUX",
        ],
        "@platforms//os:osx": [
            "LUA_USE_MACOSX",
        ],
        "//conditions:default": [
        ],
    }),
    strip_include_prefix = "src",
    visibility = ["//visibility:public"],
)

cc_binary(
    name = "lua",
    srcs = ["src/lua.c"],
    linkopts = select({
        "@platforms//os:linux": [
            "-lm",
            "-ldl",
        ],
        "//conditions:default": [
        ],
    }),
    linkstatic = True,
    visibility = ["//visibility:public"],
    deps = [
        ":lua_cc_library",
    ],
)

cc_binary(
    name = "luac",
    srcs = ["src/luac.c"],
    linkopts = select({
        "@platforms//os:linux": [
            "-lm",
            "-ldl",
        ],
        "//conditions:default": [
        ],
    }),
    linkstatic = True,
    visibility = ["//visibility:public"],
    deps = [
        ":lua_cc_library",
    ],
)
