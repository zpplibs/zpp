const std = @import("std");

const c_flags = &[_][]const u8{"-std=c99"};

const SourceType = struct {
    withExe: bool,
    withTest: bool,
    const both: SourceType = .{ .withExe = true, .withTest = true };
    const exeOnly: SourceType = .{ .withExe = true, .withTest = false };
    const testOnly: SourceType = .{ .withExe = false, .withTest = true };
};

const BuildModule = struct {
    b: *std.Build,
    tests: *std.Build.Step,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    optimize_idx: usize,
};

const optimize_names = blk: {
    // const fields = @typeInfo(std.builtin.OptimizeMode).Enum.fields;
    const fields = std.meta.fields(std.builtin.OptimizeMode);
    var names: [fields.len][]const u8 = undefined;
    for (fields, 0..) |field, i| names[i] = field.name;
    break :blk names;
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var bm: BuildModule = .{
        .b = b,
        .tests = b.step("test", "Run all tests"),
        .target = target,
        .optimize = optimize,
        .optimize_idx = @intFromEnum(optimize),
    };

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

        bm.tests.dependOn(&b.addRunArtifact(lib_test).step);
    }
    {
        const hello = addModuleTo(&bm, .exeOnly, "examples/hello.zig", "");
        hello.addImport("zpp", zpp);
    }
}

fn addModuleTo(
    bm: *BuildModule,
    comptime sourceType: SourceType,
    comptime root_src: []const u8,
    comptime run_name: []const u8,
) *std.Build.Module {
    const is_zig = std.mem.endsWith(u8, root_src, ".zig");

    if (!sourceType.withTest and !sourceType.withExe) @panic("Must atleast be exe or test.");
    if (!is_zig and sourceType.withTest) @panic("Tests can only be in .zig files");

    const name = comptime resolveSrcName(root_src);

    const b = bm.b;

    const mod = b.createModule(.{
        .root_source_file = .{
            .src_path = .{
                .owner = b,
                .sub_path = root_src,
            },
        },
        .target = bm.target,
        .optimize = bm.optimize,
    });
    // mod.addOptions("build_options", bm.build_options);

    if (sourceType.withExe) {
        const exe_name = if (bm.optimize == .ReleaseFast) name else concat(b, name ++ "--", optimize_names[bm.optimize_idx], name);
        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = mod,
        });

        if (!is_zig) {
            exe.addCSourceFile(.{
                .file = .{ .src_path = .{
                    .owner = b,
                    .sub_path = root_src,
                } },
                .flags = c_flags,
            });
        }
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| run_cmd.addArgs(args);

        b.step(
            if (run_name.len != 0) run_name else "run:" ++ name,
            "Run executable from " ++ root_src,
        ).dependOn(&run_cmd.step);

        b.installArtifact(exe);
    }
    if (is_zig and sourceType.withTest) {
        const prefix = name ++ "--test--";
        const test_name = concat(b, prefix, optimize_names[bm.optimize_idx], prefix);
        const t = b.addTest(.{
            .name = test_name,
            .root_module = mod,
        });

        b.step(
            "test:" ++ name,
            "Run tests from " ++ root_src,
        ).dependOn(&b.addRunArtifact(t).step);

        b.installArtifact(t);
        bm.tests.dependOn(&b.addRunArtifact(t).step);
    }
    return mod;
}

fn resolveSrcName(src: []const u8) []const u8 {
    const slashIdx = std.mem.lastIndexOf(u8, src, "/");
    const start = if (slashIdx) |idx| idx + 1 else 0;
    const dotIdx = std.mem.indexOf(
        u8,
        if (start == 0) src else src[start..],
        ".",
    ) orelse 0;
    return if (start != 0 and dotIdx != 0) src[start .. start + dotIdx] else src;
}

fn concat(b: *std.Build, prefix: []const u8, suffix: []const u8, def: []const u8) []const u8 {
    const out = b.allocator.alloc(u8, prefix.len + suffix.len) catch return def;
    @memcpy(out[0..prefix.len], prefix);
    @memcpy(out[prefix.len..], suffix);
    return out;
}
