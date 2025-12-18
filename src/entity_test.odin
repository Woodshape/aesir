#+test
package game

import "base:runtime"
import "core:log"
import "core:testing"
import rl "vendor:raylib"

test_ctx: ^Context
test_state: ^Game_State
test_player_ent: ^Entity
test_player: ^Player

@(init)
entity_init :: proc "contextless" () {
	context = runtime.default_context()

	test_ctx = new(Context)
	test_state: ^Game_State = new(Game_State)
	test_ctx.state = test_state

	ctx = test_ctx

	assert_contextless(ctx.state.player_handle == Entity_Handle{})
	assert_contextless(ctx.state.latest_entity_id == 0)
	assert_contextless(len(ctx.state.entity_free_list) == 0)
	assert_contextless(len(ctx.state.entities) == MAX_ENTITIES)

	assert_contextless(ctx.state.entities[0].allocated == false)
	assert_contextless(ctx.state.entities[1].allocated == false)

	test_player_ent = entity_create(.player)
	test_player = get_player()
}

@(test)
test_entity_create :: proc(t: ^testing.T) {
	ent := test_player_ent

	testing.expect_value(t, ent.handle.index, 1)
	testing.expect_value(t, ent.handle.id, 1)
	testing.expect_value(t, ent.handle, ctx.state.player_handle)

	testing.expect_value(t, ctx.state.entities[ent.handle.index], ent^)

	testing.expect_value(t, ctx.state.entities[0].allocated, false)
	testing.expect_value(t, ctx.state.entities[1].allocated, true)

	testing.expect_value(t, ctx.state.latest_entity_id, 1)
	testing.expect_value(t, len(ctx.state.entity_free_list), 0)

	rebuild_scratch_helpers()
	ents := get_all_ents()
	testing.expect_value(t, len(ents), 1)
	// log.infof("ents: %v\n", ents)
}

@(test)
test_entity_player :: proc(t: ^testing.T) {
	ent := test_player_ent
	testing.expect_value(t, ent.variant, test_player)

	#partial switch variant in ent.variant {
	case ^Player:
		variant.hp = 100
		variant.pos = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
		variant.jumps = 2
		variant.animation = animations[.player_idle]

		testing.expect_value(t, variant.hp, 100)
		testing.expect_value(t, test_player.hp, 100)
		testing.expect_value(t, variant.jumps, 2)
		testing.expect_value(t, test_player.jumps, 2)
		testing.expect_value(t, variant.animation, animations[.player_idle])
		testing.expect_value(t, test_player.animation, animations[.player_idle])
	case:
		log.errorf("entity variant not of type '^Player': is=%v", ent.variant)
		testing.fail(t)
	}
}
