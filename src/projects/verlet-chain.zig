const std = @import("std");
const rl = @import("raylib");
const c = @import("../common.zig");
const rp = c.rosepine;

const GRAVITY = rl.Vector2{
    .x = 0,
    .y = 1000.0,
};

const Ball = struct {
    current_pos: rl.Vector2,
    old_pos: rl.Vector2,
    accel: rl.Vector2,
    radius: f32,
    pinned: bool,
    color: rl.Color,

    pub fn init(pos: rl.Vector2, color: rl.Color) Ball {
        const current_pos = rl.Vector2.init(pos.x, pos.y);

        return Ball{
            .current_pos = current_pos,
            .old_pos = pos,
            .accel = rl.Vector2.zero(),
            .radius = 10.0,
            .pinned = false,
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
            .pinned = false,
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
            .pinned = false,
            .color = color,
        };
    }

    pub fn update_positon(self: *Ball, dt: f32) void {
        if (self.pinned) {
            self.accel = rl.Vector2.zero();
            return;
        }

        const vel = self.current_pos.subtract(self.old_pos);

        self.old_pos = self.current_pos;
        self.current_pos =
            self.current_pos.add(vel).add(self.accel.scale(dt * dt));

        self.accel = rl.Vector2.zero();
    }

    pub fn accelerate(self: *Ball, acc: rl.Vector2) void {
        if (self.pinned) return;
        self.accel = self.accel.add(acc);
    }

    pub fn draw(self: Ball) void {
        rl.drawCircleV(self.current_pos, self.radius, self.color);
    }

    pub fn move(self: *Ball) void {
        _ = self;
    }
};

const Link = struct {
    ball_1: usize,
    ball_2: usize,
    target_dist: f32,

    pub fn apply(self: Link, balls: []Ball) void {
        const obj_1 = &balls[self.ball_1];
        const obj_2 = &balls[self.ball_2];

        const axis = obj_1.current_pos.subtract(obj_2.current_pos);
        const dist = axis.length();
        const n = axis.scale(1 / dist);
        const delta = self.target_dist - dist;

        if (obj_1.pinned and obj_2.pinned) {
            return;
        } else if (obj_1.pinned) {
            obj_2.current_pos = obj_2.current_pos.subtract(n.scale(delta));
        } else if (obj_2.pinned) {
            obj_1.current_pos = obj_1.current_pos.add(n.scale(delta));
        } else {
            obj_1.current_pos = obj_1.current_pos.add(n.scale(0.5 * delta));
            obj_2.current_pos = obj_2.current_pos.subtract(n.scale(0.5 * delta));
        }
    }
};

pub fn run(rand: std.Random) anyerror!void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var enableShooter = false;

    var balls = try std.ArrayList(Ball).initCapacity(allocator, 100);
    for (0..31) |i| {
        const f: f32 = @floatFromInt(i);

        try balls.append(allocator, Ball.init(rl.Vector2.init(f * 20 + 100, 500), .white));
    }

    balls.items[0].pinned = true;
    balls.items[balls.items.len - 1].pinned = true;

    var links = try std.ArrayList(Link).initCapacity(allocator, 100);
    for (0..30) |i| {
        try links.append(allocator, Link{
            .ball_1 = i,
            .ball_2 = i + 1,
            .target_dist = 20.0,
        });
    }

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            enableShooter = !enableShooter;
        }

        const shooter_time: f32 = @floatCast(rl.getTime());
        if (enableShooter) {
            const max_angle = std.math.pi / 6.0; // 30 swing each side
            const swing_speed = 2.0;
            const angle = std.math.sin(shooter_time * swing_speed) * max_angle;

            // angle = 0 -> straight down. Rotate around that.
            const dir = rl.Vector2.init(@sin(angle), @cos(angle));
            const speed = 2.5;
            const vec = dir.scale(speed);

            try balls.append(allocator, Ball.initSpeed(
                rl.Vector2.init(c.SCREEN_W / 2, 50),
                vec,
                c.getRainbow(shooter_time),
                rand,
            ));
        }

        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            try balls.append(allocator, Ball.init(rl.getMousePosition(), rp.text));
        }

        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            try balls.append(allocator, Ball.init(rl.getMousePosition(), rp.text));
        }

        removeOffscreen(&balls);
        update(balls.items, links.items, rl.getFrameTime());

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rp.base);

        for (balls.items) |*single| {
            single.*.draw();
        }

        c.drawFPS();
        rl.drawText(rl.textFormat("BALLS: %i", .{balls.items.len}), 5, 25, 20, .white);
    }
}

fn update(balls: []Ball, links: []Link, dt: f32) void {
    const sub_steps = 8.0;
    const sub_dt = dt / sub_steps;

    for (0..sub_steps) |_| {
        applyGravity(balls);
        solveCollisions(balls);
        for (links) |link| {
            link.apply(balls);
        }
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

fn solveCollisions(balls: []Ball) void {
    for (balls, 0..) |*obj_1, i| {
        for (balls[i + 1 ..]) |*obj_2| {
            const collision_axis = obj_1.current_pos.subtract(obj_2.current_pos);
            const dist = collision_axis.length();
            const min_dist = obj_1.radius + obj_2.radius;

            if (dist < min_dist and dist != 0.0) {
                const n = collision_axis.scale(1 / dist);
                const delta = min_dist - dist;

                if (obj_1.pinned and obj_2.pinned) {
                    continue;
                } else if (obj_1.pinned) {
                    obj_2.current_pos = obj_2.current_pos.subtract(n.scale(delta));
                } else if (obj_2.pinned) {
                    obj_1.current_pos = obj_1.current_pos.add(n.scale(delta));
                } else {
                    obj_1.current_pos = obj_1.current_pos.add(n.scale(0.5 * delta));
                    obj_2.current_pos = obj_2.current_pos.subtract(n.scale(0.5 * delta));
                }
            }
        }
    }
}

fn removeOffscreen(balls: *std.ArrayList(Ball)) void {
    var i: usize = balls.items.len;
    while (i > 0) : (i -= 1) {
        const b = balls.items[i - 1];
        if (b.current_pos.y > c.SCREEN_H + 100 or
            b.current_pos.y < -100 or
            b.current_pos.x < -100 or
            b.current_pos.x > c.SCREEN_W + 100)
        {
            _ = balls.swapRemove(i - 1);
        }
    }
}
