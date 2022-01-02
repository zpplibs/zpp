const std = @import("std");

const c = @cImport({
    @cInclude("zpp.h");
});

// c calling to zig
pub export fn zpp_array_list_u8_append(
    list_ptr: ?*anyopaque,
    data: [*c]u8,
    data_len: isize,
) callconv(.C) bool {
    if (list_ptr == null) return false;
    var list = @ptrCast(*std.ArrayList(u8), @alignCast(@alignOf(*std.ArrayList(u8)), list_ptr));
    list.appendSlice(data[0..@intCast(usize, data_len)]) catch return false;
    return true;
}
