
Bazel Repo Example for Lua
--------

This repo includes some custom bazel rules/scripts to allow building and running lua files, either via luajit or normal lua.  See examples/ directory for usage.  By default it runs via luajit, but if you want to run with normal lua you can do this by changing the 'lua_binary' rule in 'buildtools/lua/defs.bzl'.

Supported platforms: Linux, OSX

