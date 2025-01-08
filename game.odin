package main

import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
SPEED :: 200

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Odin Game")

	player := Player{ speed = 200.0 }

	animation_player_run := Animation {
		texture = rl.LoadTexture("cat_run.png"),
		frames = 4,
		step_time = 0.1
	}

	player.position = rl.Vector2 {
		WINDOW_WIDTH / 2 - f32(animation_player_run.texture.width),
		WINDOW_HEIGHT / 2 - f32(animation_player_run.texture.height),
	}

	target_pos : rl.Vector2

	player_idle_frame := 3

	player_is_running: bool
	flip_animation: bool

	for !rl.WindowShouldClose() {
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			mousePos: rl.Vector2 = rl.GetMousePosition()
			target_pos = rl.Vector2 {
				mousePos.x - f32(animation_player_run.texture.width / 2),
				mousePos.y - f32(animation_player_run.texture.height * 2),
			}
			fmt.println(target_pos)
		}
		if target_pos != rl.Vector2(0) {
			if target_pos.x < player.position.x {
				flip_animation = true
			} else {
				flip_animation = false
			}

			player_is_running = true
			if _, at_pos := move_player_position(&player, animation_player_run, target_pos); at_pos {
				target_pos = rl.Vector2(0)
				player_is_running = false
			}
		}

		if player_is_running {
			start_animate(&animation_player_run)
		} else {
			stop_animate(&animation_player_run, player_idle_frame)
		}

		player_run_frame_width := f32(animation_player_run.texture.width) / f32(animation_player_run.frames)

		draw_player_source := rl.Rectangle {
			x      = f32(animation_player_run.current_frame) * player_run_frame_width,
			y      = 0,
			width  = player_run_frame_width,
			height = f32(animation_player_run.texture.height),
		}

		if flip_animation {
			draw_player_source.width = -draw_player_source.width
		}

		draw_player_dest := rl.Rectangle {
			x      = player.position.x,
			y      = player.position.y,
			width  = player_run_frame_width * 4,
			height = f32(animation_player_run.texture.height) * 4,
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexturePro(animation_player_run.texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)
		rl.DrawCircleV(player.position, 2.0, rl.BLUE)
		rl.DrawCircleV(target_pos, 2.0, rl.RED)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
