#version 300 es

precision mediump float;

uniform sampler2D s_tex;

in vec2 v_texCoord;

layout(location = 0) out vec4 out_color;

void main() {
    out_color = texture(s_tex, v_texCoord);
}