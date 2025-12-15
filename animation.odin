package game

import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

Animations :: enum {
	player_idle,
	player_run,
	player_death,
}

Sprite_Data :: struct {
	frames:   i8,
	duration: f32,
}

sprite_data: [Animations]Sprite_Data = {
	.player_idle = {frames = 2, duration = 0.3},
	.player_run = {frames = 3, duration = 0.1},
	.player_death = {frames = 3, duration = 0.2},
}

Animation_Data :: struct {
	scale:    rl.Vector2,
	one_shot: bool,
}

Animation_Data_Base :: Animation_Data {
	scale = {4, 4},
}

animation_data: [Animations]Animation_Data = {
	.player_idle = Animation_Data_Base,
	.player_run = Animation_Data_Base,
	.player_death = {scale = {4, 4}, one_shot = true},
}

animations: [Animations]Animation

load_animation_data :: proc(allocator := context.allocator) {
	img_dir := "res/images/"

	fmt.printf("setting up animations")

	for anim in Animations {
		path := fmt.tprint(img_dir, anim, ".png", sep = "")
		succ := os.is_file_path(path)
		assert(succ, fmt.tprint(path, "not found"))

		texture: rl.Texture2D = rl.LoadTexture(strings.clone_to_cstring(path, allocator))

		sprite := sprite_data[anim]
		data := animation_data[anim]

		animations[anim] = {
			name = anim,
			sprite = {data = sprite, texture = texture},
			data = data,
			frame_timer = sprite.duration,
		}

		fmt.printf("animation added: %v %s -> %v\n", anim, path, animations[anim])
	}
}

Sprite :: struct {
	data:    Sprite_Data,
	texture: rl.Texture2D,
}

Animation :: struct {
	name:          Animations,
	sprite:        Sprite,
	data:          Animation_Data,
	current_frame: i8,
	frame_timer:   f32,
}

update_animation :: proc(animation: ^Animation, frame_time: f32) -> bool {
	loop := false

	frames := animation.sprite.data.frames
	frame_len := animation.sprite.data.duration

	animation.frame_timer -= frame_time
	for animation.frame_timer <= 0 {
		animation.current_frame += 1

		if animation.current_frame >= frames {
			animation.current_frame = animation.data.one_shot ? frames - 1 : 0
			loop = true
		}

		animation.frame_timer = frame_len + animation.frame_timer
	}

	return loop
}

change_animation :: proc(animation: ^Animation, new_animation: Animation) -> bool {
	if animation.name == new_animation.name {
		return false
	}

	animation.name = new_animation.name
	animation.sprite = new_animation.sprite
	animation.data = new_animation.data
	animation.frame_timer = new_animation.frame_timer

	animation.current_frame = 0
	return true
}

draw_animation :: proc(animation: Animation, position: rl.Vector2, flip_sprite: bool) {
	animation_data: Sprite_Data = animation.sprite.data

	animation_width: f32 = f32(animation.sprite.texture.width)
	animation_height: f32 = f32(animation.sprite.texture.height)
	size: rl.Vector2 = {animation_width / f32(animation_data.frames), animation_height}

	player_source: rl.Rectangle = {
		x      = f32(animation.current_frame) * animation_width / f32(animation_data.frames),
		y      = 0,
		width  = size.x,
		height = size.y,
	}

	player_dest: rl.Rectangle = {
		x      = position.x,
		y      = position.y,
		width  = size.x * animation.data.scale.x,
		height = size.y * animation.data.scale.y,
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
