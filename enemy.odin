package game

import "core:log"
import "core:testing"

Enemy :: struct {
	hp:      i32,
	variant: EnemyVariant,
}

new_enemy :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}

update_enemy :: proc(enemy: ^Enemy, frame_time: f32) {
	#partial switch e_variant in enemy.variant {
	case ^Skeleton:
		log.infof("skeleton field 'bones': %v", e_variant.bones)
		update_skeleton(e_variant, frame_time)
	case ^Bat:
		log.infof("bat field 'flying': %v", e_variant.flying)
		e_variant.flying = !e_variant.flying
	case:
		log.panicf("unhandled variant: %v\n", e_variant)
	}
}

Skeleton :: struct {
	using enemy: Enemy,
	bones:       i32,
}

update_skeleton :: proc(skeleton: ^Skeleton, frame_time: f32) {
	skeleton.bones += 10
	log.infof("skeleton update: %v", skeleton)
}

Bat :: struct {
	using enemy: Enemy,
	flying:      bool,
}

EnemyVariant :: union {
	^Skeleton,
	^Bat,
}

EnemyContainer :: struct {
	variant: EnemyVariant,
}

new_enemy_container :: proc(enemy: EnemyVariant) -> ^EnemyContainer {
	e := new(EnemyContainer)
	e.variant = enemy
	return e
}

@(test)
test_enemy_stuff :: proc(t: ^testing.T) {
	skeleton: ^Skeleton = new_enemy(Skeleton)
	defer free(skeleton)
	bat: ^Bat = new_enemy(Bat)
	defer free(bat)

	skeleton.hp = 100
	skeleton.bones = 250

	log.infof("%v\n", skeleton)
	log.infof("%v\n", bat)

	// skeleton_container: EnemyContainer = {
	// 	variant = skeleton,
	// }
	skeleton_container := new_enemy_container(skeleton)
	defer free(skeleton_container)

	log.infof("%v\n", skeleton_container)

	update_enemy(skeleton, 0.5)
	update_enemy(bat, 0.5)

	log.infof("%v\n", skeleton)
	log.infof("%v\n", bat)

	myEnemyList: [dynamic]^EnemyContainer
	append(&myEnemyList, skeleton_container)
	defer delete(myEnemyList)

	testing.expect(t, len(myEnemyList) == 1)
}
