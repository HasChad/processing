const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

pub const SCREEN_W = 800;
pub const SCREEN_H = 600;

pub const rosepine = struct {
    pub const base = rl.Color.init(25, 23, 36, 255);
    pub const surface = rl.Color.init(31, 29, 46, 255);
    pub const overlay = rl.Color.init(38, 35, 58, 255);
    pub const muted = rl.Color.init(110, 106, 134, 255);
    pub const subtle = rl.Color.init(144, 140, 170, 255);
    pub const text = rl.Color.init(224, 222, 244, 255);
    pub const love = rl.Color.init(235, 111, 146, 255);
    pub const gold = rl.Color.init(246, 193, 119, 255);
    pub const rose = rl.Color.init(235, 188, 186, 255);
    pub const pine = rl.Color.init(49, 116, 143, 255);
    pub const foam = rl.Color.init(156, 207, 216, 255);
    pub const iris = rl.Color.init(196, 167, 231, 255);
    pub const highlight_low = rl.Color.init(33, 32, 46, 255);
    pub const highlight_med = rl.Color.init(64, 61, 82, 255);
    pub const highlight_high = rl.Color.init(82, 79, 103, 255);
};

pub fn getRainbow(dt: f32) rl.Color {
    const r = std.math.sin(dt);
    const g = std.math.sin(dt + 0.33 * 2.0 * std.math.pi);
    const b = std.math.sin(dt + 0.66 * 2.0 * std.math.pi);

    return rl.Color.init(
        @intFromFloat(r * r * 255),
        @intFromFloat(g * g * 255),
        @intFromFloat(b * b * 255),
        255,
    );
}

pub fn drawFPS() void {
    rl.drawText(rl.textFormat("%i FPS", .{rl.getFPS()}), 5, 5, 20, rosepine.iris);
}

pub fn colorButton(bounds: rl.Rectangle, text: [:0]const u8, color: rl.Color) bool {
    const props = [_]rg.ControlProperty{
        .border_color_normal,  .base_color_normal,  .text_color_normal,
        .border_color_focused, .base_color_focused, .text_color_focused,
        .border_color_pressed, .base_color_pressed, .text_color_pressed,
    };

    const border = color.brightness(-0.3);
    const values = [_]rl.Color{
        border, color,                  rosepine.base,
        border, color.brightness(0.2),  rosepine.base,
        border, color.brightness(-0.2), rosepine.base,
    };

    var old: [props.len]i32 = undefined;
    for (props, 0..) |p, i| old[i] = rg.getStyle(.button, p);
    defer {
        for (props, 0..) |p, i| rg.setStyle(.button, p, old[i]);
    }

    for (props, values) |p, v| rg.setStyle(.button, p, rl.colorToInt(v));

    return rg.button(bounds, text);
}
