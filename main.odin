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

Mat4 :: matrix[4, 4]f32

camera := Camera {
	position = {0, 0, 3},
	rotation = {0, -90},
	fov = 45,
	sens = 0.1,
	speed = 2.5,
}

mouse_last_x: f32 = 400
mouse_last_y: f32 = 300

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

	window := glfw.CreateWindow(800, 600, "new glfw window", nil, nil)
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
	shader_program, ok := gl.load_shaders_file("shaders/vertex.glsl", "shaders/fragment.glsl")
	if !ok {
		fmt.println("failed to load shaders")
		return
	}
	gl.UseProgram(shader_program)

	cube_vertices := [?]f32{
		-0.5, -0.5, -0.5,  0.0, 0.0,
		0.5, -0.5, -0.5,  1.0, 0.0,
		0.5,  0.5, -0.5,  1.0, 1.0,
		0.5,  0.5, -0.5,  1.0, 1.0,
		-0.5,  0.5, -0.5,  0.0, 1.0,
		-0.5, -0.5, -0.5,  0.0, 0.0,

		-0.5, -0.5,  0.5,  0.0, 0.0,
		0.5, -0.5,  0.5,  1.0, 0.0,
		0.5,  0.5,  0.5,  1.0, 1.0,
		0.5,  0.5,  0.5,  1.0, 1.0,
		-0.5,  0.5,  0.5,  0.0, 1.0,
		-0.5, -0.5,  0.5,  0.0, 0.0,

		-0.5,  0.5,  0.5,  1.0, 0.0,
		-0.5,  0.5, -0.5,  1.0, 1.0,
		-0.5, -0.5, -0.5,  0.0, 1.0,
		-0.5, -0.5, -0.5,  0.0, 1.0,
		-0.5, -0.5,  0.5,  0.0, 0.0,
		-0.5,  0.5,  0.5,  1.0, 0.0,

		0.5,  0.5,  0.5,  1.0, 0.0,
		0.5,  0.5, -0.5,  1.0, 1.0,
		0.5, -0.5, -0.5,  0.0, 1.0,
		0.5, -0.5, -0.5,  0.0, 1.0,
		0.5, -0.5,  0.5,  0.0, 0.0,
		0.5,  0.5,  0.5,  1.0, 0.0,

		-0.5, -0.5, -0.5,  0.0, 1.0,
		0.5, -0.5, -0.5,  1.0, 1.0,
		0.5, -0.5,  0.5,  1.0, 0.0,
		0.5, -0.5,  0.5,  1.0, 0.0,
		-0.5, -0.5,  0.5,  0.0, 0.0,
		-0.5, -0.5, -0.5,  0.0, 1.0,

		-0.5,  0.5, -0.5,  0.0, 1.0,
		0.5,  0.5, -0.5,  1.0, 1.0,
		0.5,  0.5,  0.5,  1.0, 0.0,
		0.5,  0.5,  0.5,  1.0, 0.0,
		-0.5,  0.5,  0.5,  0.0, 0.0,
		-0.5,  0.5, -0.5,  0.0, 1.0,
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

	VBO, VAO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)

	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(cube_vertices), &cube_vertices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	texture := load_texture("textures/container.jpg")

	last_frame: f32
	for !glfw.WindowShouldClose(window) {
		current_frame := f32(glfw.GetTime())
		process_input(window, current_frame - last_frame)
		last_frame = current_frame


		view := camera_view(camera)
		projection := camera_projection(camera)
		set_uniform(shader_program, "view", &view)
		set_uniform(shader_program, "projection", &projection)

		// draw
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.UseProgram(shader_program)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.BindVertexArray(VAO)

		for pos, idx in cube_positions {
			model := linalg.matrix4_translate(pos)
			angle := 20.0 * f32(idx)
			model *= linalg.matrix4_rotate(linalg.to_radians(angle), Vec3{1.0, 0.3, 0.5})
			set_uniform(shader_program, "model", &model)

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

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
}

get_key_down :: proc(window: glfw.WindowHandle, key: i32) -> bool {
	return glfw.GetKey(window, key) == glfw.PRESS
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
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
