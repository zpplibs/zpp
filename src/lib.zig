const std = @import("std");

const c = @cImport({
    @cInclude("zpp.h");
});

// c calling to zig
export fn zpp_array_list_u8_append(
    list_ptr: ?*anyopaque,
    data: [*c]u8,
    data_len: usize,
) callconv(.C) bool {
    if (list_ptr == null or data == null or data_len < 0) return false;
    if (data_len == 0) return true;
    
    var list = @ptrCast(
        *std.ArrayList(u8),
        @alignCast(@alignOf(*std.ArrayList(u8)),
        list_ptr,
    ));
    list.appendSlice(data[0..data_len]) catch return false;
    
    return true;
}

/// Access this variable so the compiler won't skip codegen for this
pub const initialized = !zpp_array_list_u8_append(null, null, 0);