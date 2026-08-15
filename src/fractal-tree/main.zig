const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

const screenWidth = 800;
const screenHeight = 600;
const bg_color = rl.Color{ .a = 255, .r = 25, .g = 23, .b = 36 };
const branch_color = rl.Color{ .a = 255, .r = 224, .g = 222, .b = 244 };

const LEN_MUL = 0.82;

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "fractal-tree");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const origin = rl.Vector2{
        .x = screenWidth / 2,
        .y = screenHeight,
    };
    const rot: f32 = 0;
    var add_rot: f32 = 30;
    var count: f32 = 12;

    while (!rl.windowShouldClose()) {

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bg_color);

        drawBranch(origin, 100, count, rot, add_rot);
        renderUI(&add_rot, &count);
    }
}

fn drawBranch(start: rl.Vector2, len: f32, count: f32, rot: f32, add_rot: f32) void {
    var end = start;
    end.y -= len;

    const x = end.x - start.x;
    const y = end.y - start.y;

    const rad = std.math.degreesToRadians(rot);

    end.x = x * @cos(rad) - y * @sin(rad) + start.x;
    end.y = x * @sin(rad) + y * @cos(rad) + start.y;

    rl.drawLineV(start, end, branch_color);

    if (count - 1 > 0 and len > 1.0) {
        drawBranch(end, len * LEN_MUL, count - 1, rot + add_rot, add_rot);
        drawBranch(end, len * LEN_MUL, count - 1, rot - add_rot, add_rot);
    }
}

fn renderUI(add_rot: *f32, count: *f32) void {
    _ = rg.sliderBar(
        rl.Rectangle{
            .x = 50,
            .y = 5,
            .width = 100,
            .height = 20,
        },

        "Rotation",
        rl.textFormat("%.2", .{add_rot}),
        &add_rot.*,
        0,
        90,
    );

    _ = rg.sliderBar(
        rl.Rectangle{
            .x = 50,
            .y = 30,
            .width = 100,
            .height = 20,
        },

        "Count",
        rl.textFormat("%.2", .{count}),
        &count.*,
        0,
        20,
    );
}
