const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const BG_COLOR = rl.Color{ .r = 25, .g = 23, .b = 36, .a = 255 };
const BALL_COLOR = rl.Color{ .r = 224, .g = 222, .b = 244, .a = 255 };
const BALL_COUNT = 1;

const GRAVITY = rl.Vector2{
    .x = 0,
    .y = 1000.0,
};

const Ball = struct {
    current_pos: rl.Vector2,
    old_pos: rl.Vector2,
    accel: rl.Vector2,

    pub fn init(rand: std.Random) Ball {
        _ = rand;

        const pos = rl.Vector2{
            .x = SCREEN_WIDTH / 2,
            .y = 50,
        };

        return Ball{
            .current_pos = pos,
            .old_pos = pos,
            .accel = rl.Vector2.zero(),
        };
    }

    pub fn update_positon(self: *Ball) void {
        const vel = self.current_pos.subtract(self.old_pos);

        self.old_pos = self.current_pos;
        self.current_pos = self.current_pos.add(vel).add(self.accel.scale(rl.getFrameTime() * rl.getFrameTime()));

        self.accel = rl.Vector2.zero();
    }

    pub fn accelerate(self: *Ball, acc: rl.Vector2) void {
        self.accel = self.accel.add(acc);
    }

    pub fn draw(self: Ball) void {
        rl.drawCircleV(self.current_pos, 50.0, BALL_COLOR);
    }

    pub fn move(self: *Ball) void {
        _ = self;
    }
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "verlet-physics");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var balls: [BALL_COUNT]Ball = undefined;

    const positon = rl.Vector2{
        .x = SCREEN_WIDTH / 2,
        .y = SCREEN_HEIGHT / 2,
    };
    const radius = 300.0;

    for (&balls) |*single| {
        single.* = Ball.init(rand);
    }

    while (!rl.windowShouldClose()) {
        // apply gravity
        for (&balls) |*single| {
            single.*.accelerate(GRAVITY);
        }

        // apply constraints
        for (&balls) |*ball| {
            const to_obj = ball.current_pos.subtract(positon);
            const dist = to_obj.length();

            if (dist > radius - 50.0) {
                const n = to_obj.scale(1 / dist);
                ball.*.current_pos = positon.add(n.scale(dist - 50.0));
            }
        }

        // update positons
        for (&balls) |*single| {
            single.*.update_positon();
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        rl.drawCircleV(positon, radius, .black);

        for (&balls) |*single| {
            single.*.draw();
        }
    }
}
