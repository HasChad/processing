const std = @import("std");
const rl = @import("raylib");
const c = @import("common.zig");

const canvas_w: u32 = 80;
const canvas_h: u32 = 60;
const scale: u32 = 10;

pub fn run(rand: std.Random) anyerror!void {
    _ = rand;

    const tex = try rl.loadTextureFromImage(rl.genImageColor(canvas_w, canvas_h, .black));

    var play_sim = false;
    var cells: [canvas_w * canvas_h]u8 = std.mem.zeroes([canvas_w * canvas_h]u8);
    var pixels: [canvas_w * canvas_h]rl.Color = undefined;

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        const m_pos = rl.getMousePosition();

        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            switch (play_sim) {
                true => {
                    play_sim = false;
                    std.debug.print("Pause\n", .{});
                },
                false => {
                    play_sim = true;
                    std.debug.print("Play\n", .{});
                },
            }
        }

        if (play_sim) {
            // simulation
        }

        // cell update
        if (rl.isMouseButtonDown(rl.MouseButton.left) and m_pos.x < c.SCREEN_WIDTH and m_pos.x > 0 and m_pos.y < c.SCREEN_HEIGHT and m_pos.y > 0) {
            const x: usize = @trunc(rl.getMousePosition().x / scale);
            const y: usize = @trunc(rl.getMousePosition().y / scale);

            cells[y * canvas_w + x] = 1;
        }

        // pixel color update
        for (cells, 0..) |cell, i| {
            pixels[i] = if (cell != 0) .white else .black;
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.updateTexture(tex, &pixels);
        rl.drawTextureEx(tex, rl.Vector2.init(0, 0), 0, scale, .white);

        c.drawFPS();
    }
}
