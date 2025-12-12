package game

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import rl "vendor:raylib"

Animations :: enum {
	player_idle,
	player_run,
}

Sprite_Data :: struct {
	frames:   i8,
	duration: f32,
}

sprite_data: [Animations]Sprite_Data = {
	.player_idle = {frames = 2, duration = 0.3},
	.player_run = {frames = 3, duration = 0.1},
}

animations: [Animations]Animation

load_animation_data :: proc() {
	img_dir := "res/images/"

	for anim in Animations {
		path := fmt.tprint(img_dir, anim, ".png", sep = "")
		succ := os.is_file_path(path)
		assert(succ, fmt.tprint(path, "not found"))

		texture: rl.Texture2D = rl.LoadTexture(strings.clone_to_cstring(path))

		data := sprite_data[anim]

		animations[anim] = {
			sprite = {animation = anim, texture = texture},
			frames = data.frames,
			frame_length = data.duration,
		}

		fmt.printf("animation added: %v %s -> %v\n", anim, path, animations[anim])
	}
}

Animation_Sprite :: struct {
	animation: Animations,
	texture:   rl.Texture2D,
}

Animation :: struct {
	sprite:        Animation_Sprite,
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

change_animation :: proc(animation: ^Animation, new_animation: Animation) {
	if animation.sprite.animation == new_animation.sprite.animation {
		return
	}

	animation.sprite.animation = new_animation.sprite.animation
	animation.sprite.texture = new_animation.sprite.texture
	animation.frames = new_animation.frames
	animation.frame_length = new_animation.frame_length

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
