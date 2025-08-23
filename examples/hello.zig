const std = @import("std");
const zpp = @import("zpp");

const builtin = @import("builtin");
const build_options = @import("build_options");

const version = build_options.version;
const line = "--------------------------------------------------";

const Info = struct {
    prefix: []const u8 = "",
    suffix: []const u8 = "\n" ++ line ++ "\n",
};
const info: Info = if (builtin.is_test) .{
    .prefix = line ++ "\nversion: " ++ version ++ " (Test)",
} else .{
    .prefix = line ++ "\nversion: " ++ version,
};

fn printInfo() void {
    std.debug.print("{s}\n{s} {s} {}{s}", .{
        info.prefix,
        @tagName(builtin.os.tag),
        @tagName(builtin.cpu.arch),
        builtin.mode,
        info.suffix,
    });
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    const allocArgs = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, allocArgs);
    const args = allocArgs[1..];
    try run(args);
}

fn run(args: [][:0]u8) !void {
    printInfo();
    var def = zpp.initStdString(.{
        .min_capacity = 0,
    });
    defer def.deinit();

    const min_capacity: usize = 512;
    var buf = zpp.initFlexStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    for (args) |arg| {
        try buf.appendSlice(arg);
    }

    const actual_capacity = buf.capacity();

    std.debug.print(
        "len: {}\ncapacity default: {}, min: {}, actual: {}\n",
        .{ buf.size(), def.capacity(), min_capacity, actual_capacity },
    );
}
