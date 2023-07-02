// TODO: separate terminal output from input handling (different files)

const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("termios.h");
});

const key = @import("key.zig");
const Keycode = key.Keycode;

comptime {
    switch (builtin.os.tag) {
        .linux => {},
        else => |tag| @compileError("Unsupported OS: " ++ @tagName(tag)),
    }
}

pub const TermiosErr = error{TermiosErr}; // TODO: make this more sophisticated
pub const Termios = c.termios;

pub const GetKeyError = error{
    ReadError,
};

pub const Kind = enum {
    posix,
};

// TODO: refactor this to a bunch of different impls of TerminalAPI that have functions for each thing. For example, a
// NCursesAPI and a XorgAPI.
pub fn Terminal(comptime _: Kind) type {
    return struct {
        input_stream: std.fs.File,
        output_stream: std.fs.File,
        orig_termios: ?Termios,
        raw_termios: ?Termios,
        raw_mode_enabled: bool,

        const Self = @This();

        pub fn init(input_stream: std.fs.File, output_stream: std.fs.File) TermiosErr!Self {
            var self = Self{
                .input_stream = input_stream,
                .output_stream = output_stream,
                .orig_termios = null,
                .raw_termios = null,
                .raw_mode_enabled = false,
            };

            try self.rawModeEnable();

            return self;
        }

        pub fn deinit(self: *Self) TermiosErr!void {
            try self.rawModeDisable();
        }

        /// Blocks the program until a key press is received.
        ///
        /// Might (and probably will) read more than one character from
        /// `input_stream`, so it can be able to read escape codes.
        pub fn getKey(self: *Self) GetKeyError!Keycode {
            while (true) {
                const ch = blk: {
                    var buf: [1]u8 = undefined;
                    _ = self.input_stream.read(&buf) catch
                        return GetKeyError.ReadError;
                    break :blk buf[0];
                };

                if (ch != 170)
                    return ch;
            }
        }

        // fn setKeyPressThreshold(self: *Self, threshold: usize) error{NotOnRawMode}!void {
        //     unreachable;
        // }

        fn getOrigTermios(self: *Self) TermiosErr!Termios {
            return self.orig_termios orelse blk: {
                var termios: Termios = undefined;

                const result = c.tcgetattr(c.STDIN_FILENO, &termios);
                if (result == -1) return error.TermiosErr;

                self.orig_termios = termios;
                break :blk termios;
            };
        }

        fn getRawTermios(self: *Self) TermiosErr!Termios {
            if (self.raw_termios) |termios|
                return termios;

            var r = try self.getOrigTermios();

            // lflags disabled:
            // ECHO: terminal printing pressed keys
            // ICANON: canonical mode (line-by-line reading / buffering)
            // ISIG: handling of SIGINT (Ctrl-C) and SIGTSTP (Ctrl-Z)
            // IEXTEN: literal character insertion (Ctrl-V)
            //
            // iflags disabled:
            // IXON: software flow control (Ctrl-S & Ctrl-Q)
            // ICRNL: convert '\r' (Ctrl-M) to '\n' (Ctrl-J)
            // BRKINT: convert break conditions to SIGINTs
            // INPCK: parity checking (?)
            // ISTRIP: strip the 8th bit of each input byte, setting it to 0
            //
            // oflags disabled:
            // OPOST: auto convert "\n" to "\r\n" on output
            //
            // CS8 is a mask to set the character size to 8 bits per byte
            r.c_iflag &= ~@as(u32, c.ICRNL | c.IXON | c.BRKINT | c.INPCK | c.ISTRIP);
            r.c_oflag &= ~@as(u32, c.OPOST);
            r.c_cflag |= ~@as(u32, c.CS8);
            r.c_lflag &= ~@as(u32, c.ECHO | c.ICANON | c.ISIG | c.IEXTEN);
            r.c_cc[c.VMIN] = 0; // max number of bytes of input buffered on input
            r.c_cc[c.VTIME] = 1; // max time for read() to return; 10 is one second

            self.raw_termios = r;

            return r;
        }

        pub fn rawModeEnable(self: *Self) TermiosErr!void {
            const termios = try self.getRawTermios();

            const result = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &termios);
            if (result == -1) return error.TermiosErr;

            self.raw_mode_enabled = true;
        }

        pub fn rawModeDisable(self: *Self) TermiosErr!void {
            const termios = try self.getOrigTermios();

            const result = c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &termios);
            if (result == -1) return error.TermiosErr;

            self.raw_mode_enabled = false;
        }
    };
}
