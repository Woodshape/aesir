package game

import "core:testing"
import rl "vendor:raylib"

Animation :: struct {
	texture:       rl.Texture2D,
	frames:        i8,
	current_frame: i8,
	frame_length:  f32,
	frame_timer:   f32,
}

update_animation :: proc(animation: ^Animation, frame_time: f32) {
	animation.frame_timer += frame_time
	for animation.frame_timer >= animation.frame_length {
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

	player_dest: rl.Rectangle = {
		x      = position.x,
		y      = position.y,
		width  = player_run_width * 4 / f32(animation.frames),
		height = player_run_height * 4,
	}

	if flip_sprite {
		player_source.width = -player_source.width
	}

	rl.DrawTexturePro(animation.texture, player_source, player_dest, {}, 0, tint = rl.RAYWHITE)
}

@(test)
test_update :: proc(t: ^testing.T) {
	animation := Animation {
		frames       = 2,
		frame_length = 1,
	}

	update_animation(&animation, 0.5)

	testing.expect_value(t, animation.current_frame, 0)

	update_animation(&animation, 1)

	testing.expect_value(t, animation.current_frame, 1)

	update_animation(&animation, 1)

	testing.expect_value(t, animation.current_frame, 0)
}
