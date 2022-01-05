const std = @import("std");
const zpp = @import("zpp");

const c = @cImport({
    @cInclude("zpp-test.h");
});

fn u8VerifyAppend(
    list_ptr: *std.ArrayList(u8),
    data: [:0]const u8,
    expect: []const u8,
) !void {
    try std.testing.expect(c.call_zpp_array_list_u8_append(
        list_ptr,
        data,
        data.len,
    ));
    try std.testing.expectEqualSlices(u8, expect, list_ptr.items);
}

test "ArrayList.append" {
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
    
    const initial_capacity = 512;
    var buf = zpp.initStdString(initial_capacity);
    defer buf.deinit();
    
    const actual_capacity = buf.capacity();
    try std.testing.expect(actual_capacity > 1);
    try std.testing.expect(0 == buf.size());
    
    try std.testing.expect(buf.append("foo", false));
    try std.testing.expect(3 == buf.size());
    try std.testing.expect(buf.append("bar", false));
    try std.testing.expect(6 == buf.size());
    
    try std.testing.expect(buf.append("baz", true));
    try std.testing.expect(3 == buf.size());
    try std.testing.expect(buf.clear());
    try std.testing.expect(0 == buf.size());
    
    // resize
    try std.testing.expect(buf.resize(1, 'a'));
    try std.testing.expect(1 == buf.size());
    // verify that capacity is unchanged
    try std.testing.expect(actual_capacity == buf.capacity());
    
    const slice = try buf.asSlice();
    try std.testing.expect(1 == slice.len);
    try std.testing.expect('a' == slice[0]);
    
    std.debug.print(
        "std::string api ok | capacity default: {}, set({}): {}\n",
        .{ def.capacity(), initial_capacity, actual_capacity },
    );
}
