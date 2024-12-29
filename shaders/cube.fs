#version 330 core
out vec4 fragment_color;

uniform vec3 object_color;
uniform vec3 light_color;

void main() {
	float ambient_strength = 0.1;
	vec3 ambient = light_color * ambient_strength;

	vec3 result = ambient * object_color;
	fragment_color = vec4(result, 1.0);
}