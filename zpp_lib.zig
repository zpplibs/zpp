const std = @import("std");

pub fn configure(
    comptime basedir: []const u8,
    comptime dep_dirs: anytype,
    comptime root_dep_dirs: anytype,
    allocator: std.mem.Allocator,
    lib: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
) *std.build.LibExeObjStep {
    _ = dep_dirs;
    _ = root_dep_dirs;
    _ = allocator;

    lib.setTarget(target);
    lib.setBuildMode(mode);

    lib.linkLibC();
    lib.linkLibCpp();

    lib.addIncludeDir(basedir ++ "/include");
    lib.addCSourceFiles(&.{
        basedir ++ "/src/lib.cpp",
    }, &.{
        "-std=c++14",
        "-Wall",
        "-Wextra",
        "-Werror",
        "-fno-exceptions",
        "-fno-rtti",
        "-DNDEBUG",
    });

    return lib;
}
