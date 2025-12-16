package game

import rl "vendor:raylib"

zero_entity: Entity // #readonlytodo

Entity_Kind :: enum {
	nil,
	player,
	enemy,
}


Entity_Handle :: struct {
	index: int,
	id:    int,
}

Entity :: struct {
	handle:      Entity_Handle,
	kind:        Entity_Kind,

	// todo, move this into static entity data
	update_proc: proc(_: ^Entity),
	draw_proc:   proc(_: Entity),

	// big sloppy entity state dump.
	// add whatever you need in here.
	pos:         rl.Vector2,
	flip_x:      bool,

	// this gets zeroed every frame. Useful for passing data to other systems.
	scratch:     struct{},
}

entity_from_handle :: proc(handle: Entity_Handle) -> (entity: ^Entity, ok: bool) #optional_ok {
	if handle.index <= 0 || handle.index > ctx.state.entity_top_count {
		return &zero_entity, false
	}

	ent := &ctx.state.entities[handle.index]
	if ent.handle.id != handle.id {
		return &zero_entity, false
	}

	return ent, true
}
