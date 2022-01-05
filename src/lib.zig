const std = @import("std");

const c = @cImport({
    @cInclude("zpp.h");
});

// --------------------------------------------------
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

// --------------------------------------------------
// std::string

pub const StdStringError = error {
    Nullptr,
};

pub const StdString = struct {
    ptr: isize,
    
    pub fn deinit(self: *StdString) void {
        _ = c.zpp_ss_free(self.ptr);
    }
    
    pub fn clear(self: *StdString) bool {
        return c.zpp_ss_clear(self.ptr);
    }
    
    pub fn capacity(self: *StdString) usize {
        return c.zpp_ss_capacity(self.ptr);
    }
    
    pub fn size(self: *StdString) usize {
        return c.zpp_ss_size(self.ptr);
    }
    
    pub fn resize(self: *StdString, new_size: usize, filler_char: u8) bool {
        return c.zpp_ss_resize(self.ptr, new_size, filler_char);
    }
    
    pub fn asSlice(self: *StdString) ![]u8 {
        var len: usize = undefined;
        var buf = c.zpp_ss_data(self.ptr, &len);
        return if (buf == null) StdStringError.Nullptr else buf[0..len];
    }
    
    pub fn append(self: *StdString,
        data: []const u8,
        clear_before_append: bool,
    ) bool {
        return c.zpp_ss_append(self.ptr,
            @ptrCast([*c]const u8, data), data.len,
            clear_before_append,
        );
    }
};

pub fn initStdString(initial_capacity: usize) StdString {
    return .{
        .ptr = c.zpp_ss_new(initial_capacity),
    };
}
