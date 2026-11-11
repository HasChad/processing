const std = @import("std");
const rl = @import("raylib");
const c = @import("../common.zig");
const rp = c.rosepine;

pub fn run(rand: std.Random) anyerror!void {
    _ = rand; // autofix
    while (!rl.windowShouldClose() and !rl.isKeyPressed(.q)) {
        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rp.base);

        c.drawFPS();
    }
}
