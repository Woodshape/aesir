package game

import rl "vendor:raylib"

Animation :: struct {
	texture:       rl.Texture2D,
	frames:        int,
	step_time:     f32,
	frame_timer:   f32,
	current_frame: int,
	idle_frame:    int,
	running:       bool,
	finished:      bool,
}

start_animate :: proc(animation: ^Animation, oneshot: bool = false) {
	if animation.finished {return}

	animation.running = true

	animation.frame_timer += rl.GetFrameTime()
	for animation.frame_timer > animation.step_time {
		animation.frame_timer -= animation.step_time

		animation.current_frame += 1
		if animation.current_frame >= animation.frames {
			animation.current_frame = 0
			if oneshot {
				animation.finished = true
			}
		}
	}
}

stop_animate :: proc(animation: ^Animation) {
	animation.current_frame = animation.idle_frame
	animation.running = false
	animation.finished = false
}
