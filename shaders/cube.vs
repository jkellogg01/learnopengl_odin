#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 a_normal;
layout (location = 2) in vec2 a_tex_coord;

out vec3 normal;
out vec3 fragment_position;
out vec2 tex_coord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat3 normal_matrix;

void main() {
	gl_Position = projection * view * model * vec4(position, 1.0);
	fragment_position = vec3(model * vec4(position, 1.0));
	normal = normal_matrix * a_normal;
	tex_coord = a_tex_coord;
}