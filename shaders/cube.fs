#version 330 core
in vec3 normal;
in vec3 fragment_position;

out vec4 fragment_color;

uniform vec3 object_color;
uniform vec3 light_color;
uniform vec3 light_position;
uniform vec3 view_position;

void main() {
	float ambient_strength = 0.1;
	vec3 ambient = light_color * ambient_strength;

	vec3 normal_dir = normalize(normal);
	vec3 light_dir = normalize(light_position - fragment_position);
	float diff = max(dot(normal_dir, light_dir), 0.0);
	vec3 diffuse = light_color * diff;

	float specular_strength = 0.5;
	vec3 view_dir = normalize(view_position - fragment_position);
	vec3 reflect_dir = reflect(-light_dir, normal_dir);
	float spec = pow(max(dot(view_dir, reflect_dir), 0.0), 32);
	vec3 specular = specular_strength * spec * light_color;

	vec3 result = (ambient + diffuse + specular) * object_color;
	fragment_color = vec4(result, 1.0);
}