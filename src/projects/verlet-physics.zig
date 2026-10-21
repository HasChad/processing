const std = @import("std");
const rl = @import("raylib");
const c = @import("../common.zig");

const GRAVITY = rl.Vector2{
    .x = 0,
    .y = 1000.0,
};

const Ball = struct {
    current_pos: rl.Vector2,
    old_pos: rl.Vector2,
    accel: rl.Vector2,
    radius: f32,
    color: rl.Color,

    pub fn init(pos: rl.Vector2, color: rl.Color) Ball {
        const current_pos = rl.Vector2.init(pos.x, pos.y + 3);

        return Ball{
            .current_pos = current_pos,
            .old_pos = pos,
            .accel = rl.Vector2.zero(),
            .radius = 5.0,
            .color = color,
        };
    }

    pub fn initRandom(pos: rl.Vector2, color: rl.Color, rand: std.Random) Ball {
        const current_pos = rl.Vector2.init(pos.x, pos.y + 5);

        return Ball{
            .current_pos = current_pos,
            .old_pos = pos,
            .accel = rl.Vector2.zero(),
            .radius = rand.float(f32) * 7 + 3,
            .color = color,
        };
    }

    pub fn initSpeed(pos: rl.Vector2, vec: rl.Vector2, color: rl.Color, rand: std.Random) Ball {
        const current_pos = pos.add(vec);

        return Ball{
            .current_pos = current_pos,
            .old_pos = pos,
            .accel = rl.Vector2.zero(),
            .radius = rand.float(f32) * 7 + 3,
            .color = color,
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
        rl.drawCircleV(self.current_pos, self.radius, self.color);
    }

    pub fn move(self: *Ball) void {
        _ = self;
    }
};

pub fn run(rand: std.Random) anyerror!void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var enableShooter = false;
    var balls = try std.ArrayList(Ball).initCapacity(allocator, 100);

    const position = rl.Vector2{
        .x = c.SCREEN_WIDTH / 2,
        .y = c.SCREEN_HEIGHT / 2,
    };
    const radius = 300.0;

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            enableShooter = !enableShooter;
        }

        const shooter_time: f32 = @floatCast(rl.getTime());
        if (enableShooter) {
            const max_angle = std.math.pi / 4.0; // 45 swing each side
            const swing_speed = 2.0;
            const angle = std.math.sin(shooter_time * swing_speed) * max_angle;

            // angle = 0 -> straight down. Rotate around that.
            const dir = rl.Vector2.init(@sin(angle), @cos(angle));
            const speed = 2.5;
            const vec = dir.scale(speed);

            try balls.append(allocator, Ball.initSpeed(
                rl.Vector2.init(c.SCREEN_WIDTH / 2, 50),
                vec,
                c.getRainbow(shooter_time),
                rand,
            ));
        }

        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            try balls.append(allocator, Ball.init(rl.getMousePosition(), c.rosepine.text));
        }

        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            try balls.append(allocator, Ball.init(rl.getMousePosition(), c.rosepine.text));
        }

        update(balls.items, rl.getFrameTime());

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(c.rosepine.base);

        rl.drawCircleV(position, radius, .black);

        for (balls.items) |*single| {
            single.*.draw();
        }

        c.drawFPS();
        rl.drawText(rl.textFormat("BALLS: %i", .{balls.items.len}), 5, 25, 20, .white);
    }
}

fn update(balls: []Ball, dt: f32) void {
    const position = rl.Vector2{
        .x = c.SCREEN_WIDTH / 2,
        .y = c.SCREEN_HEIGHT / 2,
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
