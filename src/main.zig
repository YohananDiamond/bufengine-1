const std = @import("std");
const terminal = @import("terminal.zig");

pub fn main() anyerror!void {
    var term = terminal.Terminal(.posix).init();
    defer term.deinit() catch |err| switch (err) {
        error.TermiosErr => std.debug.print("Warning - failed to disable raw mode. Your terminal might appear glitchy.\n", .{}),
    };

    while (true) {
        const key = term.getKey();



//         var input: [1]u8 = undefined;
//         _ = try stdin.read(&input);

//         switch (input[0]) {
//             3 => break,
//             170 => {
//                 _ = try stdout.write("~TIMEOUT~\r\n");
//                 continue;
//             },
//             else => {},
//         }

//         std.debug.print("<< {c} >>\r\n", .{input[0]});
    }
}
