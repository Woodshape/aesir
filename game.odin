package game

import "core:fmt"
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

update_animation :: proc(animation: ^Animation, frame_time: f32) {
	animation.frame_timer += frame_time
	for animation.frame_timer > animation.frame_length {
		animation.frame_timer -= animation.frame_length
		animation.current_frame += 1

		if animation.current_frame >= animation.frames {
			animation.current_frame = 0
		}
	}
}

draw_animation :: proc(animation: Animation, position: rl.Vector2, flip_sprite: bool) {
	player_run_width: f32 = f32(animation.texture.width)
	player_run_height: f32 = f32(animation.texture.height)

	player_source: rl.Rectangle = {
		x      = f32(animation.current_frame) * player_run_width / f32(animation.frames),
		y      = 0,
		width  = player_run_width / f32(animation.frames),
		height = player_run_height,
	}

	if flip_sprite {
		player_source.width = -player_source.width
	}

	player_dest: rl.Rectangle = {
		x      = position.x,
		y      = position.y,
		width  = player_run_width * 4 / f32(animation.frames),
		height = player_run_height * 4,
	}

	rl.DrawTexturePro(animation.texture, player_source, player_dest, {}, 0, tint = rl.RAYWHITE)
}

main :: proc() {
	rl.InitWindow(1280, 720, "Aesir")

	player_idle_animation: Animation = {
		texture      = rl.LoadTexture("cat_idle.png"),
		frames       = 2,
		frame_length = 0.5,
	}

	player_run_animation: Animation = {
		texture      = rl.LoadTexture("cat_run.png"),
		frames       = 4,
		frame_length = 0.1,
	}

	player_animation: ^Animation = &player_idle_animation

	player_pos: rl.Vector2 = {640, 360}
	player_vel: rl.Vector2

	player_on_ground: bool = false
	player_flip_sprite: bool = false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		frame_time: f32 = rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			player_vel.x = -SPEED
			player_flip_sprite = true
			player_animation = &player_run_animation
		} else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			player_vel.x = SPEED
			player_flip_sprite = false
			player_animation = &player_run_animation
		} else {
			player_vel.x = 0.0
			player_animation = &player_idle_animation
		}

		player_vel.y += GRAVITY * frame_time

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

		update_animation(player_animation, frame_time)

		rl.ClearBackground(rl.SKYBLUE)

		draw_animation(player_animation^, player_pos, player_flip_sprite)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
