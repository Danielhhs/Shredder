#version 300 es

precision highp float;

uniform sampler2D s_tex;

in vec2 v_texCoord;
in vec3 v_normal;
in vec2 v_position;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 color = texture(s_tex, v_texCoord);
    vec3 normal = normalize(v_normal);
    out_color = vec4(color.rgb,  color.a * normal.z);
}