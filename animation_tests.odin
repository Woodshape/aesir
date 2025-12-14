package game

import "core:log"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_load_animations :: proc(t: ^testing.T) {
	rl.InitWindow(0, 0, "test_window")
	defer rl.CloseWindow()

	load_animation_data(context.temp_allocator)

	// all animations should be loaded
	testing.expect_value(t, len(animations), len(Animations))

	for anim in animations {
		log.infof("anim: %v", anim)

		// all animations should have frames and frame_length at least
		testing.expect(t, anim.sprite.data.frames > 0)
		testing.expect(t, anim.sprite.data.duration > 0)

		// all textures should be of valid format and dimensions
		testing.expect(t, anim.sprite.texture.format != .UNKNOWN)
		testing.expect(t, anim.sprite.texture.width > 0)
		testing.expect(t, anim.sprite.texture.height > 0)
	}

	free_all(context.temp_allocator)
}

@(test)
test_change_animation :: proc(t: ^testing.T) {
	data: Sprite_Data = sprite_data[.player_idle]
	anim_data: Animation_Data = animation_data[.player_idle]
	animation := Animation {
		name = .player_idle,
		sprite = {data = data},
		one_shot = anim_data.one_shot,
	}

	testing.expect_value(t, animation.name, Animations.player_idle)
	testing.expect_value(t, animation.sprite.data.duration, data.duration)
	testing.expect_value(t, animation.sprite.data.frames, data.frames)
	testing.expect_value(t, animation.one_shot, anim_data.one_shot)

	new_data: Sprite_Data = sprite_data[.player_run]
	new_anim_data: Animation_Data = animation_data[.player_run]
	new_animation := Animation {
		name = .player_run,
		sprite = {data = new_data},
		one_shot = new_anim_data.one_shot,
	}

	change_animation(&animation, new_animation)

	testing.expect_value(t, animation.name, Animations.player_run)
	testing.expect_value(t, animation.sprite.data.duration, new_data.duration)
	testing.expect_value(t, animation.sprite.data.frames, new_data.frames)
	testing.expect_value(t, animation.one_shot, new_anim_data.one_shot)
}

@(test)
test_update :: proc(t: ^testing.T) {
	sprite_data: Sprite_Data = {
		frames   = 2,
		duration = 1,
	}
	animation := Animation {
		sprite = {data = sprite_data},
	}

	// current frame should change according to frame_length and loop after N frames
	update_animation(&animation, 0.5)
	testing.expect_value(t, animation.current_frame, 0)
	update_animation(&animation, 0.5)
	testing.expect_value(t, animation.current_frame, 1)
	update_animation(&animation, 1)
	testing.expect_value(t, animation.current_frame, 0)
}

@(test)
test_update_one_shot :: proc(t: ^testing.T) {
	sprite_data: Sprite_Data = {
		frames   = 2,
		duration = 1,
	}
	animation := Animation {
		sprite = {data = sprite_data},
		one_shot = true,
	}

	// current frame should change according to frame_length and not loop after N frames
	update_animation(&animation, 0.5)
	testing.expect_value(t, animation.current_frame, 0)
	update_animation(&animation, 0.5)
	testing.expect_value(t, animation.current_frame, 1)
	update_animation(&animation, 1)
	testing.expect_value(t, animation.current_frame, 1)
}
