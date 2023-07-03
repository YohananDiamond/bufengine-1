const Self = @This();

is_active: bool = true,
last_message: [:0]const u8 = "Welcome!",

pub fn init() Self {
    return Self{};
}

pub fn deinit(self: *Self) void {
    self.* = undefined;
}

pub const actions = struct {
    pub fn quit(editor: *Self) void {
        editor.is_active = false;
    }
};
