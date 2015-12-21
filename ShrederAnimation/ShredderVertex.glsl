#version 300 es

uniform mat4 u_mvpMatrix;
uniform float u_shredderPosition;

layout(location = 0) in vec4 a_position;
layout(location = 2) in vec2 a_texCoords;

out vec2 v_texCoords;

void main() {
    vec4 position = a_position;
    position.y = position.y + u_shredderPosition;
    gl_Position = u_mvpMatrix * position;
    v_texCoords = a_texCoords;
}