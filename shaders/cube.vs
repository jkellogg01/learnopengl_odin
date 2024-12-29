#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 a_normal;

out vec3 normal;
out vec3 frag_position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
	gl_Position = projection * view * model * vec4(position, 1.0);
	frag_position = vec3(model * vec4(frag_position, 1.0));
	normal = a_normal;
}