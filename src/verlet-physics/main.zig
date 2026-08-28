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
    radius: f32,

    pub fn init(pos: rl.Vector2) Ball {
        return Ball{
            .current_pos = pos,
            .old_pos = pos,
            .accel = rl.Vector2.zero(),
            .radius = 10.0,
        };
    }

    pub fn update_positon(self: *Ball, dt: f32) void {
        const vel = self.current_pos.subtract(self.old_pos);

        self.old_pos = self.current_pos;
        self.current_pos =
            self.current_pos.add(vel).add(self.accel.scale(dt * dt));

        self.accel = rl.Vector2.zero();
    }

    pub fn accelerate(self: *Ball, acc: rl.Vector2) void {
        self.accel = self.accel.add(acc);
    }

    pub fn draw(self: Ball) void {
        rl.drawCircleV(self.current_pos, self.radius, BALL_COLOR);
    }

    pub fn move(self: *Ball) void {
        _ = self;
    }
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rand = rng_impl.interface();
    _ = rand;

    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "verlet-physics");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // var balls: [BALL_COUNT]Ball = undefined;
    var balls = try std.ArrayList(Ball).initCapacity(allocator, 100);

    const position = rl.Vector2{
        .x = SCREEN_WIDTH / 2,
        .y = SCREEN_HEIGHT / 2,
    };
    const radius = 300.0;

    while (!rl.windowShouldClose()) {
        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            try balls.append(allocator, Ball.init(rl.getMousePosition()));
        }

        update(balls.items, rl.getFrameTime());

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        rl.drawCircleV(position, radius, .black);

        for (balls.items) |*single| {
            single.*.draw();
        }

        rl.drawText(rl.textFormat("%i FPS", .{rl.getFPS()}), 5, 5, 20, .white);
        rl.drawText(rl.textFormat("BALLS: %i", .{balls.items.len}), 5, 25, 20, .white);
    }
}

fn update(balls: []Ball, dt: f32) void {
    const position = rl.Vector2{
        .x = SCREEN_WIDTH / 2,
        .y = SCREEN_HEIGHT / 2,
    };
    const radius = 300.0;

    const sub_steps = 8.0;
    const sub_dt = dt / sub_steps;

    for (0..sub_steps) |_| {
        applyGravity(balls);
        applyConstraints(balls, position, radius);
        solveCollisions(balls);
        updatePositions(balls, sub_dt);
    }
}

fn applyGravity(balls: []Ball) void {
    for (balls) |*single| {
        single.*.accelerate(GRAVITY);
    }
}

fn updatePositions(balls: []Ball, dt: f32) void {
    for (balls) |*single| {
        single.*.update_positon(dt);
    }
}

fn applyConstraints(balls: []Ball, position: rl.Vector2, radius: f32) void {
    for (balls) |*ball| {
        const to_obj = ball.current_pos.subtract(position);
        const dist = to_obj.length();

        if (dist > radius - ball.radius) {
            const n = to_obj.scale(1 / dist);
            ball.*.current_pos = position.add(n.scale(radius - ball.radius));
        }
    }
}

// fn solveCollisions(balls: []Ball) void {
//     for (balls) |*obj_1| {
//         for (balls) |*obj_2| {
//             const collision_axis = obj_1.current_pos.subtract(obj_2.current_pos);
//             const dist = collision_axis.length();
//             const min_dist = obj_1.radius + obj_2.radius;

//             if (dist < min_dist and dist != 0.0) {
//                 const n = collision_axis.scale(1 / dist);
//                 const delta = min_dist - dist;
//                 obj_1.*.current_pos = obj_1.*.current_pos.add(n.scale(0.5 * delta));
//             }
//         }
//     }
// }

fn solveCollisions(balls: []Ball) void {
    for (balls, 0..) |*obj_1, i| {
        for (balls[i + 1 ..]) |*obj_2| {
            const collision_axis = obj_1.current_pos.subtract(obj_2.current_pos);
            const dist = collision_axis.length();
            const min_dist = obj_1.radius + obj_2.radius;

            if (dist < min_dist and dist != 0.0) {
                const n = collision_axis.scale(1 / dist);
                const delta = min_dist - dist;
                obj_1.current_pos = obj_1.current_pos.add(n.scale(0.5 * delta));
                obj_2.current_pos = obj_2.current_pos.subtract(n.scale(0.5 * delta));
            }
        }
    }
}
