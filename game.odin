package game

import rl "vendor:raylib"

SPEED: f32 : 400.0
GRAVITY: f32 : 2000.0

main :: proc() {
	rl.InitWindow(1280, 720, "Aesir")

	player_pos: rl.Vector2 = {640, 360}
	player_vel: rl.Vector2

	player_on_ground: bool = false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		frame_time: f32 = rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			player_vel.x = -SPEED
		} else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			player_vel.x = SPEED
		} else {
			player_vel.x = 0
		}

		player_vel += GRAVITY * frame_time

		if rl.IsKeyPressed(.SPACE) && player_on_ground {
			player_vel.y = -600
			player_on_ground = false
		}

		player_pos += player_vel * frame_time

		floor_pos: f32 = f32(rl.GetScreenHeight()) - 64
		if player_pos.y > floor_pos {
			player_pos.y = floor_pos
			player_on_ground = true
		}

		rl.ClearBackground(rl.SKYBLUE)
		rl.DrawRectangleV(player_pos, {64, 64}, rl.RAYWHITE)
	}

	rl.CloseWindow()
}
