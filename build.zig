const std = @import("std");

const lib_pkg = std.build.Pkg{
    .name = "zpp", // zigmod cfg
    .path = .{ .path = "src/lib.zig" }, //zigmod cfg
};

fn addAllTo(
    exe: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
) *std.build.LibExeObjStep {
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(lib_pkg);
    exe.addIncludeDir("include"); // zigmod cfg
    exe.addIncludeDir("test"); // private
    return exe;
}

fn addTest(
    comptime root_src: []const u8,
    test_name: []const u8,
    b: *std.build.Builder,
) *std.build.LibExeObjStep {
    const t = b.addTest(root_src);
    
    b.step(
        if (test_name.len != 0) test_name else "test:" ++ root_src,
        "Run tests from " ++ root_src,
    ).dependOn(&t.step);
    
    return t;
}

// fn addExecutable(
//     comptime name: []const u8,
//     root_src: []const u8,
//     run_name: []const u8,
//     run_description: []const u8,
//     b: *std.build.Builder,
// ) *std.build.LibExeObjStep {
//     const exe = b.addExecutable(name, root_src);
    
//     const run_cmd = exe.run();
//     run_cmd.step.dependOn(b.getInstallStep());
//     if (b.args) |args| run_cmd.addArgs(args);
    
//     b.step(
//         if (run_name.len != 0) run_name else "run:" ++ name,
//         if (run_description.len != 0) run_description else "Run " ++ name,
//     ).dependOn(&run_cmd.step);
    
//     return exe;
// }

pub fn build(b: *std.build.Builder) void {
    //b.setPreferredReleaseMode(.ReleaseSafe);
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    
    // tests
    const test_all = b.step("test", "Run all tests");
    const tests = &[_]*std.build.LibExeObjStep{
        addAllTo(
            addTest("test/test.zig", "test:lib", b),
            target, mode,
        ),
    };
    for (tests) |t| test_all.dependOn(&t.step);
    
    // executables
    // addAllTo(
    //     addExecutable(
    //         "example", "src/example.zig",
    //         "run", "Run the example",
    //         b,
    //     ),
    //     target, mode,
    // ).install();
}
