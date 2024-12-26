#version 330 core
out vec4 FragColor;

in vec2 tex_coord;

uniform sampler2D tex_sampler;

void main() {
	FragColor = texture(tex_sampler, tex_coord);
}