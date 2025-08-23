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
    try std.testing.expect(c.call_zpp_array_list_u8_append_slice(
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
    try buf.appendSliceOpts("bar", .{});
    try std.testing.expect(6 == buf.size());
    try std.testing.expectEqualSlices(u8, "foobar", buf.items());

    try buf.appendSliceOpts("baz!", .{ .clear_before_append = true });
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

test "ArrayList.appendSlice from c" {
    var buf = std.ArrayList(u8).init(std.testing.allocator);
    defer buf.deinit();

    // explicity call so it would be included by the compiler
    try std.testing.expect(zpp.initialized);

    try u8VerifyAppend(&buf, "foo", "foo");
    try u8VerifyAppend(&buf, "bar", "foobar");

    std.debug.print("ok\n", .{});
}

test "StdString api" {
    var def = zpp.initStdString(.{
        .min_capacity = 0,
    });
    defer def.deinit();

    const min_capacity: usize = 512;
    var buf = zpp.initStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    const actual_capacity = buf.capacity();
    try verifyStdString(&buf);

    std.debug.print(
        "ok\n  - capacity default: {}, min: {}, actual: {}\n",
        .{ def.capacity(), min_capacity, actual_capacity },
    );
}

test "StdString.append" {
    const min_capacity: usize = 64;
    var buf = zpp.initStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    try buf.append('a');
    try buf.append('b');
    try buf.append('c');
    try std.testing.expectEqualSlices(u8, "abc", buf.items());
}

test "FlexStdString api" {
    const capacity: usize = 512;
    var buf = zpp.initFlexStdString(.{
        .min_capacity = 512,
    });
    defer buf.deinit();

    const actual_capacity = buf.capacity();
    try verifyStdString(&buf);

    std.debug.print(
        "ok\n  - capacity min: {}, actual: {}\n",
        .{ capacity, actual_capacity },
    );
}

test "FixedStdString api" {
    const capacity: usize = 512;
    var buf = zpp.initFixedStdString(.{
        .capacity = capacity,
        .use_actual = false,
    });
    defer buf.deinit();

    try std.testing.expect(capacity == buf.capacity());
    try verifyStdString(&buf);

    std.debug.print(
        "ok\n  - capacity: {}\n",
        .{capacity},
    );
}

test "StdString small capacity" {
    const min_capacity: usize = 64;
    var buf = zpp.initStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    const actual_capacity = buf.capacity();

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const to_append = "1234567890";
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        try buf.appendSlice(to_append);
        try list.appendSlice(to_append);

        const b_items = buf.items();
        const l_items = list.items;

        try std.testing.expectEqualSlices(u8, l_items, b_items);
    }

    std.debug.print(
        "ok\n  - capacity min: {}, actual: {}, current: {}\n",
        .{ min_capacity, actual_capacity, buf.capacity() },
    );
}

test "FlexStdString small capacity" {
    const min_capacity: usize = 64;
    var buf = zpp.initFlexStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    const actual_capacity = buf.capacity();

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const to_append = "1234567890";
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        try buf.appendSlice(to_append);
        try list.appendSlice(to_append);

        const b_items = buf.items();
        const l_items = list.items;

        //std.debug.print("\niteration: {}\n{s}\n{s}\n", .{ i, b_items, l_items });
        try std.testing.expectEqualSlices(u8, l_items, b_items);
    }

    std.debug.print(
        "ok\n  - capacity min: {}, actual: {}, current: {}\n",
        .{ min_capacity, actual_capacity, buf.capacity() },
    );
}

test "FixedStdString.appendSlice overflow" {
    const min_capacity: usize = 16;
    var buf = zpp.initFixedStdString(.{
        .capacity = min_capacity,
        .use_actual = false,
    });
    defer buf.deinit();

    const to_append = "1234567890";
    try buf.appendSlice(to_append);
    buf.appendSlice(to_append) catch |e| {
        try std.testing.expect(e == zpp.StdStringError.Append);
        std.debug.print("ok\n", .{});
        return;
    };
    try std.testing.expect(false);
}

test "FixedStdString.append" {
    const min_capacity: usize = 16;
    var buf = zpp.initFixedStdString(.{
        .capacity = min_capacity,
        .use_actual = true,
    });
    defer buf.deinit();

    const to_append = "1234567890";
    try buf.appendSlice(to_append);
    try buf.append('a');
    try buf.append('b');
    try buf.append('c');

    try std.testing.expectEqual(to_append.len + 3, buf.len);
    try std.testing.expectEqual('c', buf.items()[buf.len - 1]);
    try std.testing.expectEqualSlices(u8, "abc", buf.items()[buf.len - 3 ..]);
}

test "FixedStdString.append overflow" {
    const min_capacity: usize = 16;
    var buf = zpp.initFixedStdString(.{
        .capacity = min_capacity,
        .use_actual = true,
    });
    defer buf.deinit();

    for (0..buf.capacity()) |_| try buf.append('a');

    buf.append('a') catch |e| {
        try std.testing.expect(e == zpp.StdStringError.Append);
        return;
    };
    try std.testing.expect(false);
}

test "FlexStdString.append" {
    const min_capacity: usize = 16;
    var buf = zpp.initFlexStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    const to_append = "1234567890";
    try buf.appendSlice(to_append);
    try buf.append('a');
    try buf.append('b');
    try buf.append('c');

    try std.testing.expectEqual(to_append.len + 3, buf.len);
    try std.testing.expectEqual('c', buf.items()[buf.len - 1]);
    try std.testing.expectEqualSlices(u8, "abc", buf.items()[buf.len - 3 ..]);
}

test "FlexStdString.append overflow" {
    const min_capacity: usize = 16;
    var buf = zpp.initFlexStdString(.{
        .min_capacity = min_capacity,
    });
    defer buf.deinit();

    for (0..buf.capacity()) |_| try buf.append('a');

    try buf.append('b');
    try buf.append('c');

    try std.testing.expectEqual('c', buf.items()[buf.len - 1]);
    try std.testing.expectEqualSlices(u8, "abc", buf.items()[buf.len - 3 ..]);
}
