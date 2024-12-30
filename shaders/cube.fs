#version 330 core

struct Material {
	sampler2D diffuse;
	sampler2D specular;
	float shininess;
};

struct Light {
	vec3 position;
	vec3 direction;
	float cutoff;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;

	float constant;
	float linear;
	float quadratic;
};

in vec3 normal;
in vec3 fragment_position;
in vec2 tex_coord;

out vec4 fragment_color;

uniform vec3 view_position;
uniform Material material;
uniform Light light;

void main() {
	// ambient
	vec3 ambient = light.ambient * texture(material.diffuse, tex_coord).rgb;

	// diffuse
	vec3 normal_dir = normalize(normal);
	vec3 light_dir = normalize(light.position - fragment_position);
	float diff = max(dot(normal_dir, light_dir), 0.0);
	vec3 diffuse = light.diffuse * diff * texture(material.diffuse, tex_coord).rgb;

	// specular
	vec3 view_dir = normalize(view_position - fragment_position);
	vec3 reflect_dir = reflect(-light_dir, normal_dir);
	float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
	vec3 specular = light.specular * spec * texture(material.specular, tex_coord).rgb;

	float distance = length(light.position - fragment_position);
	float attenuation = 1.0 / (light.constant + distance * light.linear + (distance * distance) * light.quadratic);

	ambient *= attenuation;
	diffuse *= attenuation;
	specular *= attenuation;

	float theta = dot(light_dir, normalize(-light.direction));
	if (theta > light.cutoff) {
		fragment_color = vec4(ambient + diffuse + specular, 1.0);
	} else {
		fragment_color = vec4(ambient, 1.0);
	}
}