package game

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

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
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Aesir")

	load_animation_data()

	player: Player = {
		hp        = 100,
		pos       = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2},
		animation = animations[.player_idle],
	}

	player_dead: bool

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		frame_time: f32 = rl.GetFrameTime()

		input: Input = handle_input()

		if !player_dead {
			if input.move_left {
				player.vel.x = -SPEED
				player.flip_sprite = true
				change_animation(&player.animation, animations[.player_run])
			} else if input.move_right {
				player.vel.x = SPEED
				player.flip_sprite = false
				change_animation(&player.animation, animations[.player_run])
			} else {
				player.vel.x = 0.0
				change_animation(&player.animation, animations[.player_idle])
			}
		} else {
			rl.DrawText("You are Dead", WINDOW_WIDTH / 2 - 200, WINDOW_HEIGHT / 2, 50, rl.BLACK)
		}

		if rl.IsKeyPressed(.F) {
			change_animation(&player.animation, animations[.player_death])
			player_dead = !player_dead
			player.vel.x = 0.0
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
