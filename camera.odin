package main

import "core:fmt"
import "core:math/linalg"

MAX_CAMERA_FOV :: 120

Camera :: struct {
	position: Vec3,
	rotation: Vec2,
	fov: f32,
	sens: f32,
	speed: f32,
}

camera_movement :: proc(c: ^Camera, movement: Vec3) {
	c.position += movement
}

camera_handle_mouse :: proc "c" (c: ^Camera, x_offset, y_offset: f32, constrain_pitch := true) {
	offset := Vec2{x_offset, y_offset} * c.sens
	c.rotation += offset.yx

	if !constrain_pitch do return
	if c.rotation.x > 89 do c.rotation.x = 89
	if c.rotation.x < -89 do c.rotation.x = -89
}

camera_handle_scroll :: proc "c" (c: ^Camera, y_offset: f32) {
	c.fov -= y_offset
	if c.fov > MAX_CAMERA_FOV do c.fov = MAX_CAMERA_FOV
	if c.fov < 1 do c.fov = 1
}

camera_view :: proc(c: Camera) -> Mat4 {
	camera_target := c.position + camera_direction(c)
	return linalg.matrix4_look_at(c.position, camera_target, Vec3 {0.0, 1.0, 0.0})
}

camera_projection :: proc(c: Camera) -> Mat4 {
	fov_rads := linalg.to_radians(c.fov)
	return linalg.matrix4_perspective(fov_rads, 800.0/ 600.0, 0.1, 100.0)
}

camera_direction :: proc(c: Camera) -> Vec3 {
	pitch_rad := linalg.to_radians(c.rotation.x)
	yaw_rad := linalg.to_radians(c.rotation.y)

	return Vec3 {
		linalg.cos(yaw_rad) * linalg.cos(pitch_rad),
		linalg.sin(pitch_rad),
		linalg.sin(yaw_rad) * linalg.cos(pitch_rad),
	}
}