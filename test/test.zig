const std = @import("std");
const zpp = @import("zpp");

const c = @cImport({
    @cInclude("zpp-test.h");
});

fn u8VerifyAppend(
    list: *std.ArrayList(u8),
    data: [:0]const u8,
    expect: []const u8,
) !void {
    try std.testing.expect(c.call_zpp_array_list_u8_append(
        list,
        data,
        data.len,
    ));
    try std.testing.expectEqualSlices(u8, expect, list.items);
}

fn verifyStdString(buf: anytype) !void {
    const actual_capacity = buf.capacity();
    try std.testing.expect(actual_capacity > 1);
    try std.testing.expect(0 == buf.size());
    
    try buf.appendSlice("foo");
    try std.testing.expect(3 == buf.size());
    try buf.append("bar", false);
    try std.testing.expect(6 == buf.size());
    try std.testing.expectEqualSlices(u8, "foobar", buf.items());
    
    try buf.append("baz!", true);
    try std.testing.expect(4 == buf.size());
    buf.clearRetainingCapacity();
    try std.testing.expect(0 == buf.size());
    
    // resize
    try buf.resize(3);
    var items = buf.items();
    try std.testing.expect(3 == buf.size());
    // verify that capacity is unchanged
    try std.testing.expect(actual_capacity == buf.capacity());
    try std.testing.expect(3 == items.len);
    try std.testing.expect(0 == items[0]);
    try std.testing.expect(0 == items[1]);
    try std.testing.expect(0 == items[2]);
    
    try buf.resizeAndFill(4, 'a');
    items = buf.items();
    try std.testing.expect(4 == buf.size());
    // verify that capacity is unchanged
    try std.testing.expect(actual_capacity == buf.capacity());
    try std.testing.expect(4 == items.len);
    try std.testing.expect(0 == items[0]);
    try std.testing.expect(0 == items[1]);
    try std.testing.expect(0 == items[2]);
    try std.testing.expect('a' == items[3]);
    
    try buf.resizeAndFill(5, 'z');
    items = buf.items();
    try std.testing.expect(5 == buf.size());
    try std.testing.expect(5 == items.len);
    try std.testing.expect(0 == items[0]);
    try std.testing.expect(0 == items[1]);
    try std.testing.expect(0 == items[2]);
    try std.testing.expect('a' == items[3]);
    try std.testing.expect('z' == items[4]);
    
    try buf.resize(7);
    items = buf.items();
    try std.testing.expect(7 == buf.size());
    try std.testing.expect(7 == items.len);
    try std.testing.expect(0 == items[0]);
    try std.testing.expect(0 == items[1]);
    try std.testing.expect(0 == items[2]);
    try std.testing.expect('a' == items[3]);
    try std.testing.expect('z' == items[4]);
    try std.testing.expect(0 == items[5]);
    try std.testing.expect(0 == items[6]);
    
    try buf.resizeAndFill(4, 'g');
    items = buf.items();
    try std.testing.expect(4 == buf.size());
    try std.testing.expect(4 == items.len);
    try std.testing.expect(0 == items[0]);
    try std.testing.expect(0 == items[1]);
    try std.testing.expect(0 == items[2]);
    try std.testing.expect('a' == items[3]);
}

test "ArrayList.append (from c)" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();
    
    // explicity call so it would be included by the compiler 
    try std.testing.expect(zpp.initialized);
    
    try u8VerifyAppend(&buf, "foo", "foo");
    try u8VerifyAppend(&buf, "bar", "foobar");
    
    std.debug.print("ArrayList.append ok\n", .{});
}

test "std::string api" {
    var def = zpp.initStdString(0);
    defer def.deinit();
    
    const min_capacity = 512;
    var buf = zpp.initStdString(min_capacity);
    defer buf.deinit();
    
    const actual_capacity = buf.capacity();
    try verifyStdString(&buf);
    
    std.debug.print(
        "std::string api ok | capacity default: {}, min: {}, actual: {}\n",
        .{ def.capacity(), min_capacity, actual_capacity },
    );
}

test "std::string (fixed) api" {
    const capacity = 512;
    var buf = zpp.initFixedStdString(capacity, false);
    defer buf.deinit();
    
    try std.testing.expect(capacity == buf.capacity());
    try verifyStdString(&buf);
    
    std.debug.print(
        "std::string (fixed) ok | capacity: {}\n",
        .{ capacity },
    );
}

test "std::string (flex) api" {
    const capacity = 512;
    var buf = zpp.initFlexStdString(capacity);
    defer buf.deinit();
    
    const actual_capacity = buf.capacity();
    try verifyStdString(&buf);
    
    std.debug.print(
        "std::string (flex) ok | capacity min: {}, actual: {}\n",
        .{ capacity, actual_capacity },
    );
}

test "std::string small capacity" {
    const min_capacity = 64;
    var buf = zpp.initStdString(min_capacity);
    defer buf.deinit();
    
    const actual_capacity = buf.capacity();
    
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    
    const to_append = "1234567890";
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try buf.appendSlice(to_append);
        try list.appendSlice(to_append);
    }
    
    try std.testing.expectEqualSlices(u8, list.items, buf.items());
    
    std.debug.print(
        "std::string small capacity ok | capacity min: {}, actual: {}, current: {}\n",
        .{ min_capacity, actual_capacity, buf.capacity() },
    );
}

test "std::string (flex) small capacity" {
    const min_capacity = 64;
    var buf = zpp.initStdString(min_capacity);
    defer buf.deinit();
    
    const actual_capacity = buf.capacity();
    
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    
    const to_append = "1234567890";
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try buf.appendSlice(to_append);
        try list.appendSlice(to_append);
    }
    
    try std.testing.expectEqualSlices(u8, list.items, buf.items());
    
    std.debug.print(
        "std::string (flex) small capacity ok | capacity min: {}, actual: {}, current: {}\n",
        .{ min_capacity, actual_capacity, buf.capacity() },
    );
}
