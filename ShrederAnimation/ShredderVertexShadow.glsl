#version 300 es

uniform mat4 u_mvpMatrix;
uniform float u_shredderPosition;

layout(location = 0) in vec4 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec2 a_texCoord;
layout(location = 3) in vec3 a_cylinderCenter;

out vec2 v_texCoord;
out vec3 v_normal;

#define M_PI 3.14159265358979323846264338327950288

void main() {
    vec4 position = a_position;
    if (position.y <= u_shredderPosition) {
        float angle = (a_cylinderCenter.y - a_position.y) / a_cylinderCenter.z;
        position.y = a_cylinderCenter.y - a_cylinderCenter.z * sin(angle);
        position.z = a_cylinderCenter.z * (1.0 - cos(angle)) - 20.0;
    }
    gl_Position = u_mvpMatrix * position;
    v_texCoord = a_texCoord;
    v_normal = a_cylinderCenter - position.xyz;
}