#version 330 core

struct Material {
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
	float shininess;
};

struct Light {
	vec3 position;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

in vec3 normal;
in vec3 fragment_position;

out vec4 fragment_color;

uniform vec3 view_position;
uniform Material material;
uniform Light light;

void main() {
	// ambient
	vec3 ambient = light.ambient * material.ambient;

	// diffuse
	vec3 normal_dir = normalize(normal);
	vec3 light_dir = normalize(light.position - fragment_position);
	float diff = max(dot(normal_dir, light_dir), 0.0);
	vec3 diffuse = light.diffuse * (diff * material.diffuse);

	// specular
	vec3 view_dir = normalize(view_position - fragment_position);
	vec3 reflect_dir = reflect(-light_dir, normal_dir);
	float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
	vec3 specular = light.specular * (spec * material.specular);

	vec3 result = ambient + diffuse + specular;
	fragment_color = vec4(result, 1.0);
}