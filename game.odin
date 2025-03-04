package main

import "core:fmt"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
SPEED :: 200

IDLE_FRAME :: 3

characers: [dynamic]^Character


main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Odin Game")

	animation_run := Animation {
		texture   = rl.LoadTexture("cat_run.png"),
		frames    = 4,
		idle_frame = 3,
		step_time = 0.1,
	}

	character := Character {
		speed = 200.0,
	}

	append(&characers, &character)
	defer delete(characers)

	start_pos := rl.Vector2 {
		WINDOW_WIDTH / 2 - f32(animation_run.texture.width),
		WINDOW_HEIGHT / 2 - f32(animation_run.texture.height),
	}

	init_character(&character, start_pos, animation_run.texture.width, animation_run.texture.height)
	character.current_animation = &animation_run

	target_pos: rl.Vector2

	player_is_running: bool
	flip_animation: bool

	for !rl.WindowShouldClose() {
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			target_pos = rl.GetMousePosition()
			// target_pos = rl.Vector2 {
			// 	mousePos.x - f32(animation_player_run.texture.width / 2),
			// 	mousePos.y - f32(animation_player_run.texture.height * 2),
			// }

			fmt.printf("Target: %v\n", target_pos)

			for c in characers {
				c.target_pos = target_pos
				if rl.CheckCollisionPointRec(target_pos, c.rect) {
					fmt.printf("Player %v clicked!\n", c)
				}
			}

		}


		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		for c in characers {
			handle_character(c)
			draw_character(c)
		}

		rl.DrawCircleV(character.position, 2.0, rl.BLUE)
		rl.DrawCircleV(target_pos, 2.0, rl.RED)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}

handle_character :: proc (character: ^Character) {
	if character.target_pos != rl.Vector2(0) {
		character.is_running = true
		if _, arrived_at_pos := move_character(
			character,
		); arrived_at_pos {
			character.target_pos = rl.Vector2(0)
			character.is_running = false
		}
	}
}

draw_character :: proc (character: ^Character) {
	if (character.current_animation == nil) {
		panic("Character animation unknown")
	}

	player_run_frame_width :=
		f32(character.current_animation.texture.width) / f32(character.current_animation.frames)

	draw_player_source := rl.Rectangle {
		x      = f32(character.current_animation.current_frame) * player_run_frame_width,
		y      = 0,
		width  = player_run_frame_width,
		height = f32(character.current_animation.texture.height),
	}

	draw_player_dest := rl.Rectangle {
		x      = character.position.x,
		y      = character.position.y,
		width  = player_run_frame_width * 4,
		height = f32(character.current_animation.texture.height) * 4,
	}

	character.rect = draw_player_dest

	if should_flip_animation(character^) {
		draw_player_source.width = -draw_player_source.width
	}

	if character.is_running {
		start_animate(character.current_animation)
	} else {
		stop_animate(character.current_animation)
	}

	rl.DrawTexturePro(
		character.current_animation.texture,
		draw_player_source,
		draw_player_dest,
		0,
		0,
		rl.WHITE,
	)
}
