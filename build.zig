const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zpp = b.addModule("zpp", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cpp_header = b.path("include/zpp.h");

    const cpp_lib = b.addStaticLibrary(.{
        .name = "zpp",
        .target = target,
        .optimize = optimize,
    });
    cpp_lib.addIncludePath(b.path("include"));
    cpp_lib.linkLibCpp();
    cpp_lib.installHeader(cpp_header, "zpp.h");

    cpp_lib.addCSourceFiles(.{
        .files = &.{
            "lib.cpp",
        },
        .root = b.path("src"),
    });
    b.installArtifact(cpp_lib);

    b.default_step.dependOn(&b.addInstallHeaderFile(
        cpp_header,
        "zpp.h",
    ).step);

    zpp.linkLibrary(cpp_lib);

    zpp.addImport("zpp_clib", b.addTranslateC(.{
        .root_source_file = cpp_header,
        .target = target,
        .optimize = optimize,
    }).createModule());

    {
        // Setup Tests
        // const test_header = b.path("test/zpp-test.h");
        const lib_test = b.addTest(.{
            // .root_module = zpp,
            .root_source_file = b.path("test/test.zig"),
            .filters = b.option(
                []const []const u8,
                "test-filter",
                "test-filter",
            ) orelse &.{},
            // .test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
        });
        lib_test.root_module.addImport("zpp", zpp);
        lib_test.addIncludePath(b.path("test"));
        lib_test.addIncludePath(b.path("include"));

        // lib_test.addImport("zpp_testlib", b.addTranslateC(.{
        //     .root_source_file = test_header,
        //     .target = target,
        //     .optimize = optimize,
        // }).createModule());

        const run_test = b.addRunArtifact(lib_test);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_test.step);
    }
}
