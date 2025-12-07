package game

import rl "vendor:raylib"

SPEED: f32 : 400.0
GRAVITY: f32 : 2000.0

Animation :: struct {
	texture:       rl.Texture2D,
	frames:        i8,
	current_frame: i8,
	frame_length:  f32,
	frame_timer:   f32,
}

main :: proc() {
	rl.InitWindow(1280, 720, "Aesir")

	player_run_animation: Animation = {
		texture      = rl.LoadTexture("cat_run.png"),
		frames       = 4,
		frame_length = 0.1,
	}

	player_pos: rl.Vector2 = {640, 360}
	player_vel: rl.Vector2

	player_on_ground: bool = false
	player_flip_sprite: bool = false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		frame_time: f32 = rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			player_vel.x = -SPEED
			player_flip_sprite = true
		} else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			player_vel.x = SPEED
			player_flip_sprite = false
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

		player_run_animation.frame_timer += frame_time
		for player_run_animation.frame_timer > player_run_animation.frame_length {
			player_run_animation.frame_timer -= player_run_animation.frame_length
			player_run_animation.current_frame += 1

			if player_run_animation.current_frame >= player_run_animation.frames {
				player_run_animation.current_frame = 0
			}
		}

		player_run_width: f32 = f32(player_run_animation.texture.width)
		player_run_height: f32 = f32(player_run_animation.texture.height)

		player_source: rl.Rectangle = {
			x      = f32(
				player_run_animation.current_frame,
			) * player_run_width / f32(player_run_animation.frames),
			y      = 0,
			width  = player_run_width / f32(player_run_animation.frames),
			height = player_run_height,
		}

		if player_flip_sprite {
			player_source.width = -player_source.width
		}

		player_dest: rl.Rectangle = {
			x      = player_pos.x,
			y      = player_pos.y,
			width  = player_run_width * 4 / f32(player_run_animation.frames),
			height = player_run_height * 4,
		}

		rl.ClearBackground(rl.SKYBLUE)
		rl.DrawTexturePro(
			player_run_animation.texture,
			player_source,
			player_dest,
			{},
			0,
			tint = rl.RAYWHITE,
		)
	}

	rl.CloseWindow()
}
