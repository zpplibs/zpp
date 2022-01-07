const std = @import("std");
const deps = @import("deps.zig");

const mode_names = makeModeNames();
var mode_name_idx: usize = undefined;

fn makeModeNames() [@typeInfo(std.builtin.Mode).Enum.fields.len][]const u8 {
    var names: [@typeInfo(std.builtin.Mode).Enum.fields.len][]const u8 = undefined;
    inline for (@typeInfo(std.builtin.Mode).Enum.fields) |field, i| {
        names[i] = "[" ++ field.name ++ "] ";
    }
    return names;
}

fn addTest(
    comptime root_src: []const u8,
    test_name: []const u8,
    b: *std.build.Builder,
) *std.build.LibExeObjStep {
    const t = b.addTest(root_src);
    t.setNamePrefix(mode_names[mode_name_idx]);
    
    t.addIncludeDir("test"); // private
    
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
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    mode_name_idx = @enumToInt(mode);
    
    // tests
    const test_all = b.step("test", "Run all tests");
    const tests = &[_]*std.build.LibExeObjStep{
        deps.addAllTo(
            addTest("test/test.zig", "test:lib", b),
            b, target, mode,
        ),
    };
    for (tests) |t| test_all.dependOn(&t.step);
    
    // executables
    // deps.addAllTo(
    //     addExecutable(
    //         "example", "src/example.zig",
    //         "run", "Run the example",
    //         b,
    //     ),
    //     b, target, mode,
    // ).install();
}
