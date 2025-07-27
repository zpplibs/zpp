const std = @import("std");
const zpp = @import("zpp");
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
    var def = zpp.initStdString(0);
    defer def.deinit();

    const min_capacity: usize = 512;
    var buf = zpp.initFlexStdString(min_capacity);
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
