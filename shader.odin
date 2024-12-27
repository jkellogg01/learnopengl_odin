package main

import gl "vendor:OpenGL"

set_uniform :: proc{
	set_uniform_mat4
}

get_uniform_location :: proc(program: u32, name: string) -> i32 {
	return gl.GetUniformLocation(program, cstring(raw_data(name)))
}

set_uniform_mat4 :: proc(program: u32, name: string, value: ^mat4) {
	loc := get_uniform_location(program, name)
	gl.UniformMatrix4fv(loc, 1, gl.FALSE, &value[0][0])
}