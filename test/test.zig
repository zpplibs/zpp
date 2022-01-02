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
}