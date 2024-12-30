#version 330 core

struct Material {
	sampler2D diffuse;
	sampler2D specular;
	float shininess;
};

// struct Light {
// 	vec3 position;
// 	vec3 direction;
// 	float inner_cutoff;
// 	float outer_cutoff;

// 	vec3 ambient;
// 	vec3 diffuse;
// 	vec3 specular;

// 	float constant;
// 	float linear;
// 	float quadratic;
// };

struct Dir_Light {
	vec3 direction;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

struct Point_Light {
	vec3 position;

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

#define NUM_POINT_LIGHTS 4

uniform vec3 view_position;
uniform Material material;
uniform Dir_Light dir_light;
uniform Point_Light point_lights[NUM_POINT_LIGHTS];

vec3 calc_dir_light(Dir_Light light, vec3 normal, vec3 view_direction);
vec3 calc_point_light(Point_Light light, vec3 normal, vec3 fragment_position, vec3 view_direction);

void main() {
	vec3 fragment_normal = normalize(normal);
	vec3 view_direction = normalize(view_position - fragment_position);

	vec3 result = calc_dir_light(dir_light, fragment_normal, view_direction);
	for (int i = 0; i < NUM_POINT_LIGHTS; i++) {
		result += calc_point_light(point_lights[i], fragment_normal, fragment_position, view_direction);
	}
	// [insert spot light code here]

	fragment_color = vec4(result, 1.0);
}

vec3 calc_dir_light(Dir_Light light, vec3 normal, vec3 view_direction) {
	vec3 light_direction = normalize(-light.direction);

	float diff = max(dot(normal, light_direction), 0.0);

	vec3 reflect_direction = reflect(-light_direction, normal);
	float spec = pow(max(dot(view_direction, reflect_direction), 0.0), material.shininess);

	vec3 diffuse_sample = texture(material.diffuse, tex_coord).rgb;
	vec3 specular_sample = texture(material.specular, tex_coord).rgb;

	vec3 ambient = light.ambient * diffuse_sample;
	vec3 diffuse = light.diffuse * diffuse_sample * diff;
	vec3 specular = light.specular * specular_sample * spec;
	return ambient + diffuse + specular;
}

vec3 calc_point_light(Point_Light light, vec3 normal, vec3 fragment_position, vec3 view_direction) {
	vec3 light_direction = normalize(light.position - fragment_position);

	float diff = max(dot(normal, light_direction), 0.0);

	vec3 reflect_direction = reflect(-light_direction, normal);
	float spec = pow(max(dot(view_direction, reflect_direction), 0.0), material.shininess);

	vec3 diffuse_sample = texture(material.diffuse, tex_coord).rgb;
	vec3 specular_sample = texture(material.specular, tex_coord).rgb;

	vec3 ambient = light.ambient * diffuse_sample;
	vec3 diffuse = light.diffuse * diffuse_sample * diff;
	vec3 specular = light.specular * specular_sample * spec;

	float distance = length(light.position - fragment_position);
	float attenuation = 1.0 / (light.constant + distance * light.linear + distance * distance * light.quadratic);

	ambient *= attenuation;
	diffuse *= attenuation;
	specular *= attenuation;

	return ambient + diffuse + specular;
}