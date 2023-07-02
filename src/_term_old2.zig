const std = @import("std");
const File = std.fs.File;

pub fn Terminal(comptime Impl: type) type {
    return struct {
        in_stream: File,
        out_stream: File,
        impl: Impl,

        const Self = @This();

        pub fn init(in_stream: File, out_stream: File) Impl.InitError!Self {
            return Self{
                .impl = Impl.init(in_stream, out_stream),
            };

            return self.impl.
            return Self{
            };
        }

        pub fn deinit(self: *Self) Impl.DeinitError!void {

        }

        pub fn waitForKey(self: *Self) Keycode {
            return self.impl.waitForKey();
        }
    };
}
