const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn genDeinitFull(comptime T: type, comptime mappings: anytype) (fn (*T, Allocator) void) {
    // TODO: cleanup and document
    // TODO: context management (refer to odin's context system)
    // TODO: error on fields from `mappings` that don't exist

    return struct {
        pub fn deinitFull(self: *T, alloc: Allocator) void {
            inline for (comptime std.meta.fieldNames(T)) |name| {
                const value = @field(mappings, name);

                switch (@typeInfo(@TypeOf(value))) {
                    .Fn => value(&@field(self, name), alloc),
                    .EnumLiteral => switch (value) {
                        .ignore => {},
                        .deinitShallow => if (hasField(T, name)) {
                            @field(self, name).deinit(alloc);
                        } else {
                            @compileError("TODO:name");
                        },
                        .auto => if (hasField(T, name)) {
                            @field(self, name).deinitFull(alloc);
                        } else {
                            @compileError("TODO:name");
                        },
                        else => |h| @compileError("unknown value: " ++ h),
                    },
                    else => |h| @compileError("unknown value: " ++ h),
                }
            }
            self.* = undefined;
        }
    }.deinitFull;
}

pub fn hasField(comptime T: type, comptime field: []const u8) bool {
    for (std.meta.fieldNames(T)) |name| {
        if (std.mem.eql(u8, name, field)) return true;
    }
    return false;
}
