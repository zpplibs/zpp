const std = @import("std");

const c = @cImport({
    @cInclude("zpp.h");
});

// const empty_array: [0]u8 = undefined;
// const empty_slice = empty_array[0..];
const empty_slice: []u8 = "";

// --------------------------------------------------
// std::string

pub const StdStringError = error{
    Append,
    Resize,
    Nullptr,
};

pub const AppendOpts = struct {
    clear_before_append: bool = false,
};

/// Best for reading/processing data coming from c++.
/// If you must also write to the buffer, consider using `FlexStdString`.
pub const StdString = struct {
    ptr: isize,

    pub fn deinit(self: *StdString) void {
        _ = c.zpp_ss_free(&self.ptr);
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
            self.ptr,
            new_len,
            0,
            false,
            null,
            null,
        )) return StdStringError.Resize;
    }

    pub fn resizeAndFill(self: *StdString, new_len: usize, filler: u8) !void {
        if (!c.zpp_ss_resize(
            self.ptr,
            new_len,
            filler,
            false,
            null,
            null,
        )) return StdStringError.Resize;
    }

    pub fn items(self: *StdString) []u8 {
        var len: usize = undefined;
        var data = c.zpp_ss_data(self.ptr, &len);
        return if (data == null) empty_slice else data[0..len];
    }

    pub fn append(self: *StdString, item: u8) !void {
        const items_: [1]u8 = .{item};
        return appendSlice(self, &items_);
    }

    /// Append the slice of items. Allocates more memory as necessary.
    pub fn appendSlice(self: *StdString, items_: []const u8) !void {
        if (!c.zpp_ss_append(
            self.ptr,
            items_.ptr,
            items_.len,
            false,
        )) return StdStringError.Append;
    }

    pub fn appendSliceOpts(
        self: *StdString,
        data: []const u8,
        opts: AppendOpts,
    ) !void {
        if (!c.zpp_ss_append(
            self.ptr,
            data.ptr,
            data.len,
            opts.clear_before_append,
        )) return StdStringError.Append;
    }
};

pub fn initStdString(opts: struct {
    min_capacity: usize,
}) StdString {
    return .{
        .ptr = c.zpp_ss_new(
            opts.min_capacity,
            false,
            null,
            null,
        ),
    };
}

// --------------------------------------------------
// std::string (fixed capacity)

/// Best for writing data to be consumed by c++.
/// The capacity is fixed/static.
pub const FixedStdString = struct {
    ptr: isize,
    len: usize,
    buf: []u8,

    pub fn deinit(self: *FixedStdString) void {
        _ = c.zpp_ss_free(&self.ptr);
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
        // @memset(self.buf[0..new_len], 0);
        try self.resizeAndFill(new_len, 0);
    }

    pub fn resizeAndFill(self: *FixedStdString, new_len: usize, filler: u8) !void {
        if (new_len > self.buf.len) return StdStringError.Resize;
        const prev_len = self.len;
        if (new_len == prev_len) {
            @memset(self.buf[0..new_len], filler);
        } else if (new_len > prev_len) {
            self.len = new_len;
            @memset(self.buf[prev_len..new_len], filler);
        } else {
            self.len = new_len;
        }
    }

    pub fn items(self: *FixedStdString) []u8 {
        return self.buf[0..self.len];
    }

    pub fn append(self: *FixedStdString, item: u8) !void {
        const new_len = self.len + 1;
        if (new_len > self.buf.len) return StdStringError.Append;
        self.buf[self.len] = item;
        self.len = new_len;
    }

    pub fn appendSlice(self: *FixedStdString, items_: []const u8) !void {
        if (items_.len == 0) return;
        const new_len = self.len + items_.len;
        if (new_len > self.buf.len) return StdStringError.Append;

        @memcpy(self.buf[self.len .. self.len + items_.len], items_);
        self.len = new_len;
    }

    pub fn appendSliceOpts(
        self: *FixedStdString,
        data: []const u8,
        opts: AppendOpts,
    ) !void {
        if (data.len == 0) {
            if (opts.clear_before_append) self.len = 0;
            return;
        }
        const len = if (opts.clear_before_append) 0 else self.len;
        const new_len = len + data.len;
        if (new_len > self.buf.len) return StdStringError.Append;

        @memcpy(self.buf[len .. len + data.len], data);
        self.len = new_len;
    }
};

pub fn initFixedStdString(opts: struct {
    capacity: usize,
    use_actual: bool = true,
}) FixedStdString {
    var data: [*c]u8 = undefined;
    var actual_capacity = opts.capacity;
    const ptr = c.zpp_ss_new(
        opts.capacity,
        false,
        &data,
        if (opts.use_actual) &actual_capacity else null,
    );
    return .{
        .ptr = ptr,
        .len = 0,
        .buf = data[0..actual_capacity],
    };
}

// --------------------------------------------------
// std::string (flex capacity)

/// Best for writing data to be consumed by c++.
/// Similar to `FixedStdString` in terms of efficiency but can grow the capacity.
pub const FlexStdString = struct {
    ptr: isize,
    len: usize,
    buf: []u8,
    owned: bool,

    pub fn deinit(self: *FlexStdString) void {
        if (self.owned) _ = c.zpp_ss_free(&self.ptr);
    }

    pub fn clearRetainingCapacity(self: *FlexStdString) void {
        self.len = 0;
    }

    pub fn capacity(self: *FlexStdString) usize {
        return self.buf.len;
    }

    pub fn size(self: *FlexStdString) usize {
        return self.len;
    }

    pub fn resize(self: *FlexStdString, new_len: usize) !void {
        try self.resizeAndFill(new_len, 0);
    }

    pub fn resizeAndFill(self: *FlexStdString, new_len: usize, filler: u8) !void {
        if (new_len > self.buf.len) {
            var data: [*c]u8 = undefined;
            var actual_capacity: usize = undefined;
            if (!c.zpp_ss_resize(
                self.ptr,
                new_len,
                filler,
                false,
                &data,
                &actual_capacity,
            )) return StdStringError.Resize;
            self.len = new_len;
            self.buf = data[0..actual_capacity];
            return;
        }
        const prev_len = self.len;
        if (new_len == prev_len) {
            @memset(self.buf[0..new_len], filler);
        } else if (new_len > prev_len) {
            self.len = new_len;
            @memset(self.buf[prev_len..new_len], filler);
        } else {
            self.len = new_len;
        }
    }

    pub fn items(self: *FlexStdString) []u8 {
        return self.buf[0..self.len];
    }

    pub fn append(self: *FlexStdString, item: u8) !void {
        const new_len = self.len + 1;
        if (new_len > self.buf.len) {
            // var new_data: [*c]u8 = undefined;
            // const new_capacity = c.zpp_ss_inc_capacity(
            //     self.ptr,
            //     new_len,
            //     &new_data,
            // );
            // if (new_capacity == 0) return StdStringError.Append;
            // self.buf = new_data[0..new_capacity];
            var new_data: [*c]u8 = undefined;
            var new_capacity: usize = undefined;
            if (!c.zpp_ss_resize(
                self.ptr,
                new_len,
                0,
                true,
                &new_data,
                &new_capacity,
            )) return StdStringError.Append;
            self.buf = new_data[0..new_capacity];
        }
        self.buf[self.len] = item;
        self.len = new_len;
    }

    pub fn appendSlice(self: *FlexStdString, items_: []const u8) !void {
        if (items_.len == 0) return;
        const new_len = self.len + items_.len;
        if (new_len > self.buf.len) {
            // var new_data: [*c]u8 = undefined;
            // const new_capacity = c.zpp_ss_inc_capacity(
            //     self.ptr,
            //     new_len,
            //     &new_data,
            // );
            // if (new_capacity == 0) return StdStringError.Append;
            // self.buf = new_data[0..new_capacity];
            var new_data: [*c]u8 = undefined;
            var new_capacity: usize = undefined;
            if (!c.zpp_ss_resize(
                self.ptr,
                new_len,
                0,
                true,
                &new_data,
                &new_capacity,
            )) return StdStringError.Append;
            self.buf = new_data[0..new_capacity];
        }

        @memcpy(self.buf[self.len .. self.len + items_.len], items_);
        self.len = new_len;
    }

    pub fn appendSliceOpts(
        self: *FlexStdString,
        data: []const u8,
        opts: AppendOpts,
    ) !void {
        if (data.len == 0) {
            if (opts.clear_before_append) self.len = 0;
            return;
        }
        const len = if (opts.clear_before_append) 0 else self.len;
        const new_len = len + data.len;
        if (new_len > self.buf.len) {
            // var new_data: [*c]u8 = undefined;
            // const new_capacity = c.zpp_ss_inc_capacity(
            //     self.ptr,
            //     new_len,
            //     &new_data,
            // );
            // if (new_capacity == 0) return StdStringError.Append;
            // self.buf = new_data[0..new_capacity];
            var new_data: [*c]u8 = undefined;
            var new_capacity: usize = undefined;
            if (!c.zpp_ss_resize(
                self.ptr,
                new_len,
                0,
                true,
                &new_data,
                &new_capacity,
            )) return StdStringError.Append;
            self.buf = new_data[0..new_capacity];
        }

        @memcpy(self.buf[len .. len + data.len], data);
        self.len = new_len;
    }
};

pub fn initFlexStdString(opts: struct {
    min_capacity: usize,
    std_string_ptr: isize = 0,
}) FlexStdString {
    var data: [*c]u8 = undefined;
    var capacity: usize = undefined;
    var ptr: isize = undefined;
    if (opts.std_string_ptr == 0) {
        ptr = c.zpp_ss_new(
            opts.min_capacity,
            true,
            &data,
            &capacity,
        );
    } else {
        ptr = opts.std_string_ptr;
        data = c.zpp_ss_init(
            ptr,
            opts.min_capacity,
            true,
            &capacity,
        );
    }
    return .{
        .ptr = ptr,
        .len = 0,
        .buf = data[0..capacity],
        .owned = opts.std_string_ptr != 0,
    };
}

// --------------------------------------------------
// c calling to zig

export fn zpp_array_list_u8_append_slice(
    list_ptr: ?*anyopaque,
    data: [*c]u8,
    data_len: usize,
) callconv(.C) bool {
    if (list_ptr == null or data == null or data_len < 0) return false;
    if (data_len == 0) return true;

    // var list = @ptrCast(
    //     *std.ArrayList(u8),
    //     @alignCast(@alignOf(*std.ArrayList(u8)),
    //     list_ptr,
    // ));

    var list: *std.ArrayList(u8) = @ptrCast(@alignCast(list_ptr));
    list.appendSlice(data[0..data_len]) catch return false;

    return true;
}

/// Access this variable so the compiler won't skip codegen for this
pub const initialized = !zpp_array_list_u8_append_slice(null, null, 0);
