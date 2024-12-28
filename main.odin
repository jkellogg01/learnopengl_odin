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

UP :: Vec3 { 0.0, 1.0, 0.0 }

main :: proc () {
	glfw.WindowHint(glfw.RESIZABLE, glfw.TRUE)
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

	glfw.SwapInterval(1)

	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)

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

	// coordinate system matrices
	fov_rads := linalg.to_radians(f32(45))
	projection := linalg.matrix4_perspective(fov_rads, 800.0/ 600.0, 0.1, 100.0)

	radius: f32 : 10

	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		// update
		time := f32(glfw.GetTime())
		camera_x := linalg.sin(time) * radius
		camera_z := linalg.cos(time) * radius
		camera_position := Vec3 { camera_x, 0.0, camera_z }
		camera_target := Vec3 { 0.0, 0.0, 0.0 }
		camera_direction := linalg.normalize(camera_position - camera_target)

		// cross product of two vectors produces a vector which is orthogonal to both components
		// NOTE: order is important! vector cross product is not commutative. doing these in the wrong
		// order will result in inverted camera axes
		camera_right := linalg.normalize(linalg.cross(UP, camera_direction))
		camera_up := linalg.cross(camera_direction, camera_right)
		view := linalg.matrix4_look_at(camera_position, camera_target, camera_up)

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
	}

	// exit
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE do glfw.SetWindowShouldClose(window, true)
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
