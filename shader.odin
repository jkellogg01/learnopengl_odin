package main

import gl "vendor:OpenGL"

get_uniform_location :: proc(program: u32, name: string) -> i32 {
	return gl.GetUniformLocation(program, cstring(raw_data(name)))
}

set_uniform_float :: proc(program: u32, name: string, value: f32) {
	loc := get_uniform_location(program, name)
	gl.Uniform1f(loc, value)
}

set_uniform_mat4 :: proc(program: u32, name: string, value: ^Mat4) {
	loc := get_uniform_location(program, name)
	gl.UniformMatrix4fv(loc, 1, gl.FALSE, &value[0][0])
}

set_uniform_mat3 :: proc(program: u32, name: string, value: ^Mat3) {
	loc := get_uniform_location(program, name)
	gl.UniformMatrix3fv(loc, 1, gl.FALSE, &value[0][0])
}

set_uniform_vec3 :: proc(program: u32, name: string, value: Vec3) {
	loc := get_uniform_location(program, name)
	gl.Uniform3f(loc, value.x, value.y, value.z)
}

set_uniform :: proc{
	set_uniform_float,
	set_uniform_mat3,
	set_uniform_mat4,
	set_uniform_vec3,
}