package main

import "core:fmt"
import "core:strings"
import "core:math/linalg"

import "vendor:glfw"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat3 :: matrix[3, 3]f32
Mat4 :: matrix[4, 4]f32

window_width: i32 = 800
window_height: i32 = 600

camera := Camera {
	position = {0, 0, 3},
	rotation = {0, -90},
	fov = 45,
	sens = 0.1,
	speed = 2.5,
	aspect = f32(window_width) / f32(window_height),
}

mouse_last_x := f32(window_width) / 2
mouse_last_y := f32(window_height) / 2

light_position := Vec3 {1.2, 1, 2}

main :: proc () {
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)

	if !glfw.Init() {
		fmt.println("failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	window := glfw.CreateWindow(window_width, window_height, "new glfw window", nil, nil)
	defer glfw.DestroyWindow(window)

	if window == nil {
		fmt.println("failed to open window")
		return
	}

	glfw.MakeContextCurrent(window)

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	glfw.SwapInterval(1)

	glfw.SetFramebufferSizeCallback(window, size_callback)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	gl.Enable(gl.DEPTH_TEST)

	// init
	cube_shader, cube_shader_ok := gl.load_shaders_file("shaders/cube.vs", "shaders/cube.fs")
	if !cube_shader_ok {
		fmt.println("failed to load cube shaders")
		return
	}

	light_shader, light_shader_ok := gl.load_shaders_file("shaders/light.vs", "shaders/light.fs")
	if !light_shader_ok {
		fmt.println("failed to load light source shaders")
		return
	}

	cube_vertices := [?]f32{
	    // positions       // normals        // texture coords
	    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,
	     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 0.0,
	     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
	     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
	    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 1.0,
	    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,

	    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,
	     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 0.0,
	     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
	     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
	    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 1.0,
	    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,

	    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,
	    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0, 1.0,
	    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
	    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
	    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0, 0.0,
	    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,

	     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
	     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0, 1.0,
	     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
	     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
	     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
	     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

	    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,
	     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0, 1.0,
	     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
	     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
	    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0, 0.0,
	    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,

	    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
	     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0, 1.0,
	     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
	     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
	    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
	    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
	}

	cube_positions := [?]Vec3{
	    Vec3{ 0.0, 0.0, 0.0 },
	    Vec3{ 2.0, 5.0, -15.0 },
	    Vec3{ -1.5, -2.2, -2.5 },
	    Vec3{ -3.8, -2.0, -12.3 },
	    Vec3{ 2.4, -0.4, -3.5 },
	    Vec3{ -1.7, 3.0, -7.5 },
	    Vec3{ 1.3, -2.0, -2.5 },
	    Vec3{ 1.5, 2.0, -2.5 },
	    Vec3{ 1.5, 0.2, -1.5 },
	    Vec3{ -1.3, 1.0, -1.5 },
	}

	VBO, cube_VAO, light_VAO: u32
	gl.GenVertexArrays(1, &cube_VAO)
	gl.GenVertexArrays(1, &light_VAO)
	gl.GenBuffers(1, &VBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(cube_vertices), &cube_vertices, gl.STATIC_DRAW)

	gl.BindVertexArray(cube_VAO)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(2)

	gl.BindVertexArray(light_VAO)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	diffuse_map := load_texture("textures/container2.png")

	specular_map := load_texture("textures/container2_specular.png")

	gl.UseProgram(cube_shader)

	light_model := linalg.matrix4_translate(light_position)
	light_model *= linalg.matrix4_scale(Vec3 {0.2, 0.2, 0.2})

	last_frame: f32
	for !glfw.WindowShouldClose(window) {
		current_frame := f32(glfw.GetTime())
		process_input(window, current_frame - last_frame)
		last_frame = current_frame

		view := camera_view(camera)
		projection := camera_projection(camera)

		// draw
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// IMPORTANT: a shader must be active to set its uniform values!
		gl.UseProgram(cube_shader)
		set_uniform(cube_shader, "view", &view)
		set_uniform(cube_shader, "projection", &projection)
		set_uniform(cube_shader, "view_position", camera.position)
		set_uniform_int(cube_shader, "material.diffuse", 0)
		set_uniform_int(cube_shader, "material.specular", 1)
		set_uniform_float(cube_shader, "material.shininess", 32)
		set_uniform(cube_shader, "light.position", camera.position)
		set_uniform(cube_shader, "light.direction", camera_direction(camera))
		set_uniform_float(cube_shader, "light.cutoff", linalg.cos(linalg.to_radians(f32(12.5))))
		set_uniform(cube_shader, "light.ambient", Vec3{0.2, 0.2, 0.2})
		set_uniform(cube_shader, "light.diffuse", Vec3{0.5, 0.5, 0.5})
		set_uniform(cube_shader, "light.specular", Vec3{1, 1, 1})
		set_uniform_float(cube_shader, "light.constant", 1)
		set_uniform_float(cube_shader, "light.linear", 0.09)
		set_uniform_float(cube_shader, "light.quadratic", 0.032)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, diffuse_map)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, specular_map)

		gl.BindVertexArray(cube_VAO)
		for pos, i in cube_positions {
			cube_model := linalg.matrix4_translate(pos)
			angle: f32 = 20 * f32(i)
			cube_model *= linalg.matrix4_rotate(linalg.to_radians(angle), Vec3{1, 0.3, 0.5})
			set_uniform(cube_shader, "model", &cube_model)
			cube_normal := linalg.matrix3_from_matrix4(linalg.matrix4_inverse_transpose(cube_model))
			set_uniform(cube_shader, "normal_matrix", &cube_normal)

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		// gl.UseProgram(light_shader)
		// set_uniform(light_shader, "view", &view)
		// set_uniform(light_shader, "projection", &projection)
		// set_uniform(light_shader, "model", &light_model)
		// gl.BindVertexArray(light_VAO)
		// gl.DrawArrays(gl.TRIANGLES, 0, 36)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	// exit
}

process_input :: proc(window: glfw.WindowHandle, delta_time: f32) {
	camera_speed := camera.speed * delta_time
	camera_forward := camera_direction(camera)
	camera_right := linalg.normalize(linalg.cross(camera_forward, Vec3{0, 1, 0}))
	if get_key_down(window, glfw.KEY_ESCAPE) do glfw.SetWindowShouldClose(window, true)
	if get_key_down(window, glfw.KEY_W) {
		camera_movement(&camera, camera_speed * camera_forward)
	}
	if get_key_down(window, glfw.KEY_S) {
		camera_movement(&camera, -camera_speed * camera_forward)
	}
	if get_key_down(window, glfw.KEY_A) {
		camera_movement(&camera, -camera_speed * camera_right)
	}
	if get_key_down(window, glfw.KEY_D) {
		camera_movement(&camera, camera_speed * camera_right)
	}
	if get_key_down(window, glfw.KEY_Q) {
		camera_movement(&camera, -camera_speed * Vec3{0, 1, 0})
	}
	if get_key_down(window, glfw.KEY_E) {
		camera_movement(&camera, camera_speed * Vec3{0, 1, 0})
	}
}

get_key_down :: proc(window: glfw.WindowHandle, key: i32) -> bool {
	return glfw.GetKey(window, key) == glfw.PRESS
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	camera.aspect = f32(width) / f32(height)
	gl.Viewport(0, 0, width, height)
}

load_texture :: proc (filename: string, wrap_s : i32 = gl.REPEAT, wrap_t : i32 = gl.REPEAT) -> u32 {
	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap_s)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap_t)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	cfilename := strings.clone_to_cstring(filename)
	defer delete(cfilename)

	img_width, img_height, num_chans: i32
	data := stbi.load(cfilename, &img_width, &img_height, &num_chans, 0)
	defer stbi.image_free(data)

	image_format := num_chans == 4 ? gl.RGBA : gl.RGB

	gl.TexImage2D(gl.TEXTURE_2D, 0, i32(image_format), img_width, img_height, 0, u32(image_format), gl.UNSIGNED_BYTE, data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return texture
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, mouse_x, mouse_y: f64) {
	mouse_x_offset := f32(mouse_x) - mouse_last_x
	mouse_last_x = f32(mouse_x)
	mouse_y_offset := mouse_last_y - f32(mouse_y)
	mouse_last_y = f32(mouse_y)

	camera_handle_mouse(&camera, mouse_x_offset, mouse_y_offset)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
	camera_handle_scroll(&camera, f32(y_offset))
}
