const std = @import("std");

const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("termios.h");
});

comptime {
    switch (std.Target.current.os.tag) {
        .linux => {},
        else => |tag| @compileError("Unsupported OS: " ++ @tagName(tag)),
    }
}

pub const TerminalKind = enum {
    posix,
};

pub const TermiosErr = error{TermiosErr}; // TODO: make this more sophisticated
pub const Termios = c.termios;

pub const GetKeyError = error{
    StreamClosed,
    UnknownSequence,
};

pub const Keycode = enum {
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    dot,
    colon,
    semicolon,
    comma,
    less_than,
    greater_than,
    up,
    down,
    left,
    right,
};

pub const Key = union(enum) {
    ctrl: Keycode,
    ctrl_meta: Keycode,
    meta: Keycode,
    alone: Keycode,
};

// TODO: `kind` might not need to be compile time at some time.
pub fn Terminal(comptime kind: TerminalKind) type {
    return struct {
        const Self = @This();

        stdin: std.fs.File,
        stdout: std.fs.File,

        orig_termios: ?Termios,
        raw_termios: ?Termios,
        raw_mode_enabled: bool,

        pub fn init() Self {
            return .{
                .stdin = std.io.getStdIn(),
                .stdout = std.io.getStdOut(),
                .orig_termios = null,
                .raw_termios = null,
                .raw_mode_enabled = false,
            };
        }

        pub fn deinit(self: *Self) void {
            self.rawModeDisable();
        }

        /// Blocks the program until a key press is received.
        ///
        /// Might (and probably will) read more than one character from
        /// `stdin`, so it can be able to read escape codes.
        pub fn getKey(self: *Self) GetKeyError!Key {
            unreachable;
        }

        fn setKeyPressThreshold(self: *Self, threshold: usize) error{NotOnRawMode}!void {}

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
            return self.raw_termios orelse blk: {
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
                var r = try self.getOrigTermios();
                r.c_iflag &= ~(@as(u32, c.ICRNL) | c.IXON | c.BRKINT | c.INPCK | c.ISTRIP);
                r.c_oflag &= ~(@as(u32, c.OPOST));
                r.c_cflag |= ~(@as(u32, c.CS8));
                r.c_lflag &= ~(@as(u32, c.ECHO) | c.ICANON | c.ISIG | c.IEXTEN);
                r.c_cc[c.VMIN] = 0; // max number of bytes of input buffered on input
                r.c_cc[c.VTIME] = 1; // max time for read() to return; 10 is one second

                self.raw_termios = r;
                break :blk r;
            };
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
