#+test
package game

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

@(init)
init :: proc "contextless" () {
	rl.InitWindow(0, 0, "Test Window")

	context = runtime.default_context()
	load_animation_data(context.temp_allocator)
}

@(fini)
fini :: proc "contextless" () {
	rl.CloseWindow()


	context = runtime.default_context()
	free_all(context.temp_allocator)
}

@(test)
test_load_animations :: proc(t: ^testing.T) {
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
	// load_test_animation_data(context.temp_allocator)

	data: Sprite_Data = sprite_data[.player_idle]
	anim: Animation_Data = animation_data[.player_idle]
	animation := animations[.player_idle]

	testing.expect_value(t, animation.name, Animations.player_idle)
	testing.expect_value(t, animation.frame_timer, data.duration)
	testing.expect_value(t, animation.sprite.data.duration, data.duration)
	testing.expect_value(t, animation.sprite.data.frames, data.frames)
	testing.expect_value(t, animation.data.scale, anim.scale)
	testing.expect_value(t, animation.data.one_shot, anim.one_shot)

	new_data: Sprite_Data = sprite_data[.player_run]
	new_anim: Animation_Data = animation_data[.player_idle]
	new_animation := animations[.player_run]

	change_animation(&animation, new_animation)

	testing.expect_value(t, animation.name, Animations.player_run)
	testing.expect_value(t, animation.frame_timer, new_data.duration)
	testing.expect_value(t, animation.sprite.data.duration, new_data.duration)
	testing.expect_value(t, animation.sprite.data.frames, new_data.frames)
	testing.expect_value(t, animation.data.scale, new_anim.scale)
	testing.expect_value(t, animation.data.one_shot, new_anim.one_shot)
}

@(test)
test_update :: proc(t: ^testing.T) {
	sprite_data: Sprite_Data = {
		frames   = 2,
		duration = 1,
	}
	animation := Animation {
		sprite = {data = sprite_data},
		frame_timer = sprite_data.duration,
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
		data = {one_shot = true},
		frame_timer = sprite_data.duration,
	}

	// current frame should change according to frame_length and not loop after N frames
	update_animation(&animation, 0.5)
	testing.expect_value(t, animation.current_frame, 0)
	update_animation(&animation, 0.5)
	testing.expect_value(t, animation.current_frame, 1)
	update_animation(&animation, 1)
	testing.expect_value(t, animation.current_frame, 1)
}
