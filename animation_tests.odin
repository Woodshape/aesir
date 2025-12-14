package game

import "core:fmt"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

load_test_animation_data :: proc(allocator := context.allocator) {
	img_dir := "res/images/"

	for anim in Animations {
		path := fmt.tprint(img_dir, anim, ".png", sep = "")

		sprite := sprite_data[anim]
		data := animation_data[anim]

		animations[anim] = {
			name = anim,
			sprite = {data = sprite},
			frame_timer = sprite.duration,
			one_shot = data.one_shot,
		}

		fmt.printf("animation added: %v %s -> %v\n", anim, path, animations[anim])
	}
}

@(test)
test_load_animations :: proc(t: ^testing.T) {
	rl.InitWindow(0, 0, "TestWindow")
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
	load_test_animation_data(context.temp_allocator)

	data: Sprite_Data = sprite_data[.player_idle]
	animation := animations[.player_idle]

	testing.expect_value(t, animation.name, Animations.player_idle)
	testing.expect_value(t, animation.frame_timer, data.duration)
	testing.expect_value(t, animation.sprite.data.duration, data.duration)
	testing.expect_value(t, animation.sprite.data.frames, data.frames)
	testing.expect_value(t, animation.one_shot, false)

	new_data: Sprite_Data = sprite_data[.player_run]
	new_animation := animations[.player_run]

	change_animation(&animation, new_animation)

	testing.expect_value(t, animation.name, Animations.player_run)
	testing.expect_value(t, animation.frame_timer, new_data.duration)
	testing.expect_value(t, animation.sprite.data.duration, new_data.duration)
	testing.expect_value(t, animation.sprite.data.frames, new_data.frames)
	testing.expect_value(t, animation.one_shot, false)
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
		frame_timer = sprite_data.duration,
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
