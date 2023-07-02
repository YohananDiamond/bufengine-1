is_active: bool = true,

const Self = @This();

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
