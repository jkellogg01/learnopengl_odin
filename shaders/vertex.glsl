#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color0;
layout (location = 2) in vec2 tex_coord0;

out vec3 color;
out vec2 tex_coord;

void main() {
	gl_Position = vec4(position.xyz, 1.0);
	color = color0;
	tex_coord = tex_coord0;
}