package game

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import rl "vendor:raylib"

Animations :: enum {
	player_idle,
	player_run,
	player_death,
}

SpriteData :: struct {
	frames:   i8,
	duration: f32,
}

sprite_data: [Animations]SpriteData = {
	.player_idle = {frames = 2, duration = 0.3},
	.player_run = {frames = 3, duration = 0.1},
	.player_death = {frames = 3, duration = 0.2},
}

AnimationData :: struct {
	one_shot: bool,
}

animation_data: [Animations]AnimationData = #partial {
	.player_death = {one_shot = true},
}

animations: [Animations]Animation

load_animation_data :: proc(allocator := context.allocator) {
	img_dir := "res/images/"

	for anim in Animations {
		path := fmt.tprint(img_dir, anim, ".png", sep = "")
		succ := os.is_file_path(path)
		assert(succ, fmt.tprint(path, "not found"))

		texture: rl.Texture2D = rl.LoadTexture(strings.clone_to_cstring(path, allocator))

		sprite := sprite_data[anim]
		data := animation_data[anim]

		animations[anim] = {
			sprite = {animation = anim, texture = texture},
			frames = sprite.frames,
			frame_length = sprite.duration,
			one_shot = data.one_shot,
		}

		fmt.printf("animation added: %v %s -> %v\n", anim, path, animations[anim])
	}
}

AnimationSprite :: struct {
	animation: Animations,
	texture:   rl.Texture2D,
}

Animation :: struct {
	sprite:        AnimationSprite,
	frames:        i8,
	current_frame: i8,
	frame_length:  f32,
	frame_timer:   f32,
	one_shot:      bool,
}

update_animation :: proc(animation: ^Animation, frame_time: f32) {
	animation.frame_timer += frame_time
	for animation.frame_timer >= animation.frame_length {
		animation.frame_timer -= animation.frame_length
		animation.current_frame += 1

		if animation.current_frame >= animation.frames {
			animation.current_frame = animation.one_shot ? animation.frames - 1 : 0
		}
	}
}

change_animation :: proc(animation: ^Animation, new_animation: Animation) {
	if animation.sprite.animation == new_animation.sprite.animation {
		return
	}

	animation.sprite.animation = new_animation.sprite.animation
	animation.sprite.texture = new_animation.sprite.texture
	animation.frames = new_animation.frames
	animation.frame_length = new_animation.frame_length
	animation.one_shot = new_animation.one_shot

	animation.frame_timer = 0
	animation.current_frame = 0
}

draw_animation :: proc(animation: Animation, position: rl.Vector2, flip_sprite: bool) {
	animation_width: f32 = f32(animation.sprite.texture.width)
	animation_height: f32 = f32(animation.sprite.texture.height)

	player_source: rl.Rectangle = {
		x      = f32(animation.current_frame) * animation_width / f32(animation.frames),
		y      = 0,
		width  = animation_width / f32(animation.frames),
		height = animation_height,
	}

	player_dest: rl.Rectangle = {
		x      = position.x,
		y      = position.y,
		width  = animation_width * 4 / f32(animation.frames),
		height = animation_height * 4,
	}

	if flip_sprite {
		player_source.width = -player_source.width
	}

	rl.DrawTexturePro(
		animation.sprite.texture,
		player_source,
		player_dest,
		{},
		0,
		tint = rl.RAYWHITE,
	)
}

@(test)
test_load_animations :: proc(t: ^testing.T) {
	rl.InitWindow(0, 0, "")
	load_animation_data(context.temp_allocator)

	// all animations should be loaded
	testing.expect_value(t, len(animations), len(Animations))

	for anim in animations {
		// all animations should have frames and frame_length at least
		testing.expect(t, anim.frames > 0)
		testing.expect(t, anim.frame_length > 0)

		// all textures should be of valid format and dimensions
		testing.expect(t, anim.sprite.texture.format != .UNKNOWN)
		testing.expect(t, anim.sprite.texture.width > 0)
		testing.expect(t, anim.sprite.texture.height > 0)
	}

	free_all(context.temp_allocator)
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
