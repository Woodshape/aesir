#+test
package game

import "core:log"
import "core:testing"

@(test)
test_entity_create :: proc(t: ^testing.T) {
	local_ctx := new(Context)
	defer free(local_ctx)
	local_state: ^Game_State = new(Game_State)
	defer free(local_state)
	local_ctx.state = local_state

	test_player_ent := entity_create(.player, local_ctx)
	test_player := new(Player)
	defer free(test_player)
	test_player.handle = test_player_ent.handle

	ent := test_player_ent

	testing.expect_value(t, ent.handle.index, 1)
	testing.expect_value(t, ent.handle.id, 1)
	testing.expect_value(t, ent.handle, local_ctx.state.player_handle)

	testing.expect_value(t, local_ctx.state.entities[ent.handle.index], ent^)
	testing.expect_value(t, local_ctx.state.entities[ent.handle.index].kind, Entity_Kind.player)

	testing.expect_value(t, local_ctx.state.entities[0].allocated, false)
	testing.expect_value(t, local_ctx.state.entities[1].allocated, true)

	testing.expect_value(t, len(local_ctx.state.entity_free_list), 0)
	testing.expect(t, local_ctx.state.latest_entity_id >= 1)

	rebuild_scratch_helpers(local_ctx)
	ents := get_all_ents(local_ctx)
	testing.expect(t, len(ents) >= 1)

	vars := get_all_variants(local_ctx)
	testing.expect(t, len(vars) >= 1)

	entity_destroy(ent, local_ctx)
	rebuild_scratch_helpers(local_ctx)
	ents_after_des := get_all_ents(local_ctx)
	vars_after_des := get_all_variants(local_ctx)

	testing.expect_value(t, len(ents_after_des), len(ents) - 1)
	testing.expect_value(t, len(vars_after_des), len(vars) - 1)

	testing.expect_value(t, local_ctx.state.entities[ent.handle.index], ent^)

	delete(local_ctx.state.entity_free_list)
}

@(test)
test_entity_player :: proc(t: ^testing.T) {
	local_ctx := new(Context)
	defer free(local_ctx)
	local_state: ^Game_State = new(Game_State)
	defer free(local_state)
	local_ctx.state = local_state

	test_player_ent := entity_create(.player, local_ctx)
	test_player := new(Player)
	defer free(test_player)
	test_player.handle = test_player_ent.handle

	ent := test_player_ent
	ent.hp = 100

	testing.expect_value(t, local_ctx.state.entities[ent.handle.index].kind, Entity_Kind.player)

	variant := variant_from_handle(ent.handle, local_ctx)
	if p, ok := variant.(Player); ok {
		testing.expect_value(t, p, test_player^)
		testing.expect_value(t, ent.hp, 100)
	} else {
		log.fatal("player variant expected. got=", variant)
		testing.fail(t)
	}
}

@(test)
test_entity_enemy :: proc(t: ^testing.T) {
	local_ctx := new(Context)
	defer free(local_ctx)
	local_state: ^Game_State = new(Game_State)
	defer free(local_state)
	local_ctx.state = local_state

	ent := entity_create(.enemy, local_ctx)
	testing.expect_value(t, local_ctx.state.entities[ent.handle.index].kind, Entity_Kind.enemy)

	skeleton := Skeleton {
		bones = 1,
	}
	enemy := Enemy {
		handle        = ent.handle,
		enemy_variant = skeleton,
	}

	variant := variant_from_handle(ent.handle, local_ctx)
	if p, ok := variant.(Enemy); ok {
		p.enemy_variant = skeleton
		testing.expect_value(t, p, enemy)
	} else {
		log.fatal("enemy variant expected. got=", variant)
		testing.fail(t)
	}
}
