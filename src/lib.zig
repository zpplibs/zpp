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

const empty_array: [0]u8 = undefined;
const empty_slice = empty_array[0..];

pub const StdStringError = error {
    Append,
    Resize,
    Nullptr,
};

pub const StdString = struct {
    ptr: isize,
    
    pub fn deinit(self: *StdString) void {
        _ = c.zpp_ss_free(self.ptr);
    }
    
    pub fn clearRetainingCapacity(self: *StdString) void {
        _ = c.zpp_ss_clear(self.ptr);
    }
    
    pub fn capacity(self: *StdString) usize {
        return c.zpp_ss_capacity(self.ptr);
    }
    
    pub fn size(self: *StdString) usize {
        return c.zpp_ss_size(self.ptr);
    }
    
    pub fn resize(self: *StdString, new_len: usize) !void {
        if (!c.zpp_ss_resize(
            self.ptr, new_len, 0,
        )) return StdStringError.Resize;
    }
    
    pub fn resizeAndFill(self: *StdString, new_len: usize, filler: u8) !void {
        if (!c.zpp_ss_resize(
            self.ptr, new_len, filler,
        )) return StdStringError.Resize;
    }
    
    pub fn items(self: *StdString) []u8 {
        var len: usize = undefined;
        var data = c.zpp_ss_data(self.ptr, &len);
        return if (data == null) empty_slice else data[0..len];
    }
    
    /// Append the slice of items. Allocates more memory as necessary.
    pub fn appendSlice(self: *StdString, items_: []const u8) !void {
        if (!c.zpp_ss_append(self.ptr,
            @ptrCast([*c]const u8, items_), items_.len,
            false,
        )) return StdStringError.Append;
    }
    
    pub fn append(self: *StdString,
        data: []const u8,
        clear_before_append: bool,
    ) !void {
        if (!c.zpp_ss_append(self.ptr,
            @ptrCast([*c]const u8, data), data.len,
            clear_before_append,
        )) return StdStringError.Append;
    }
};

pub fn initStdString(min_capacity: usize) StdString {
    return .{
        .ptr = c.zpp_ss_new(min_capacity, null, null),
    };
}

pub const FixedStdString = struct {
    ptr: isize,
    len: usize,
    buf: []u8,
    
    pub fn deinit(self: *FixedStdString) void {
        _ = c.zpp_ss_free(self.ptr);
    }
    
    pub fn clearRetainingCapacity(self: *FixedStdString) void {
        self.len = 0;
    }
    
    pub fn capacity(self: *FixedStdString) usize {
        return self.buf.len;
    }
    
    pub fn size(self: *FixedStdString) usize {
        return self.len;
    }
    
    pub fn resize(self: *FixedStdString, new_len: usize) !void {
        // if (new_len > self.buf.len) return StdStringError.Resize;
        // self.len = new_len;
        // std.mem.set(u8, self.buf[0..new_len], 0);
        try self.resizeAndFill(new_len, 0);
    }
    
    pub fn resizeAndFill(self: *FixedStdString, new_len: usize, filler: u8) !void {
        if (new_len > self.buf.len) return StdStringError.Resize;
        const prev_len = self.len;
        if (new_len == prev_len) {
            std.mem.set(u8, self.buf[0..new_len], filler);
        } else if (new_len > prev_len) {
            self.len = new_len;
            std.mem.set(u8, self.buf[prev_len..new_len], filler);
        } else {
            self.len = new_len;
        }
    }
    
    pub fn items(self: *FixedStdString) []u8 {
        return self.buf[0..self.len];
    }
    
    pub fn appendSlice(self: *FixedStdString, items_: []const u8) !void {
        if (items_.len == 0) return;
        const new_len = self.len + items_.len;
        if (new_len > self.buf.len) return StdStringError.Append;
        
        std.mem.copy(u8, self.buf[self.len..], items_);
        self.len = new_len;
    }
    
    pub fn append(self: *FixedStdString,
        data: []const u8,
        clear_before_append: bool,
    ) !void {
        if (data.len == 0) {
            if (clear_before_append) self.len = 0;
            return;
        }
        const len = if (clear_before_append) 0 else self.len;
        const new_len = len + data.len;
        if (new_len > self.buf.len) return StdStringError.Append;
        
        std.mem.copy(u8, self.buf[len..], data);
        self.len = new_len;
    }
};

pub fn initFixedStdString(capacity: usize, use_actual: bool) FixedStdString {
    var min_capacity = capacity;
    var data: [*c]u8 = undefined;
    var ptr = c.zpp_ss_new(
        capacity + 1, // zero-terminated
        &data,
        if (use_actual) &min_capacity else null,
    );
    data[capacity] = 0;
    return .{
        .ptr = ptr,
        .len = 0,
        .buf = data[0..min_capacity],
    };
}
