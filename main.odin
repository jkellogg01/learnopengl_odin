package main

import "core:fmt"
import "core:c"
import "core:strings"
import "core:math/linalg"
import "core:time"

import "vendor:glfw"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

vec2 :: linalg.Vector2f32
vec3 :: linalg.Vector3f32
vec4 :: linalg.Vector4f32

mat4 :: linalg.Matrix4f32

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

	vertices := [?]f32{
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
		-0.5,  0.5, -0.5,  0.0, 1.0
	}

	VBO, VAO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)

	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	texture := load_texture("textures/container.jpg")

	// coordinate system matrices
	model_rads := linalg.to_radians(f32(-55))
	model := linalg.matrix4_rotate(model_rads, vec3{ 1.0, 0.0, 0.0 })
	view := linalg.matrix4_translate(vec3{ 0.0, 0.0, -3.0 })
	fov_rads := linalg.to_radians(f32(45))
	projection := linalg.matrix4_perspective(fov_rads, 800.0/ 600.0, 0.1, 100.0)

	t := time.now()
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		delta_time := time.duration_seconds(time.since(t))
		t = time.now()
		fmt.printf("dt: %4f gt: %4f\n", delta_time, glfw.GetTime())

		// update
		// using a delta time here instead of the direct time like the examples because I'm mutating the
		// model transformation matrix instead of applying a rotation to create a new one
		rotate_cube := linalg.matrix4_rotate(f32(delta_time), vec3{0.5, 1.0, 0.0})
		model = linalg.matrix_mul(model, rotate_cube)

		model_loc := gl.GetUniformLocation(shader_program, "model")
		gl.UniformMatrix4fv(model_loc, 1, gl.FALSE, &model[0][0])
		view_loc := gl.GetUniformLocation(shader_program, "view")
		gl.UniformMatrix4fv(view_loc, 1, gl.FALSE, &view[0][0])
		projection_loc := gl.GetUniformLocation(shader_program, "projection")
		gl.UniformMatrix4fv(projection_loc, 1, gl.FALSE, &projection[0][0])

		// draw
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.UseProgram(shader_program)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 36)

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
