package game

import "core:log"
import "core:testing"
import rl "vendor:raylib"

SPEED: f32 : 400.0
GRAVITY: f32 : 2000.0

Player :: struct {
	hp:          i32,
	pos:         rl.Vector2,
	vel:         rl.Vector2,
	animation:   Animation,
	grounded:    bool,
	flip_sprite: bool,
}

Input :: struct {
	move_left:  bool,
	move_right: bool,
	jump:       bool,
}

handle_input :: proc() -> Input {
	return {
		move_left = rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A),
		move_right = rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D),
		jump = rl.IsKeyPressed(.SPACE),
	}
}


main :: proc() {
	rl.InitWindow(1280, 720, "Aesir")

	load_animation_data()

	player_idle_animation: Animation = player_animations[.player_idle]
	player_run_animation: Animation = player_animations[.player_run]

	player: Player = {
		hp        = 100,
		pos       = {640, 360},
		animation = player_idle_animation,
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		frame_time: f32 = rl.GetFrameTime()

		input: Input = handle_input()

		if input.move_left {
			player.vel.x = -SPEED
			player.flip_sprite = true
			change_animation(&player.animation, player_run_animation)
		} else if input.move_right {
			player.vel.x = SPEED
			player.flip_sprite = false
			change_animation(&player.animation, player_run_animation)
		} else {
			player.vel.x = 0.0
			change_animation(&player.animation, player_idle_animation)
		}

		player.vel.y += GRAVITY * frame_time

		if input.jump && player.grounded {
			player.vel.y = -600
			player.grounded = false
		}

		player.pos += player.vel * frame_time

		floor_pos: f32 = f32(rl.GetScreenHeight()) - 96
		if player.pos.y > floor_pos {
			player.pos.y = floor_pos
			player.grounded = true
		}

		update_animation(&player.animation, frame_time)

		rl.ClearBackground(rl.SKYBLUE)

		draw_animation(player.animation, player.pos, player.flip_sprite)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
