#version 300 es

uniform mat4 u_mvpMatrix;

layout(location = 0) in vec4 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec2 a_texCoord;

out vec2 v_texCoord;
out vec3 v_normal;
out vec2 v_position;

#define M_PI 3.14159265358979323846264338327950288

void main() {
    gl_Position = u_mvpMatrix * a_position;
    v_texCoord = a_texCoord;
    v_normal = a_normal;
    v_position = a_position.xy;
}