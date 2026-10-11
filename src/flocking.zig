const std = @import("std");
const rl = @import("raylib");
const c = @import("common.zig");

const FLOCK_SIZE = 100;
const WALL_SIZE = 10;

const PERCEPTION = 50;
const MAX_SPEED = 3;
const MAX_ACCEL = 0.15;

const Wall = struct {
    pos: rl.Vector2,

    pub fn init(rand: std.Random) Wall {
        return Wall{
            .pos = rl.Vector2{
                .x = rand.float(f32) * c.SCREEN_WIDTH,
                .y = rand.float(f32) * c.SCREEN_HEIGHT,
            },
        };
    }

    pub fn draw(self: Wall) void {
        rl.drawCircleV(self.pos, 5.0, rl.Color.red);
    }
};

const Boid = struct {
    id: u16,
    pos: rl.Vector2,
    vel: rl.Vector2,
    accel: rl.Vector2,
    perception: f32,

    pub fn init(id: usize, rand: std.Random) Boid {
        var vel = rl.Vector2{
            .x = rand.float(f32) * 2 - 1,
            .y = rand.float(f32) * 2 - 1,
        };

        vel = vel.normalize();

        return Boid{
            .id = @intCast(id),
            .pos = rl.Vector2{
                .x = rand.float(f32) * c.SCREEN_WIDTH,
                .y = rand.float(f32) * c.SCREEN_HEIGHT,
            },
            .vel = vel,
            .accel = rl.Vector2.zero(),
            .perception = PERCEPTION,
        };
    }

    pub fn alignment(self: *Boid, flock: []const Boid) void {
        var wish_dir = rl.Vector2.zero();
        var boid_count: f32 = 0;
        const strength = 0.2;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;
                    wish_dir = wish_dir.add(boid.vel);
                }
            }
        }

        if (boid_count > 0) {
            wish_dir = wish_dir.scale(1.0 / boid_count);
            const wish_vel = wish_dir.subtract(self.vel).scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn cohesion(self: *Boid, flock: []const Boid) void {
        var wish_pos = rl.Vector2.zero();
        var boid_count: f32 = 0;
        const strength = 0.1;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;
                    wish_pos = wish_pos.add(boid.pos);
                }
            }
        }

        if (boid_count > 0) {
            wish_pos = wish_pos.scale(1.0 / boid_count);
            const wish_vel = wish_pos.subtract(self.pos).scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn seperation(self: *Boid, flock: []const Boid) void {
        var wish_dir = rl.Vector2.zero();
        var boid_count: f32 = 0;
        const strength = 0.08;

        for (flock) |*boid| {
            if (self.id != boid.id) {
                const dist = self.pos.subtract(boid.pos).length();

                if (dist < self.perception) {
                    boid_count += 1;

                    var diff = self.pos.subtract(boid.pos);

                    if (dist != 0.0) {
                        diff = diff.scale(PERCEPTION / dist);
                    }

                    wish_dir = wish_dir.add(diff);
                }
            }
        }

        if (boid_count > 0) {
            wish_dir = wish_dir.scale(1.0 / boid_count);
            const wish_vel = wish_dir.scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn focus(self: *Boid) void {
        var wish_dir = rl.Vector2.zero();
        const strength = 0.2;

        if (rl.isMouseButtonDown(rl.MouseButton.left)) {
            wish_dir = rl.getMousePosition().subtract(self.pos);

            wish_dir = wish_dir.normalize().scale(strength);

            self.*.accel = self.*.accel.add(wish_dir);
            rl.drawCircleV(rl.getMousePosition(), 5, rl.Color.white);
        }
    }

    pub fn check_wall(self: *Boid, walls: []const Wall) void {
        var wish_dir = rl.Vector2.zero();
        var wall_count: f32 = 0;
        const strength = 0.2;

        for (walls) |*wall| {
            const dist = self.pos.subtract(wall.pos).length();

            if (dist < self.perception) {
                wall_count += 1;

                var diff = self.pos.subtract(wall.pos);

                if (dist != 0.0) {
                    diff = diff.scale(PERCEPTION / dist);
                }

                wish_dir = wish_dir.add(diff);
            }
        }

        if (wall_count > 0) {
            wish_dir = wish_dir.scale(1.0 / wall_count);
            const wish_vel = wish_dir.scale(strength);

            self.*.accel = self.*.accel.add(wish_vel);
        }
    }

    pub fn move(self: *Boid) void {
        self.accel = self.accel.clampValue(0.0, MAX_ACCEL);

        self.vel = self.vel.add(self.accel);

        if (self.vel.length() < MAX_SPEED) {
            const new_speed = @min(self.vel.length() + MAX_ACCEL / 2.0, MAX_SPEED);
            self.vel = self.vel.normalize().scale(new_speed);
        } else {
            self.vel = self.vel.normalize().scale(MAX_SPEED);
        }

        if (self.id == 0) {
            rl.drawText(rl.textFormat("Speed: %.4f", .{self.vel.length()}), 5, 30, 20, .white);
            rl.drawText(rl.textFormat("Accel: %.4f", .{self.accel.length()}), 5, 55, 20, .white);
        }

        self.pos = self.pos.add(self.vel);

        self.accel = rl.Vector2.zero();

        if (self.pos.x > c.SCREEN_WIDTH) {
            self.pos.x = 0;
        } else if (self.pos.x < 0) {
            self.pos.x = c.SCREEN_WIDTH;
        }

        if (self.pos.y > c.SCREEN_HEIGHT) {
            self.pos.y = 0;
        } else if (self.pos.y < 0) {
            self.pos.y = c.SCREEN_HEIGHT;
        }
    }

    pub fn draw(self: Boid) void {
        const up = rl.Vector2{ .x = 0, .y = -1 };
        const rot = up.angle(self.vel);

        var p1 = rl.Vector2{ .x = -5, .y = 5 };
        var p2 = rl.Vector2{ .x = 5, .y = 5 };
        var p3 = rl.Vector2{ .x = 0, .y = -10 };

        p1 = p1.rotate(rot).add(self.pos);
        p2 = p2.rotate(rot).add(self.pos);
        p3 = p3.rotate(rot).add(self.pos);

        rl.drawTriangle(p1, p2, p3, c.rosepine.subtle);

        if (self.id == 0) {
            rl.drawLineV(self.pos, self.pos.add(self.vel.scale(50)), c.rosepine.subtle);
            rl.drawCircleLinesV(self.pos, self.perception, rl.Color.white.alpha(0.5));
        }
    }
};

pub fn run(rand: std.Random) anyerror!void {
    var flock: [FLOCK_SIZE]Boid = undefined;

    for (&flock, 0..) |*single, i| {
        single.* = Boid.init(i, rand);
    }

    var walls: [WALL_SIZE]Wall = undefined;

    for (&walls) |*wall| {
        wall.* = Wall.init(rand);
    }

    while (!rl.windowShouldClose() and !rl.isKeyPressed(.escape)) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(c.rosepine.base);

        for (&flock) |*boid| {
            boid.*.alignment(&flock);
            boid.*.seperation(&flock);
            boid.*.cohesion(&flock);
            boid.*.check_wall(&walls);
            boid.*.focus();
            boid.*.move();
            boid.*.draw();
        }

        for (&walls) |*wall| {
            wall.*.draw();
        }

        c.drawFPS();
    }
}
